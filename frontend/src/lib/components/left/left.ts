import {
	METRICS,
	METRIC_DISPLAY_NAMES,
	Metric,
	getBillMetrics,
	getMetricValue,
	getPolicyMetrics,
	getProposalTotalEffect
} from '../../game/index.ts';
import { MetricSymbol, type MemorialMetricData } from '../memorial/types';
import type {
	ArchiveFilterState,
	LeftItem,
	LeftItemKind,
	ProposalLeftItem,
	ProposalPreview,
	SynthesisFilterState
} from './types';

export const LEFT_KIND_LABELS: Record<LeftItemKind, string> = {
	constitution: '约法',
	bill: '法案',
	proposal: '提案',
	policy: '政策'
};

export const LEFT_METRIC_LABELS: Record<Metric, string> = {
	[Metric.TAX]: '税课',
	[Metric.PRICE]: '物价',
	[Metric.WAGE]: '工钱',
	[Metric.EMPLOYMENT]: '用工',
	[Metric.TRADE]: '商贸'
};

export function isSameLeftRef(first: LeftItem['ref'], second: LeftItem['ref']): boolean {
	return first.collection === second.collection && first.index === second.index;
}

export function getLeftItemMetrics(item: LeftItem): Metric[] {
	switch (item.kind) {
		case 'constitution':
			return getBillMetrics([], item.constitution.policies);
		case 'bill':
			return getBillMetrics(item.bill.proposals, item.bill.policies);
		case 'proposal':
			return METRICS.filter(
				(metric) => getMetricValue(getProposalTotalEffect(item.proposal), metric) !== 0
			);
		case 'policy':
			return getPolicyMetrics(item.policy);
	}
}

export function filterArchiveItems(items: LeftItem[], state: ArchiveFilterState): LeftItem[] {
	return items.filter(
		(item) =>
			state.kinds.includes(item.kind) &&
			state.metrics.some((metric) => getLeftItemMetrics(item).includes(metric))
	);
}

export function sortArchiveItems(items: LeftItem[], state: ArchiveFilterState): LeftItem[] {
	const queues = new Map<LeftItemKind, LeftItem[]>();
	for (const kind of Object.keys(LEFT_KIND_LABELS) as LeftItemKind[]) {
		const sameKind = items.filter((item) => item.kind === kind);
		queues.set(
			kind,
			kind === 'proposal'
				? sortProposalItems(sameKind as ProposalLeftItem[], state)
				: kind === 'bill'
					? stableSort(sameKind, (first, second) =>
							compare(first.ref.index, second.ref.index, state.timeAscending)
						)
					: sameKind
		);
	}
	const cursors = new Map<LeftItemKind, number>();
	return items.map((item) => {
		const index = cursors.get(item.kind) ?? 0;
		cursors.set(item.kind, index + 1);
		return queues.get(item.kind)?.[index] ?? item;
	});
}

export function getProposalGroupOptions(items: ProposalLeftItem[]): string[] {
	return [...new Set(items.map((item) => item.proposal.source_group.display_name))];
}

export function deriveSynthesisItems(
	items: ProposalLeftItem[],
	state: SynthesisFilterState
): ProposalLeftItem[] {
	const filtered = items.filter(
		(item) =>
			(!state.group || item.proposal.source_group.display_name === state.group) &&
			state.metrics.some((metric) => getLeftItemMetrics(item).includes(metric))
	);
	return sortProposalItems(filtered, state);
}

export function sortProposalItemsByTime(
	items: ProposalLeftItem[],
	ascending: boolean
): ProposalLeftItem[] {
	return stableSort(items, (first, second) =>
		compare(first.ref.index, second.ref.index, ascending)
	);
}

export function sortProposalItemsByValue(
	items: ProposalLeftItem[],
	metrics: Metric[],
	ascending: boolean
): ProposalLeftItem[] {
	return stableSort(items, (first, second) =>
		compareProposalValues(first, second, metrics, ascending)
	);
}

