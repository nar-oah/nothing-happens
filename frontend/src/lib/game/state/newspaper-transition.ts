import type {
	NewspaperCommentData,
	NewspaperEventData,
	NewspaperMetricData
} from '../../components/newspaper/types.ts';

export type NewspaperMode = 'MONTHLY' | 'TERM_END';
export type NewspaperTermOutcome = 'NONE' | 'COLLAPSE' | 'NOTHING_HAPPENS';

type NewspaperDataBase = {
	term: number;
	year: number;
	month: number;
	metrics: NewspaperMetricData[];
	events: NewspaperEventData[];
	comment: NewspaperCommentData;
};

export type DisplayedNewspaperData =
	| (NewspaperDataBase & { mode: 'MONTHLY' })
	| (NewspaperDataBase & {
			mode: 'TERM_END';
			termOutcome: Exclude<NewspaperTermOutcome, 'NONE'>;
			governingMonths: number;
	  });

export type NewspaperTransitionState = {
	open: boolean;
	busy: boolean;
	leaving: boolean;
	backgroundCovered: boolean;
	displayedNewspaperData: DisplayedNewspaperData | null;
	pendingNewspaperData: DisplayedNewspaperData | null;
	entryCycle: number;
};

export function createNewspaperTransitionState(): NewspaperTransitionState {
	return {
		open: false,
		busy: false,
		leaving: false,
		backgroundCovered: false,
		displayedNewspaperData: null,
		pendingNewspaperData: null,
		entryCycle: 0
	};
}

export function openNewspaperTransition(
	state: NewspaperTransitionState,
	data: DisplayedNewspaperData,
	busy = false
): NewspaperTransitionState {
	return {
		...state,
		open: true,
		busy,
		leaving: false,
		backgroundCovered: false,
		displayedNewspaperData: data,
		pendingNewspaperData: null,
		entryCycle: state.entryCycle + 1
	};
}

export function coverNewspaperTransition(
	state: NewspaperTransitionState
): NewspaperTransitionState {
	return { ...state, backgroundCovered: true };
}

export function leaveNewspaperTransition(
	state: NewspaperTransitionState,
	latestData: DisplayedNewspaperData | null = null
): NewspaperTransitionState {
	const terminalSwap =
		latestData?.mode === 'TERM_END' && state.displayedNewspaperData?.mode !== 'TERM_END';
	return {
		...state,
		busy: true,
		leaving: true,
		backgroundCovered: terminalSwap,
		pendingNewspaperData: terminalSwap ? latestData : null
	};
}

export function finishNewspaperTransition(
	state: NewspaperTransitionState
): NewspaperTransitionState {
	if (state.pendingNewspaperData) {
		return {
			...state,
			busy: false,
			leaving: false,
			backgroundCovered: true,
			displayedNewspaperData: state.pendingNewspaperData,
			pendingNewspaperData: null,
			entryCycle: state.entryCycle + 1
		};
	}
	return {
		...state,
		open: false,
		busy: false,
		leaving: false,
		backgroundCovered: false,
		pendingNewspaperData: null
	};
}
