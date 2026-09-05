import assert from 'node:assert/strict';
import test from 'node:test';
import { applyGameMessage, EMPTY_GAME_STORE } from './store.ts';
import { deriveSaveItems, getSaveAction } from './saves.ts';
import type { SaveSlotDto } from './types.ts';
import { makeDraftSync, makeLiveState, makeParliamentLayout } from './test-fixtures.ts';

const automaticSave: SaveSlotDto = {
	slot_id: 'auto',
	automatic: true,
	term: 2,
	year: 3,
	month: 4,
	saved_at: '2026-09-05T10:00:00'
};
const manualSave: SaveSlotDto = {
	...automaticSave,
	slot_id: 'manual-1',
	automatic: false,
	term: 1,
	year: 1,
	month: 2
};

test('save list synchronization preserves gameplay and clears command errors', () => {
	const original = makeLiveState(12);
	const saves = [manualSave, automaticSave];
	const updated = applyGameMessage(
		{ snapshot: original, error: { code: 'save_failed', message: '写入失败' } },
		{ type: 'saves.list', payload: { saves } }
	);
	assert.deepEqual(updated.snapshot, { ...original, saves });
	assert.equal(updated.snapshot?.proposal_hand, original.proposal_hand);
	assert.equal(updated.snapshot?.draft_preview, original.draft_preview);
	assert.equal(updated.error, null);
	assert.deepEqual(original.saves, []);
});

test('saving keeps manual slots first and current progress last without altering stored auto', () => {
	const current = { term: 4, year: 1, month: 0 };
	const items = deriveSaveItems([automaticSave, manualSave], current, false);
	assert.deepEqual(
		items.map(({ slot }) => slot.slot_id),
		['manual-1', 'auto']
	);
	assert.deepEqual(
		items.map(({ item }) => item),
		[
			{ text: '第 1 任', value: '1 年 2 月' },
			{ text: '第 4 任', value: '1 年 0 月' }
		]
	);
	assert.deepEqual(getSaveAction(items[0].slot, false), {
		type: 'saves.overwrite',
		payload: { slot_id: 'manual-1' }
	});
	assert.deepEqual(getSaveAction(items[1].slot, false), { type: 'saves.create', payload: {} });
	assert.equal(automaticSave.term, 2);
	assert.equal(deriveSaveItems([], current, false).length, 1);
});

test('loading shows actual saved dates and reads any slot including the last automatic slot', () => {
	const current = { term: 1, year: 1, month: 2 };
	const items = deriveSaveItems([automaticSave, manualSave], current, true);
	assert.deepEqual(
		items.map(({ slot }) => slot),
		[manualSave, automaticSave]
	);
	assert.equal(items[1].item.value, '3 年 4 月');
	for (const { slot } of items) {
		assert.deepEqual(getSaveAction(slot, true), {
			type: 'saves.load',
			payload: { slot_id: slot.slot_id }
		});
	}
	assert.deepEqual(deriveSaveItems([], current, true), []);
});

test('state.full replaces the complete snapshot', () => {
	const first = makeLiveState(5);
	const replacement = {
		...makeLiveState(2),
		year: 9,
		governing_months: 25,
		run_phase: 'TERM_ENDED' as const,
		term_outcome: 'COLLAPSE' as const,
		proposal_hand: [],
		saves: [manualSave, automaticSave]
	};
	const loaded = applyGameMessage(EMPTY_GAME_STORE, { type: 'state.full', payload: first });
	const replaced = applyGameMessage(loaded, { type: 'state.full', payload: replacement });
	assert.equal(replaced.snapshot, replacement);
	assert.equal(replaced.snapshot?.year, 9);
	assert.equal(replaced.snapshot?.governing_months, 25);
	assert.equal(replaced.snapshot?.run_phase, 'TERM_ENDED');
	assert.equal(replaced.snapshot?.term_outcome, 'COLLAPSE');
	assert.deepEqual(replaced.snapshot?.proposal_hand, []);
	assert.deepEqual(replaced.snapshot?.saves, [manualSave, automaticSave]);
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
