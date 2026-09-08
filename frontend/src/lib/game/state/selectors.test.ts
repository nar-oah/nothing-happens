import assert from 'node:assert/strict';
import test from 'node:test';
import { Metric } from '../types.ts';
import {
	deriveConstitutionMemorial,
	deriveDialoguePresentation,
	deriveLeftItems
} from './selectors.ts';
import { makeLiveState } from './test-fixtures.ts';

test('live state derives stable Left refs and hides unresolved visit proposals', () => {
	const state = makeLiveState();
	state.proposal_hand[0].bonus_choice_resolved = false;
	state.proposal_hand[0].positive_trait_accepted = false;
	assert.equal(
		deriveLeftItems(state).some((item) => item.kind === 'proposal'),
		false
	);

	state.proposal_hand[0].bonus_choice_resolved = true;
	state.proposal_hand[0].positive_trait_accepted = true;
	assert.deepEqual(
		deriveLeftItems(state).map((item) => [item.kind, item.ref.collection, item.ref.index]),
		[
			['constitution', 'constitution', 0],
			['bill', 'bills', 0],
			['proposal', 'proposals', 0],
			['policy', 'policies', 0]
		]
	);
});

test('dialogue presentation keeps authoritative event-intel values', () => {
	assert.deepEqual(
		deriveDialoguePresentation({
			kind: 'event_intel',
			race_name: '南柯',
			metric: Metric.PRODUCTION,
			requirement: 112,
			strength: 73
		}),
		{
			kind: 'event_intel',
			raceName: '南柯',
			metricName: '生産',
			requirement: 112,
			strength: 73
		}
	);
});

test('constitution presentation keeps the active article in its authoritative column', () => {
	const constitution = deriveConstitutionMemorial(makeLiveState());
	const rows = Array.isArray(constitution['常制']) ? constitution['常制'] : [];
	assert.equal(rows[0]?.articleRef, 0);
	assert.equal(rows[0]?.selected, true);
	assert.equal(rows[0]?.selectable, false);
});
