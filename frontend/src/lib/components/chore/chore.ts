export type ChoreFilterMode = 'default' | 'archives' | 'metric';
export type ChoreArchiveKey = 'constitution' | 'bill' | 'proposal' | 'policy';
export type ChoreMetricKey = 'tax' | 'consumption' | 'production' | 'employment' | 'investment';

export type ChoreArchiveState = Record<ChoreArchiveKey, boolean>;
export type ChoreMetricState = Record<ChoreMetricKey, boolean>;

export type ChoreFilterOptions = {
	options: string[];
	selected: string[];
	multiple: boolean;
};

export type ChoreFilterValue = ChoreFilterOptions | boolean;
export type ChoreFilters = Record<string, ChoreFilterValue>;

export const CHORE_ARCHIVE_OPTIONS = [
	{ key: 'constitution', text: '约法' },
	{ key: 'bill', text: '法案' },
	{ key: 'proposal', text: '提案' },
	{ key: 'policy', text: '政策' }
] as const;

export const CHORE_METRIC_OPTIONS = [
	{ key: 'tax', text: '税课' },
	{ key: 'consumption', text: '消费' },
	{ key: 'production', text: '生产' },
	{ key: 'employment', text: '就业' },
	{ key: 'investment', text: '投资' }
] as const;

export function createChoreArchiveState(): ChoreArchiveState {
	return { constitution: false, bill: true, proposal: true, policy: true };
}

export function createChoreMetricState(): ChoreMetricState {
	return { tax: true, consumption: false, production: true, employment: false, investment: false };
}
