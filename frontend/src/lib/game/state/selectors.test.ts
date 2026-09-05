import assert from 'node:assert/strict';
import test from 'node:test';
import { reconcileSavedBill } from '../rules.ts';
import { Metric } from '../types.ts';
import {
	deriveConstitutionMemorial,
	deriveDialoguePresentation,
	deriveDraftPreviewMetrics,
	deriveGameStateDisplayProps,
	deriveLeftItems,
	deriveTopItems
} from './selectors.ts';
import { makeLiveState, testPolicy, testProposal } from './test-fixtures.ts';

test('live state derives Left refs from authoritative array indices', () => {
	const state = makeLiveState();
	state.proposal_hand[0].bonus_choice_resolved = true;
	state.proposal_hand[0].positive_trait_accepted = true;
	const items = deriveLeftItems(state);
	assert.deepEqual(
		items.map((item) => [item.kind, item.ref.collection, item.ref.index]),
		[
			['constitution', 'constitution', 0],
			['bill', 'bills', 0],
			['proposal', 'proposals', 0],
			['policy', 'policies', 0]
		]
	);
	assert.equal(items[0].kind === 'constitution' && items[0].constitution.title, '蓬莱约法');
});

test('Left hides unresolved visit proposals until the positive trait is accepted', () => {
	const state = makeLiveState();
	const pending = state.proposal_hand[0];
	pending.bonus_choice_resolved = false;
	pending.positive_trait_accepted = false;
	assert.equal(
		deriveLeftItems(state).some((item) => item.kind === 'proposal'),
		false
	);
	pending.bonus_choice_resolved = true;
	pending.positive_trait_accepted = true;
	const accepted = deriveLeftItems(state).filter((item) => item.kind === 'proposal');
	assert.equal(accepted.length, 1);
	assert.equal(accepted[0].ref.index, 0);
});

test('live race/group summaries derive Top without mock lore', () => {
	const top = deriveTopItems(makeLiveState());
	assert.equal(top.raceItems[0].item.text, '人类');
	assert.equal(top.raceItems[0].item.value, 1);
	assert.equal(top.raceItems[0].detail.leftLabel, '年度期望');
	assert.match(top.raceItems[0].detail.leftBody, /投資↑110/);
	assert.equal(top.raceItems[0].detail.rightLabel, '种族简介');
	assert.equal(top.raceItems[0].detail.rightBody, '人类简介');
	assert.equal(top.interestGroupItems[0].item.text, '造身公所');
	assert.equal(top.interestGroupItems[0].item.value, 1);
	assert.equal(top.interestGroupItems[0].detail.leftLabel, '固定指标立场');
	assert.match(top.interestGroupItems[0].detail.leftBody, /消費↓/);
	assert.equal(top.interestGroupItems[0].detail.rightLabel, '利益集团简介');
	assert.equal(top.interestGroupItems[0].detail.rightBody, '造身公所简介');
});

test('live status derives political donation and collapse values', () => {
	assert.deepEqual(deriveGameStateDisplayProps(makeLiveState()), {
		primary: { text: '政治献金', value: 8, isRow: false },
		secondary: { text: '崩溃度', value: 4, limit: 24, isRow: false }
	});
});

test('draft preview displays every projected metric including unchanged values', () => {
	const state = makeLiveState();
	state.draft_preview.projected_metrics.tax = 107;
	state.draft_preview.projected_metrics.investment = -5;
	const preview = deriveDraftPreviewMetrics(state.draft_preview);
	assert.deepEqual(
		preview.map(({ text, symbol, value }) => [text, symbol, value]),
		[
			['税課', undefined, 107],
			['消費', undefined, 92],
			['生産', undefined, 100],
			['就業', undefined, 100],
			['投資', undefined, -5]
		]
	);
});

