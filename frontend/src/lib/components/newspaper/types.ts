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
	metric: Metric;
	value: number;
	change: number;
};

export type NewspaperEventData = {
	race: NewspaperRace;
	metric: Metric;
	value: number;
	countdown: number;
	strength: number;
	state: NewspaperEventState;
};

export type NewspaperCommentData = {
	title: string;
	comment: string;
};

export const NEWSPAPER_METRIC_ORDER: Metric[] = [
	Metric.TAX,
	Metric.CONSUMPTION,
	Metric.PRODUCTION,
	Metric.EMPLOYMENT,
	Metric.INVESTMENT
];

const METRIC_LABELS: Record<Metric, string> = {
	[Metric.TAX]: '稅課',
	[Metric.CONSUMPTION]: '消費',
	[Metric.PRODUCTION]: '生產',
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

const RACE_EVENT_DESCRIPTIONS: Record<NewspaperRace, string> = {
	[NewspaperRace.HUMAN]: '朝使认为国用与贡路正在偏离朝廷要求，催促联合政府尽快纠正。',
	[NewspaperRace.ZHUSHUI]: '现行秩序正在偏离驻岁所能承受的节律，驻岁要求联合政府尽快纠正。',
	[NewspaperRace.PEACH_BLOSSOM]: '外部征敛与市场往来继续牵动地方生活，桃源要求收束与外界的联系。',
	[NewspaperRace.NANKE]: '连续轮班与现实劳动正在挤压睡眠，南柯要求改善眼前的劳动处境。',
	[NewspaperRace.BIYI]: '公共秩序仍在偏离当月清醒半身的尺度，比翼要求尽快纠正。',
	[NewspaperRace.YANOU]: '行身制造、维修与流通条件继续偏离机谱秩序，偃偶要求恢复稳定。'
};

const EVENT_STATE_LABELS: Record<NewspaperEventState, string> = {
	[NewspaperEventState.DETERIORATION]: '惡化 ↑',
	[NewspaperEventState.POSTPONED]: '暫緩 -',
	[NewspaperEventState.CALM]: '平息 ↓'
};

export function getNewspaperMetricLabel(metric: Metric): string {
	return METRIC_LABELS[metric];
}

export function getNewspaperRaceLabel(race: NewspaperRace): string {
	return RACE_LABELS[race];
}

export function getNewspaperEventDescription(race: NewspaperRace): string {
	return RACE_EVENT_DESCRIPTIONS[race];
}

export function getNewspaperEventStateLabel(state: NewspaperEventState): string {
	return EVENT_STATE_LABELS[state];
}

export function formatNewspaperNumber(value: number): string {
	return String(Math.max(0, Math.trunc(value))).padStart(2, '0');
}
