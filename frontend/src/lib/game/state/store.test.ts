import assert from 'node:assert/strict';
import test from 'node:test';
import { applyGameMessage, EMPTY_GAME_STORE } from './store.ts';
import { makeDraftSync, makeLiveState } from './test-fixtures.ts';

test('state.full replaces the authoritative snapshot', () => {
	const first = makeLiveState(5);
	const replacement = { ...makeLiveState(6), year: 9, proposal_hand: [] };
	const loaded = applyGameMessage(EMPTY_GAME_STORE, { type: 'state.full', payload: first });
	const replaced = applyGameMessage(loaded, { type: 'state.full', payload: replacement });
	assert.equal(replaced.snapshot, replacement);
	assert.equal(replaced.snapshot?.year, 9);
	assert.deepEqual(replaced.snapshot?.proposal_hand, []);
});

test('newer domain sync updates its fields while stale sync is ignored', () => {
	const original = makeLiveState(5);
	const value = { snapshot: original, error: null };
	assert.equal(
		applyGameMessage(value, { type: 'draft.sync', payload: makeDraftSync(4) }),
		value
	);

	const next = makeDraftSync(6);
	const updated = applyGameMessage(value, { type: 'draft.sync', payload: next });
	assert.equal(updated.snapshot?.state_version, 6);
	assert.equal(updated.snapshot?.year, original.year);
	assert.deepEqual(updated.snapshot?.proposal_hand, next.proposal_hand);
});

test('command errors preserve the current snapshot and clear on full recovery', () => {
	const snapshot = makeLiveState(5);
	const failed = applyGameMessage(
		{ snapshot, error: null },
		{
			type: 'command.error',
			payload: { code: 'stale_command', message: '状态已变化', recover_full_state: true }
		}
	);
	assert.equal(failed.snapshot, snapshot);
	assert.equal(failed.error?.code, 'stale_command');

	const replacement = makeLiveState(6);
	const recovered = applyGameMessage(failed, { type: 'state.full', payload: replacement });
	assert.equal(recovered.snapshot, replacement);
	assert.equal(recovered.error, null);
});
