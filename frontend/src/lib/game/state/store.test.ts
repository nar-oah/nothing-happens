import assert from 'node:assert/strict';
import test from 'node:test';
import { applyGameMessage, EMPTY_GAME_STORE } from './store.ts';
import { makeDraftSync, makeLiveState, makeParliamentLayout } from './test-fixtures.ts';

test('state.full replaces the complete snapshot', () => {
	const first = makeLiveState(5);
	const replacement = {
		...makeLiveState(2),
		year: 9,
		governing_months: 25,
		run_phase: 'TERM_ENDED' as const,
		term_outcome: 'COLLAPSE' as const,
		proposal_hand: []
	};
	const loaded = applyGameMessage(EMPTY_GAME_STORE, { type: 'state.full', payload: first });
	const replaced = applyGameMessage(loaded, { type: 'state.full', payload: replacement });
	assert.equal(replaced.snapshot, replacement);
	assert.equal(replaced.snapshot?.year, 9);
	assert.equal(replaced.snapshot?.governing_months, 25);
	assert.equal(replaced.snapshot?.run_phase, 'TERM_ENDED');
	assert.equal(replaced.snapshot?.term_outcome, 'COLLAPSE');
	assert.deepEqual(replaced.snapshot?.proposal_hand, []);
});

test('domain sync immutably overwrites only its authoritative fields', () => {
	const original = makeLiveState(1);
	const value = { snapshot: original, error: null };
	const draftSync = makeDraftSync(2);
	draftSync.draft_preview.vote.seat_votes[0].score = 9;
	const updated = applyGameMessage(value, { type: 'draft.sync', payload: draftSync });
	assert.notEqual(updated.snapshot, original);
	assert.equal(original.proposal_hand.length, 1);
	assert.deepEqual(updated.snapshot?.proposal_hand, []);
	assert.equal(updated.snapshot?.year, original.year);
	assert.equal(updated.snapshot?.run_phase, original.run_phase);
	assert.equal(updated.snapshot?.term_outcome, original.term_outcome);
	assert.equal(updated.snapshot?.parliament_seat_anchors, original.parliament_seat_anchors);
	assert.equal(updated.snapshot?.draft_preview.vote.seat_votes[0].score, 9);
	assert.equal(updated.snapshot?.state_version, 2);
});

test('parliament.layout updates only seat anchors without changing gameplay version', () => {
	const original = makeLiveState(5);
	const layout = makeParliamentLayout();
	const error = { code: 'existing', message: 'Existing command error' };
	const value = { snapshot: original, error };
	const updated = applyGameMessage(value, { type: 'parliament.layout', payload: layout });

	assert.notEqual(updated.snapshot, original);
	assert.equal(updated.snapshot?.state_version, 5);
	assert.equal(updated.snapshot?.draft_preview, original.draft_preview);
	assert.deepEqual(updated.snapshot?.parliament_seat_anchors, [
		{ seat_index: 0, x: 0.25, y: 0.75 },
		{ seat_index: 3, x: 0.8, y: 0.2 }
	]);
	assert.equal(updated.error, error);
});

test('parliament.layout is ignored until a full snapshot is available', () => {
	assert.equal(
		applyGameMessage(EMPTY_GAME_STORE, {
			type: 'parliament.layout',
			payload: makeParliamentLayout()
		}),
		EMPTY_GAME_STORE
	);
});

test('stale domain sync and command errors do not mutate current game state', () => {
	const snapshot = makeLiveState(5);
	const value = { snapshot, error: null };
	const stale = applyGameMessage(value, { type: 'draft.sync', payload: makeDraftSync(4) });
	assert.equal(stale, value);

	const failed = applyGameMessage(value, {
		type: 'command.error',
		payload: { code: 'stale_command', message: '状态已变化', recover_full_state: true }
	});
	assert.equal(failed.snapshot, snapshot);
	assert.equal(failed.error?.code, 'stale_command');

	const replacement = { ...makeLiveState(6), proposal_hand: [] };
	const recovered = applyGameMessage(failed, { type: 'state.full', payload: replacement });
	assert.equal(recovered.snapshot, replacement);
	assert.equal(recovered.error, null);
});
