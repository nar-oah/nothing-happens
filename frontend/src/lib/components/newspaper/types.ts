import { Metric } from '../../game/types.ts';
import { translate, type Translate } from '../../i18n/index.ts';

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
	metric: Metric | string;
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

const METRIC_KEYS: Record<Metric, string> = {
	[Metric.TAX]: 'tax',
	[Metric.CONSUMPTION]: 'consumption',
	[Metric.PRODUCTION]: 'production',
	[Metric.EMPLOYMENT]: 'employment',
	[Metric.INVESTMENT]: 'investment'
};

export function getNewspaperMetricLabel(
	metric: Metric | string,
	translator: Translate = translate
): string {
	return typeof metric === 'string' ? metric : translator(`game.metric.${METRIC_KEYS[metric]}`);
}

export function getNewspaperRaceLabel(
	race: NewspaperRace,
	translator: Translate = translate
): string {
	return translator(`race.${race}`);
}

export function getNewspaperEventStateLabel(
	state: NewspaperEventState,
	translator: Translate = translate
): string {
	return translator(`newspaper.${state}`);
}

export function formatNewspaperNumber(value: number, translator: Translate = translate): string {
	return value === 0
		? translator('newspaper.negotiation')
		: String(Math.max(0, Math.trunc(value))).padStart(2, '0');
}
