<script lang="ts">
	import { Metric } from '$lib/game';
	import ChoreFilter from '../chore/ChoreFilter.svelte';
	import type { ChoreFilters } from '../chore/chore';
	import Mark from '../mark/Mark.svelte';
	import MemorialBillClosed from '../memorial/closed/MemorialBillClosed.svelte';
	import MemorialConstitutionClosed from '../memorial/closed/MemorialConstitutionClosed.svelte';
	import MemorialProposalClosed from '../memorial/closed/MemorialProposalClosed.svelte';
	import MemorialProposalOption from '../memorial/closed/MemorialProposalOption.svelte';
	import {
		LEFT_KIND_LABELS,
		LEFT_METRIC_LABELS,
		createProposalSynthesisPreview,
		deriveSynthesisItems,
		filterArchiveItems,
		getProposalGroupOptions,
		isSameLeftRef,
		moveSelectedProposalsFirst,
		proposalToMemorialMetrics,
		sortArchiveItems,
		toggleProposalSelection
	} from './left';
	import type {
		ArchiveFilterState,
		LeftItem,
		LeftItemKind,
		LeftProps,
		ProposalLeftItem,
		SynthesisFilterState
	} from './types';

	let { items, baseline, onItemSelect, onSynthesisConfirm }: LeftProps = $props();
	let synthesisMode = $state(false);
	let selectedProposals = $state<ProposalLeftItem[]>([]);
	let leftFilters = $state<ChoreFilters>({
		类型: {
			options: Object.values(LEFT_KIND_LABELS),
			selected: Object.values(LEFT_KIND_LABELS),
			multiple: true
		},
		指标: {
			options: Object.values(LEFT_METRIC_LABELS),
			selected: ['税课'],
			multiple: true
		},
		时间: false,
		数值: false
	});
	let rightFilters = $state<ChoreFilters>({
		利益集团: { options: [], selected: [], multiple: false },
		指标: {
			options: Object.values(LEFT_METRIC_LABELS),
			selected: ['商贸'],
			multiple: true
		},
		时间: false,
		数值: false
	});

	let proposalItems: ProposalLeftItem[] = $derived(
		items.filter((item): item is ProposalLeftItem => item.kind === 'proposal')
	);
	let groupOptions = $derived(getProposalGroupOptions(proposalItems));
	let archiveState: ArchiveFilterState = $derived({
		kinds: selectedOptions(leftFilters, '类型').flatMap((label) =>
			(Object.entries(LEFT_KIND_LABELS) as [LeftItemKind, string][]).flatMap(([kind, text]) =>
				text === label ? [kind] : []
			)
		),
		metrics: metricOptions(leftFilters),
		timeAscending: direction(leftFilters, '时间'),
		valueAscending: direction(leftFilters, '数值')
	});
	let archiveItems = $derived(
		sortArchiveItems(filterArchiveItems(items, archiveState), archiveState)
	);
	let synthesisState: SynthesisFilterState = $derived({
		group: selectedOptions(rightFilters, '利益集团')[0],
		metrics: metricOptions(rightFilters),
		timeAscending: direction(rightFilters, '时间'),
		valueAscending: direction(rightFilters, '数值')
	});
	let availableSynthesisItems = $derived(deriveSynthesisItems(proposalItems, synthesisState));
	let synthesisItems = $derived(
		moveSelectedProposalsFirst(availableSynthesisItems, selectedProposals)
	);
	let confirming = $derived(selectedProposals.length === 3);
	let synthesisPreview = $derived(createProposalSynthesisPreview(selectedProposals));

	$effect(() => {
		const filter = rightFilters['利益集团'];
		if (typeof filter === 'boolean') return;
		const current = filter.selected[0];
		const selected = current && groupOptions.includes(current) ? [current] : groupOptions.slice(0, 1);
		if (
			filter.options.join('\u0000') !== groupOptions.join('\u0000') ||
			filter.selected.join('\u0000') !== selected.join('\u0000')
		) {
			rightFilters = { ...rightFilters, 利益集团: { ...filter, options: groupOptions, selected } };
		}
	});

	$effect(() => {
		const visible = selectedProposals.filter((selected) =>
			availableSynthesisItems.some((item) => isSameLeftRef(item.ref, selected.ref))
		);
		if (visible.length !== selectedProposals.length) selectedProposals = visible;
	});

	function selectProposal(item: ProposalLeftItem) {
		if (confirming && !selectedProposals.some((selected) => isSameLeftRef(selected.ref, item.ref))) {
			return;
		}
		selectedProposals = toggleProposalSelection(selectedProposals, item);
	}

	function confirmSynthesis() {
		if (selectedProposals.length !== 3) return;
		onSynthesisConfirm?.({
			proposals: selectedProposals,
			refs: selectedProposals.map((item) => item.ref),
			reverseSource: synthesisPreview.reverseSource
		});
		selectedProposals = [];
	}

	function optionFor(item: ProposalLeftItem): string {
		if (!confirming) return '选中';
		return isSameLeftRef(selectedProposals[2].ref, item.ref) ? '取消' : '确认';
	}

	function activateOption(item: ProposalLeftItem) {
		if (!confirming) return selectProposal(item);
		if (isSameLeftRef(selectedProposals[2].ref, item.ref)) {
			selectedProposals = [];
			return;
		}
		confirmSynthesis();
	}

	function selectedOptions(filters: ChoreFilters, name: string): string[] {
		const filter = filters[name];
		return !filter || typeof filter === 'boolean' ? [] : filter.selected;
	}

	function metricOptions(filters: ChoreFilters): Metric[] {
		return selectedOptions(filters, '指标').flatMap((label) =>
			(Object.entries(LEFT_METRIC_LABELS) as unknown as [Metric, string][]).flatMap(
				([metric, text]) => (text === label ? [Number(metric) as Metric] : [])
			)
		);
	}

	function direction(filters: ChoreFilters, name: string): boolean {
		return filters[name] === true;
	}
