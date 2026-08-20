export const FOLD_WIDTH = 230;
export const FOLD_HEIGHT = 82;

export enum MetricText {
	Tax = '税課',
	Price = '物價',
	Wage = '工錢',
	Employment = '用工',
	Trade = '商貿'
}

export enum MetricSymbol {
	Increase = '+',
	Decrease = '-'
}

export type MemorialMetricData = {
	text: MetricText;
	symbol: MetricSymbol;
	value: number;
	isReverse?: boolean;
};

export type MemorialConstitutionRowData = {
	text: string;
	number: string | number;
	selected: boolean;
};
