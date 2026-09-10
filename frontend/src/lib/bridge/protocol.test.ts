import assert from 'node:assert/strict';
import test from 'node:test';
import { makeLiveState } from '../game/state/test-fixtures.ts';
import type { OutboundMessage } from './protocol.ts';
import { decodeInboundMessage, encodeOutboundMessage } from './validation.ts';

test('IPC round-trips a representative command and authoritative snapshot', () => {
	const command: OutboundMessage = {
		type: 'draft.proposal.add',
		request_id: 'ui-1',
		payload: { state_version: 4, hand_index: 2 }
	};
	assert.deepEqual(JSON.parse(encodeOutboundMessage(command)), command);

	const decoded = decodeInboundMessage(
		JSON.stringify({ type: 'state.full', request_id: 'ui-1', payload: makeLiveState(4) })
	);
	assert.equal(decoded.ok, true);
	if (decoded.ok) {
		assert.equal(decoded.value.type, 'state.full');
		assert.equal(decoded.value.request_id, 'ui-1');
	}
});

test('IPC rejects malformed command and state payloads', () => {
	assert.throws(
		() =>
			encodeOutboundMessage({
				type: 'settings.language.set',
				payload: { language: 'fr' }
			} as unknown as OutboundMessage),
		TypeError
	);
	assert.deepEqual(
		decodeInboundMessage(
			JSON.stringify({ type: 'state.full', payload: { ...makeLiveState(5), collapse_level: 1.5 } })
		),
		{ ok: false, error: 'Invalid payload for state.full' }
	);
	const invalidPlanState = makeLiveState(5);
	invalidPlanState.draft_preview.minimum_donation_plan = { seat_indices: [0], cost: 2 };
	assert.deepEqual(
		decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: invalidPlanState })),
		{ ok: false, error: 'Invalid payload for state.full' }
	);
	invalidPlanState.draft_preview.minimum_donation_plan = { seat_indices: [0, 0], cost: 2 };
	assert.deepEqual(
		decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: invalidPlanState })),
		{ ok: false, error: 'Invalid payload for state.full' }
	);
	assert.throws(
		() =>
			encodeOutboundMessage({
				type: 'bill.submit',
				payload: { state_version: 5, bribed_seat_indices: [1, 1] }
			}),
		TypeError
	);
});
