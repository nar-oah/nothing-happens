import type {
	BillResultDto,
	DraftSyncDto,
	LiveGameState,
	ProposalSyncDto,
	UiMode
} from '../game/state/types.ts';

export type RequestId = string;

export type NormalizedRect = {
	x: number;
	y: number;
	width: number;
	height: number;
};

export type CommandErrorDto = {
	code: string;
	message: string;
	state_version?: number;
	recover_full_state?: boolean;
};

export type OutboundPayloads = {
	'ui.ready': Record<string, never>;
	'ui.input_regions': { regions: NormalizedRect[] };
	'ui.mode.set': { state_version: number; mode: UiMode };
	'ui.newspaper.close': Record<string, never>;
	'draft.proposal.add': { state_version: number; hand_index: number };
	'draft.proposal.remove': { state_version: number; draft_index: number };
	'draft.policy.add': { state_version: number; display_name: string };
	'draft.policy.remove': { state_version: number; draft_index: number };
	'draft.title.set': { state_version: number; title: string };
	'bill.new': { state_version: number };
	'bill.edit': { state_version: number; saved_bill_index: number };
	'bill.submit': { state_version: number };
	'proposal.merge': {
		state_version: number;
		hand_indices: number[];
		negative_base_index: number;
		selected_positive_index: number | null;
	};
	'proposal.bonus.resolve': {
		state_version: number;
		hand_index: number;
		accept_trait: boolean;
	};
	'constitution.revise': { state_version: number; article_index: number };
	'constitution.column.unlock': { state_version: number; column_index: number };
	'month.advance': { state_version: number };
	'term.next': { state_version: number };
};

export type OutboundType = keyof OutboundPayloads;
export type GameplayCommandType = Exclude<
	OutboundType,
	'ui.ready' | 'ui.input_regions' | 'ui.newspaper.close'
>;

export type OutboundMessage<T extends OutboundType = OutboundType> = T extends OutboundType
	? {
			type: T;
			request_id?: RequestId;
			payload: OutboundPayloads[T];
		}
	: never;

export type InboundPayloads = {
	'state.full': LiveGameState;
	'draft.sync': DraftSyncDto;
	'proposal.sync': ProposalSyncDto;
	'bill.result': BillResultDto;
	'command.error': CommandErrorDto;
};

export type InboundType = keyof InboundPayloads;

export type InboundMessage<T extends InboundType = InboundType> = T extends InboundType
	? {
			type: T;
			request_id?: RequestId;
			payload: InboundPayloads[T];
		}
	: never;

export type DecodeResult<T> = { ok: true; value: T } | { ok: false; error: string };

export class CommandError extends Error {
	readonly code: string;
	readonly requestId?: string;
	readonly recoverFullState: boolean;

	constructor(payload: CommandErrorDto, requestId?: string) {
		super(payload.message);
		this.name = 'CommandError';
		this.code = payload.code;
		this.requestId = requestId;
		this.recoverFullState = payload.recover_full_state ?? false;
	}
}
