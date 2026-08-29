import assert from 'node:assert/strict';
import test from 'node:test';
import {
	Metric,
	MetricConditionOperator,
	PolicyEffectFormula,
	type InterestGroupDefinition,
	type PolicyDefinition,
	type Proposal
} from '../../game/index.ts';
import {
	createProposalSynthesisPreview,
	createSynthesisConfirmation,
	deriveSynthesisItems,
	filterArchiveItems,
	filterSelectionItems,
	getLeftSecondaryMode,
	getProposalGroupOptions,
	moveSelectedProposalsFirst,
	restoreProposalToHand,
	sortProposalItemsByTime,
	sortProposalItemsByValue,
	toggleProposalSelection
} from './left.ts';
import { proposalToHorizontalContents } from '../memorial/presentation.ts';
import type { LeftItem, ProposalLeftItem } from './types.ts';
import { mockLeftItems, mockProposalItems } from '../../demo/mock.ts';

const group = (display_name: string): InterestGroupDefinition => ({
	display_name,
	description: `${display_name}简介`,
	base_column_weight: 1,
	decrease_tax: false,
	decrease_price: false,
	decrease_wage: false,
	decrease_employment: false,
	decrease_trade: false
});

const proposal = (
	name: string,
	tax: number,
	trade = 0,
	positiveTax = 0,
	positiveTrade = 0
): Proposal => ({
	source_group: group(name),
	base_effect: { tax, price: 0, wage: 0, employment: 0, trade },
	positive_effect: {
		tax: positiveTax,
		price: 0,
		wage: 0,
		employment: 0,
		trade: positiveTrade
	},
	lag_months: 2,
	donation_offer: 0,
	bonus_choice_resolved: true,
	positive_trait_accepted: true
});

const proposalItem = (index: number, value: Proposal): ProposalLeftItem => ({
	kind: 'proposal',
	ref: { collection: 'proposals', index },
	proposal: value
});

const policy: PolicyDefinition = {
	display_name: '工贸调节',
	condition: {
		left_metric: Metric.WAGE,
		operator: MetricConditionOperator.LESS_THAN,
		right_metric: Metric.TRADE,
		right_multiplier: 1
	},
	effects: [
		{
			target_metric: Metric.EMPLOYMENT,
			formula: PolicyEffectFormula.METRIC_VALUE,
			source_a: Metric.TRADE,
			source_b: Metric.TRADE,
			multiplier: 0.1
		}
	]
};

const secondArticlePolicy: PolicyDefinition = {
	display_name: '物价政策',
	condition: {
		left_metric: Metric.PRICE,
		operator: MetricConditionOperator.GREATER_THAN,
		right_metric: Metric.TAX,
		right_multiplier: 1
	},
	effects: []
};

const proposals = [
	proposalItem(4, proposal('商会', -4, 1)),
	proposalItem(9, proposal('工所', -9, 3)),
	proposalItem(2, proposal('商会', -2, 2))
];

const items: LeftItem[] = [
	{
		kind: 'constitution',
		ref: { collection: 'constitution', index: 0 },
		constitution: {
			title: '约法',
			active_articles: [
				{ display_name: '节点一', content: '', policies: [policy] },
				{ display_name: '节点二', content: '', policies: [secondArticlePolicy] }
			]
		}
	},
	{
		kind: 'bill',
		ref: { collection: 'bills', index: 0 },
		bill: { title: '法案', proposals: [proposals[0].proposal], policies: [] }
	},
	...proposals,
	{ kind: 'policy', ref: { collection: 'policies', index: 0 }, policy }
];

test('proposal details show the source interest group description', () => {
	assert.deepEqual(proposalToHorizontalContents(proposals[0].proposal)[0], {
		title: '商会',
		body: '商会简介'
	});
});

test('Left filters by discriminated kind without mutating input', () => {
	const filtered = filterArchiveItems(items, {
		kinds: ['bill', 'policy'],
		metrics: [Metric.TAX, Metric.WAGE],
		timeAscending: false,
		valueAscending: false
	});
	assert.deepEqual(
		filtered.map((item) => item.kind),
		['bill', 'policy']
	);
	assert.equal(items.length, 6);
});

test('Left metric filter matches any involved metric', () => {
	const filtered = filterArchiveItems(items, {
		kinds: ['constitution', 'proposal'],
		metrics: [Metric.PRICE],
		timeAscending: false,
		valueAscending: false
	});
	assert.deepEqual(
		filtered.map((item) => item.kind),
		['constitution']
	);
});

test('synthesis group options are dynamic, deduplicated, and value based', () => {
	const separateObject = proposalItem(10, proposal('商会', -1));
	assert.deepEqual(getProposalGroupOptions([...proposals, separateObject]), ['商会', '工所']);
	assert.deepEqual(
		deriveSynthesisItems([...proposals, separateObject], {
			group: '商会',
			metrics: [Metric.TAX],
			timeAscending: true,
			valueAscending: true
		}).map((item) => item.proposal.source_group.display_name),
		['商会', '商会', '商会']
	);
});