export function toggleProposalSelection(
	selected: ProposalLeftItem[],
	item: ProposalLeftItem,
	limit = 3
): ProposalLeftItem[] {
	const selectedIndex = selected.findIndex((current) => isSameLeftRef(current.ref, item.ref));
	if (selectedIndex >= 0) return selected.filter((_, index) => index !== selectedIndex);
	return selected.length >= limit ? selected : [...selected, item];
}

export function moveSelectedProposalsFirst(
	items: ProposalLeftItem[],
	selected: ProposalLeftItem[]
): ProposalLeftItem[] {
	const visibleSelected = selected.filter((selectedItem) =>
		items.some((item) => isSameLeftRef(item.ref, selectedItem.ref))
	);
	const rest = items.filter(
		(item) => !visibleSelected.some((selectedItem) => isSameLeftRef(item.ref, selectedItem.ref))
	);
	return [...visibleSelected, ...rest];
}

export function proposalToMemorialMetrics(proposal: ProposalLeftItem['proposal']): MemorialMetricData[] {
	const ordinary = METRICS.flatMap((metric) =>
		makeMetric(metric, getMetricValue(proposal.base_effect, metric), false)
	);
	const reverse = METRICS.flatMap((metric) =>
		makeMetric(metric, getMetricValue(proposal.positive_effect, metric), true)
	);
	return [...ordinary, ...reverse];
}

export function createProposalSynthesisPreview(selected: ProposalLeftItem[]): ProposalPreview {
	const ordinary = METRICS.flatMap((metric): MemorialMetricData[] => {
		const values = selected.map((item) => getMetricValue(item.proposal.base_effect, metric));
		if (values.every((value) => value === 0)) return [];
		return [{ text: METRIC_DISPLAY_NAMES[metric], value: `${Math.min(...values)}~${Math.max(...values)}` }];
	});
	const reverseCandidates = selected.flatMap((item, selectionIndex) =>
		METRICS.flatMap((metric) => {
			const raw = getMetricValue(item.proposal.positive_effect, metric);
			return raw === 0 ? [] : [{ item, metric, raw, selectionIndex }];
		})
	);
	reverseCandidates.sort(
		(first, second) => Math.abs(second.raw) - Math.abs(first.raw) || first.selectionIndex - second.selectionIndex
	);
	const reverse = reverseCandidates[0];
	return {
		metrics: [
			...ordinary,
			...(reverse
				? makeMetric(reverse.metric, reverse.raw, true)
				: [])
		],
		reverseSource: reverse?.item
	};
}

function sortProposalItems(
	items: ProposalLeftItem[],
	state: Pick<ArchiveFilterState, 'metrics' | 'timeAscending' | 'valueAscending'>
): ProposalLeftItem[] {
	return stableSort(items, (first, second) => {
		const byValue = compareProposalValues(first, second, state.metrics, state.valueAscending);
		return byValue || compare(first.ref.index, second.ref.index, state.timeAscending);
	});
}

function compareProposalValues(
	first: ProposalLeftItem,
	second: ProposalLeftItem,
	metrics: Metric[],
	ascending: boolean
): number {
	for (const metric of METRICS.filter((metric) => metrics.includes(metric))) {
		const result = compare(
			getMetricValue(getProposalTotalEffect(first.proposal), metric),
			getMetricValue(getProposalTotalEffect(second.proposal), metric),
			ascending
		);
		if (result) return result;
	}
	return 0;
}

function makeMetric(metric: Metric, raw: number, isReverse: boolean): MemorialMetricData[] {
	return raw === 0
		? []
		: [{
				text: METRIC_DISPLAY_NAMES[metric],
				symbol: raw > 0 ? MetricSymbol.Increase : MetricSymbol.Decrease,
				value: Math.abs(raw),
				isReverse
			}];
}

function compare(first: number, second: number, ascending: boolean): number {
	return (first - second) * (ascending ? 1 : -1);
}

function stableSort<T>(items: T[], compareItems: (first: T, second: T) => number): T[] {
	return items
		.map((item, index) => ({ item, index }))
		.sort((first, second) => compareItems(first.item, second.item) || first.index - second.index)
		.map(({ item }) => item);
}
