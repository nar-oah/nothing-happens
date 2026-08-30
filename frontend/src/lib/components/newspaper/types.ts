import { Metric } from '$lib/game/types';

export const NewspaperRace = {
	HUMAN: 'human',
	ZHUSHUI: 'zhushui',
	PEACH_BLOSSOM: 'peach_blossom',
	NANKE: 'nanke',
	BIYI: 'biyi',
	YANOU: 'yanou'
} as const;

export type NewspaperRace = (typeof NewspaperRace)[keyof typeof NewspaperRace];

export const NewspaperEventState = {
	DETERIORATION: 'Deterioration',
	POSTPONED: 'Postponed',
	CALM: 'Calm'
} as const;

export type NewspaperEventState = (typeof NewspaperEventState)[keyof typeof NewspaperEventState];

export type NewspaperMetricData = {
	metric: Metric | string;
	value: number;
	change: number;
};

export type NewspaperFrontData = {
	title: string;
	content: string;
};

export type NewspaperEventData = {
	race: NewspaperRace;
	description: string;
	metric: Metric;
	value: number;
	countdown: number;
	strength: number;
	state: NewspaperEventState;
};

export const NEWSPAPER_METRIC_ORDER: Metric[] = [
	Metric.TAX,
	Metric.CONSUMPTION,
	Metric.PRODUCTION,
	Metric.EMPLOYMENT,
	Metric.INVESTMENT
];

const METRIC_LABELS: Record<Metric, string> = {
	[Metric.TAX]: '税課',
	[Metric.CONSUMPTION]: '消費',
	[Metric.PRODUCTION]: '生産',
	[Metric.EMPLOYMENT]: '就業',
	[Metric.INVESTMENT]: '投資'
};

const RACE_LABELS: Record<NewspaperRace, string> = {
	[NewspaperRace.HUMAN]: '人类',
	[NewspaperRace.ZHUSHUI]: '驻岁',
	[NewspaperRace.PEACH_BLOSSOM]: '桃花妖',
	[NewspaperRace.NANKE]: '南柯',
	[NewspaperRace.BIYI]: '比翼',
	[NewspaperRace.YANOU]: '偃偶'
};

const EVENT_STATE_LABELS: Record<NewspaperEventState, string> = {
	[NewspaperEventState.DETERIORATION]: '惡化 ↑',
	[NewspaperEventState.POSTPONED]: '暫緩 -',
	[NewspaperEventState.CALM]: '平息 ↓'
};

export function getNewspaperMetricLabel(metric: Metric | string): string {
	return typeof metric === 'string' ? metric : METRIC_LABELS[metric];
}

export function getNewspaperRaceLabel(race: NewspaperRace): string {
	return RACE_LABELS[race];
}

export function getNewspaperEventStateLabel(state: NewspaperEventState): string {
	return EVENT_STATE_LABELS[state];
}

export function formatNewspaperNumber(value: number): string {
	return value === 0 ? '談判' : String(Math.max(0, Math.trunc(value))).padStart(2, '0');
}
