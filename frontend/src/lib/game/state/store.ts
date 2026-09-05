import { writable, type Readable } from 'svelte/store';
import type { CommandErrorDto, InboundMessage } from '../../bridge/protocol.ts';
import type { LiveGameState } from './types.ts';

export type GameStoreValue = {
	snapshot: LiveGameState | null;
	error: CommandErrorDto | null;
};

export type GameStore = Readable<GameStoreValue> & {
	apply(message: InboundMessage): void;
	clear(): void;
};

export const EMPTY_GAME_STORE: GameStoreValue = { snapshot: null, error: null };

export function createGameStore(initial: LiveGameState | null = null): GameStore {
	const store = writable<GameStoreValue>({ snapshot: initial, error: null });
	return {
		subscribe: store.subscribe,
		apply: (message) => store.update((value) => applyGameMessage(value, message)),
		clear: () => store.set(EMPTY_GAME_STORE)
	};
}

export function applyGameMessage(value: GameStoreValue, message: InboundMessage): GameStoreValue {
	if (message.type === 'state.full') return { snapshot: message.payload, error: null };
	if (message.type === 'command.error') return { ...value, error: message.payload };
	if (message.type === 'parliament.layout')
		return value.snapshot
			? {
					...value,
					snapshot: {
						...value.snapshot,
						parliament_seat_anchors: message.payload.parliament_seat_anchors
					}
				}
			: value;
	if (!value.snapshot || message.payload.state_version < value.snapshot.state_version) return value;

	const snapshot = value.snapshot;
	switch (message.type) {
		case 'draft.sync':
			return {
				snapshot: {
					...snapshot,
					state_version: message.payload.state_version,
					proposal_hand: message.payload.proposal_hand,
					draft_bill: message.payload.draft_bill,
					editing_saved_bill_index: message.payload.editing_saved_bill_index,
					draft_preview: message.payload.draft_preview,
					saved_bills: message.payload.saved_bills ?? snapshot.saved_bills
				},
				error: null
			};
		case 'proposal.sync':
			return {
				snapshot: {
					...snapshot,
					state_version: message.payload.state_version,
					proposal_hand: message.payload.proposal_hand,
					political_donation_pool: message.payload.political_donation_pool,
					pending_dialogue: message.payload.pending_dialogue,
					ui_mode: message.payload.ui_mode,
					world_scene: message.payload.world_scene
				},
				error: null
			};
		case 'bill.result':
			return {
				snapshot: {
					...snapshot,
					...message.payload.status,
					state_version: message.payload.state_version,
					saved_bills: message.payload.saved_bills,
					proposal_hand: message.payload.proposal_hand,
					draft_bill: message.payload.draft_bill,
					editing_saved_bill_index: message.payload.editing_saved_bill_index,
					active_bill: message.payload.active_bill,
					draft_preview: message.payload.draft_preview,
					pending_dialogue: message.payload.pending_dialogue,
					ui_mode: message.payload.ui_mode,
					world_scene: message.payload.world_scene
				},
				error: null
			};
	}
}