test('proposal time sort uses original collection index', () => {
	assert.deepEqual(
		sortProposalItemsByTime(proposals, true).map((item) => item.ref.index),
		[2, 4, 9]
	);
	assert.deepEqual(
		sortProposalItemsByTime(proposals, false).map((item) => item.ref.index),
		[9, 4, 2]
	);
});

test('proposal value sort uses selected effective metric', () => {
	assert.deepEqual(
		sortProposalItemsByValue(proposals, [Metric.TAX], true).map((item) => item.ref.index),
		[9, 4, 2]
	);
});

test('proposal selection is capped at three and selected refs move first unchanged', () => {
	const fourth = proposalItem(12, proposal('商会', -12));
	const selected = [...proposals, fourth].reduce(
		(current, item) => toggleProposalSelection(current, item),
		[] as ProposalLeftItem[]
	);
	assert.deepEqual(
		selected.map((item) => item.ref.index),
		[4, 9, 2]
	);
	const moved = moveSelectedProposalsFirst([fourth, ...proposals], [proposals[2], proposals[0]]);
	assert.deepEqual(
		moved.map((item) => item.ref.index),
		[2, 4, 12, 9]
	);
	assert.equal(moved[0].ref, proposals[2].ref);
});

test('three proposal preview shows min~max ranges', () => {
	const preview = createProposalSynthesisPreview(proposals);
	assert.equal(preview.metrics.find((metric) => metric.text === '税課')?.value, '-9~-2');
	assert.equal(preview.metrics.find((metric) => metric.text === '商貿')?.value, '1~3');
});

test('preview keeps only the largest reverse metric with stable ties', () => {
	const first = proposalItem(0, proposal('商会', -1, 0, -8));
	const second = proposalItem(1, proposal('工所', -1, 0, 0, 8));
	const third = proposalItem(2, proposal('农会', -1, 0, 0, 5));
	const preview = createProposalSynthesisPreview([first, second, third]);
	const reverse = preview.metrics.filter((metric) => metric.isReverse);
	assert.equal(reverse.length, 1);
	assert.equal(reverse[0].text, '税課');
	assert.equal(reverse[0].value, 8);
	assert.equal(preview.reverseSource, first);
});

test('synthesis confirmation records the clicked negative base ref', () => {
	const confirmation = createSynthesisConfirmation(proposals, proposals[1]);
	assert.equal(confirmation.negativeBaseRef, proposals[1].ref);
	assert.deepEqual(
		confirmation.refs,
		proposals.map((item) => item.ref)
	);
});

test('Left secondary mode follows its scene', () => {
	assert.equal(getLeftSecondaryMode('office'), 'synthesis');
	assert.equal(getLeftSecondaryMode('parliament'), 'selection');
	assert.equal(getLeftSecondaryMode('dialogue'), undefined);
});

test('selection hides selected ingredients and the editing saved bill', () => {
	const selection = filterSelectionItems(items, {
		proposalRefs: [proposals[0].ref],
		policyDisplayNames: [policy.display_name],
		editingSavedBillIndex: 0
	});
	assert.equal(
		selection.some((item) => item.kind === 'constitution'),
		false
	);
	assert.equal(
		selection.some((item) => item.kind === 'proposal' && item.ref.index === proposals[0].ref.index),
		false
	);
	assert.equal(
		selection.some((item) => item.kind === 'policy'),
		false
	);
	assert.equal(
		selection.some((item) => item.kind === 'bill' && item.ref.index === 0),
		false
	);
});

test('restoring a draft Proposal keeps acquisition ref order', () => {
	const restored = restoreProposalToHand([proposals[1], proposals[0]], proposals[2]);
	assert.deepEqual(
		restored.map((item) => item.ref.index),
		[2, 4, 9]
	);
});

test('the Left mock contains one Constitution with active articles', () => {
	const constitutions = mockLeftItems.filter((item) => item.kind === 'constitution');
	assert.equal(constitutions.length, 1);
	assert.equal(constitutions[0].constitution.title, '蓬莱约法');
	assert.equal(constitutions[0].constitution.active_articles.length > 1, true);
});

test('Proposal mocks preserve each InterestGroup fixed base effect template', () => {
	const expected: Record<string, Partial<Record<keyof Proposal['base_effect'], number>>> = {
		造身公所: { price: 1, employment: -1 },
		槐安公所: { wage: -1, price: 1 },
		永乐轮运局: { price: 1, trade: -1 },
		官药局: { tax: 1, price: 1 },
		铅字报馆: { tax: 1, wage: -1 },
		会同成衣会: { price: 1, wage: -1 }
	};
	for (const item of mockProposalItems) {
		const template = expected[item.proposal.source_group.display_name];
		const nonzero = Object.entries(item.proposal.base_effect).filter(([, value]) => value !== 0);
		assert.deepEqual(
			Object.fromEntries(nonzero.map(([metric, value]) => [metric, Math.sign(value)])),
			template
		);
	}
});