</script>

<aside class="flex h-full w-[390px] flex-col items-start" aria-label="左侧案牍">
	<div class="z-10 shrink-0">
		<ChoreFilter
			left="案牍"
			right="合成"
			bind:leftFilters
			bind:rightFilters
			bind:isSwitch={synthesisMode}
		/>
	</div>

	<div class="left-list mt-12 flex min-h-0 w-full flex-1 flex-col gap-12 overflow-y-auto pb-[120px]">
		{#if synthesisMode}
			{#each synthesisItems as item (`${item.ref.collection}-${item.ref.index}`)}
				{@const selected = selectedProposals.some((current) => isSameLeftRef(current.ref, item.ref))}
				<button
					type="button"
					class="w-[230px] shrink-0 cursor-pointer border-0 bg-transparent p-0 text-left"
					aria-pressed={selected}
					disabled={confirming && !selected}
					onclick={() => (selected ? activateOption(item) : selectProposal(item))}
				>
					{#if selected}
						<MemorialProposalOption
							option={optionFor(item)}
							lag={item.proposal.lag_months}
							metrics={confirming
								? synthesisPreview.metrics
								: proposalToMemorialMetrics(item.proposal)}
						/>
					{:else}
						<MemorialProposalClosed
							title={item.proposal.source_group.display_name}
							lag={item.proposal.lag_months}
							metrics={proposalToMemorialMetrics(item.proposal)}
						/>
					{/if}
				</button>
			{/each}
		{:else}
			{#each archiveItems as item (`${item.ref.collection}-${item.ref.index}`)}
				{#if item.kind === 'policy'}
					<div
						class="w-[230px] shrink-0 cursor-pointer"
						onclick={() => onItemSelect?.(item)}
						onkeydown={(event) => event.key === 'Enter' && onItemSelect?.(item)}
						role="button"
						tabindex="0"
					>
						<Mark policy={item.policy} {baseline} />
					</div>
				{:else}
					<button
						type="button"
						class="w-[230px] shrink-0 cursor-pointer border-0 bg-transparent p-0 text-left"
						onclick={() => onItemSelect?.(item)}
					>
						{#if item.kind === 'constitution'}
							<MemorialConstitutionClosed title={item.constitution.title} />
						{:else if item.kind === 'bill'}
							<MemorialBillClosed
								title={item.bill.title}
								proposals={item.bill.proposals}
								policies={item.bill.policies}
							/>
						{:else}
							<MemorialProposalClosed
								title={item.proposal.source_group.display_name}
								lag={item.proposal.lag_months}
								metrics={proposalToMemorialMetrics(item.proposal)}
							/>
						{/if}
					</button>
				{/if}
			{/each}
		{/if}

		{#if (synthesisMode ? synthesisItems : archiveItems).length === 0}
			<p class="m-0 bg-ink-primary px-12 py-8 font-document text-20 text-surface-amber">
				暂无可用案牍
			</p>
		{/if}
	</div>
</aside>

<style>
	.left-list {
		scrollbar-width: none;
		overscroll-behavior: contain;
	}

	.left-list::-webkit-scrollbar {
		display: none;
	}
</style>
