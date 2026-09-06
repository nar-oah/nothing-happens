import { translate } from '../../i18n/index.ts';

export const MetricText = {
	Tax: translate('game.metric.tax', undefined, 'zh_CN'),
	Consumption: translate('game.metric.consumption', undefined, 'zh_CN'),
	Production: translate('game.metric.production', undefined, 'zh_CN'),
	Employment: translate('game.metric.employment', undefined, 'zh_CN'),
	Investment: translate('game.metric.investment', undefined, 'zh_CN'),
	Lag: translate('memorial.lag', undefined, 'zh_CN')
} as const;

export const MetricSymbol = {
	Increase: '+',
	Decrease: '-'
} as const;

export type MetricSymbol = (typeof MetricSymbol)[keyof typeof MetricSymbol];

export type MemorialMetricData = {
	text: string;
	symbol?: MetricSymbol;
	value: number | string;
	isReverse?: boolean;
};

export type MemorialHorizontalContentData = {
	title?: string;
	body: string;
	redacted?: boolean;
};

export type MemorialProposalContentData = {
	proposalTitle: string;
	content: MemorialHorizontalContentData;
};

export type MemorialPolicyContentData = {
	policyTitle: string;
	content: MemorialHorizontalContentData;
};

export type MemorialConstitutionRowData = {
	text: string;
	number: string | number;
	selected: boolean;
	selectable: boolean;
};

export type MemorialConstitutionRowContentData = MemorialConstitutionRowData & {
	articleRef?: number;
	contents: MemorialHorizontalContentData[];
	policies: MemorialPolicyContentData[];
};

export type MemorialConstitutionData = Record<
	string,
	number | MemorialConstitutionRowContentData[]
>;
