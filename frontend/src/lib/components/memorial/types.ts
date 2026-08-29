export const MetricText = {
	Tax: '稅課',
	Consumption: '消費',
	Production: '生產',
	Employment: '就業',
	Investment: '投資',
	Lag: '滞后'
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