test('constitution presentation keeps one aligned row grid and turns locked columns into year pages', () => {
	const state = makeLiveState();
	state.constitution.columns.push({
		column_index: 1,
		display_name: '新制',
		unlock_cost_months: 12,
		unlocked: false,
		can_unlock: true
	});
	state.constitution.rows.push({
		row_index: 1,
		display_name: '文化',
		race_display_name: '比翼',
		free_navigation: false,
		ignores_column_unlocks: false,
		active_article_index: -1
	});
	const constitution = deriveConstitutionMemorial(state);
	const rowLabels = Array.isArray(constitution['']) ? constitution[''] : [];
	const normalRows = Array.isArray(constitution['常制']) ? constitution['常制'] : [];
	assert.equal(rowLabels.length, 2);
	assert.equal(rowLabels[0]?.text, '外交');
	assert.equal(rowLabels[0]?.number, 50);
	assert.equal(rowLabels[0]?.selectable, false);
	assert.equal(rowLabels[1]?.text, '文化');
	assert.equal(rowLabels[1]?.number, '');
	assert.equal(normalRows.length, 2);
	assert.equal(normalRows[0]?.articleRef, 0);
	assert.equal(normalRows[0]?.number, 50);
	assert.equal(normalRows[0]?.selected, true);
	assert.equal(normalRows[0]?.selectable, false);
	assert.equal(normalRows[1]?.articleRef, undefined);
	assert.equal(constitution['新制'], 1);
});

test('constitution details preserve the authoritative description, requirements and effect sections', () => {
	const state = makeLiveState();
	state.constitution.articles[0].contents.push({ title: '事件情报', body: '人类事件情报概率增加25%' });
	const constitution = deriveConstitutionMemorial(state);
	const rows = Array.isArray(constitution['常制']) ? constitution['常制'] : [];
	assert.deepEqual(rows[0]?.contents, [
		{ title: '', body: '外藩约法描述' },
		{ title: '要求', body: '种族：人类\n席位占比：不低于50%' },
		{ title: '事件情报', body: '人类事件情报概率增加25%' }
	]);
});

test('interest-group dialogue presentation uses authoritative visit values', () => {
	const state = makeLiveState();
	const dialogue = deriveDialoguePresentation(state.pending_dialogue);
	assert.deepEqual(dialogue, {
		kind: 'interest_group',
		raceName: '人类',
		groupName: '造身公所',
		positiveEffect: '投資+8',
		donationOffer: '政治献金+5'
	});
});

test('event-intel dialogue presentation maps metric names and keeps event values', () => {
	const dialogue = deriveDialoguePresentation({
		kind: 'event_intel',
		race_name: '南柯',
		metric: Metric.PRODUCTION,
		requirement: 112,
		strength: 73
	});
	assert.deepEqual(dialogue, {
		kind: 'event_intel',
		raceName: '南柯',
		metricName: '生産',
		requirement: 112,
		strength: 73
	});
});

test('simple dialogue presentation preserves Godot-provided strings', () => {
	const dialogue = deriveDialoguePresentation({
		kind: 'simple',
		initial_text: '先听我说。',
		left_option: '留下',
		right_option: '离开',
		left_content: '那就留下。',
		right_content: '那便告辞。'
	});
	assert.deepEqual(dialogue, {
		kind: 'simple',
		initialText: '先听我说。',
		leftOption: '留下',
		rightOption: '离开',
		leftContent: '那就留下。',
		rightContent: '那便告辞。'
	});
});

test('simple dialogue presentation allows choices to be omitted', () => {
	const dialogue = deriveDialoguePresentation({ kind: 'simple', initial_text: '只说这一句。' });
	assert.equal(dialogue?.kind, 'simple');
	if (dialogue?.kind !== 'simple') return;
	assert.equal(dialogue.initialText, '只说这一句。');
	assert.equal(dialogue.leftOption, undefined);
	assert.equal(dialogue.rightOption, undefined);
	assert.equal(dialogue.leftContent, undefined);
	assert.equal(dialogue.rightContent, undefined);
});

test('Saved Bill optimistic reconciliation still uses gameplay equivalence', () => {
	const handProposal = {
		...testProposal,
		source_group: { ...testProposal.source_group },
		base_effect: { ...testProposal.base_effect },
		positive_effect: { ...testProposal.positive_effect }
	};
	const reconciled = reconcileSavedBill(
		{ title: '旧法案', proposals: [testProposal], policies: [{ ...testPolicy }] },
		[handProposal],
		[testPolicy]
	);
	assert.equal(reconciled.proposals[0], handProposal);
	assert.equal(reconciled.policies[0], testPolicy);
});