import assert from 'node:assert/strict';
import test from 'node:test';
import { applyGameMessage, EMPTY_GAME_STORE } from './store.ts';
import { makeDraftSync, makeLiveState } from './test-fixtures.ts';

test('state.full replaces the complete snapshot', () => {
	const first = makeLiveState(5);
	const replacement = { ...makeLiveState(2), year: 9, proposal_hand: [] };
	const loaded = applyGameMessage(EMPTY_GAME_STORE, { type: 'state.full', payload: first });
	const replaced = applyGameMessage(loaded, { type: 'state.full', payload: replacement });
	assert.equal(replaced.snapshot, replacement);
	assert.equal(replaced.snapshot?.year, 9);
	assert.deepEqual(replaced.snapshot?.proposal_hand, []);
});

test('domain sync immutably overwrites only its authoritative fields', () => {
	const original = makeLiveState(1);
	const value = { snapshot: original, error: null };
	const updated = applyGameMessage(value, { type: 'draft.sync', payload: makeDraftSync(2) });
	assert.notEqual(updated.snapshot, original);
	assert.equal(original.proposal_hand.length, 1);
	assert.deepEqual(updated.snapshot?.proposal_hand, []);
	assert.equal(updated.snapshot?.year, original.year);
	assert.equal(updated.snapshot?.state_version, 2);
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
