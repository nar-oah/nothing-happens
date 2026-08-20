export const FOLD_WIDTH = 230;
export const FOLD_HEIGHT = 82;
export const VERTICAL_FOLD_WIDTH = 123;
export const VERTICAL_FOLD_HEIGHT = 345;
export const VERTICAL_FOLD_SKEW = 9.25;

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
	text: MetricText;
	symbol?: MetricSymbol;
	value: number;
	isReverse?: boolean;
};

export type MemorialProposalContentData = {
	title: string;
	body: string;
};

export type MemorialPolicyContentData = MemorialProposalContentData;

export type MemorialConstitutionContentData =
	| {
			title: string;
			locked: true;
			requirement: string | number;
			rows?: never;
	  }
	| {
			title: string;
			locked: false;
			requirement?: never;
			rows: MemorialConstitutionRowData[];
	  };

export type MemorialConstitutionRowData = {
	text: string;
	number: string | number;
	selected: boolean;
};
