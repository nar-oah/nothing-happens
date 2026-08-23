export enum MetricText {
	Tax = '税課',
	Price = '物價',
	Wage = '工錢',
	Employment = '用工',
	Trade = '商貿',
	Lag = '滞后'
}

export enum MetricSymbol {
	Increase = '+',
	Decrease = '-'
}

export type MemorialMetricData = {
	text: string;
	symbol?: MetricSymbol;
	value: number;
	isReverse?: boolean;
};

export type MemorialHorizontalContentData = {
	title?: string;
	body: string;
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
	contents: MemorialHorizontalContentData[];
	policies: MemorialPolicyContentData[];
};

export type MemorialConstitutionData = Record<
	string,
	number | MemorialConstitutionRowContentData[]
>;
