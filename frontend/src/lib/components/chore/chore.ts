export type ChoreFilterMode = 'default' | 'archives' | 'metric';
export type ChoreArchiveKey = 'constitution' | 'bill' | 'proposal' | 'policy';
export type ChoreMetricKey = 'tax' | 'price' | 'wage' | 'employment' | 'trade';

export type ChoreArchiveState = Record<ChoreArchiveKey, boolean>;
export type ChoreMetricState = Record<ChoreMetricKey, boolean>;

export const CHORE_ARCHIVE_OPTIONS = [
	{ key: 'constitution', text: '约法' },
	{ key: 'bill', text: '法案' },
	{ key: 'proposal', text: '提案' },
	{ key: 'policy', text: '政策' }
] as const;

export const CHORE_METRIC_OPTIONS = [
	{ key: 'tax', text: '税课' },
	{ key: 'price', text: '物价' },
	{ key: 'wage', text: '工钱' },
	{ key: 'employment', text: '用工' },
	{ key: 'trade', text: '商贸' }
] as const;

export function createChoreArchiveState(): ChoreArchiveState {
	return { constitution: false, bill: true, proposal: true, policy: true };
}

export function createChoreMetricState(): ChoreMetricState {
	return { tax: true, price: false, wage: true, employment: false, trade: false };
}
