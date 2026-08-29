<script lang="ts">
	import { untrack } from 'svelte';
	import { Metric } from '$lib/game';
	import ChoreFilter from '../chore/ChoreFilter.svelte';
	import type { ChoreFilters } from '../chore/chore';
	import Mark from '../mark/Mark.svelte';
	import MemorialBillClosed from '../memorial/closed/MemorialBillClosed.svelte';
	import MemorialConstitutionClosed from '../memorial/closed/MemorialConstitutionClosed.svelte';
	import MemorialProposalClosed from '../memorial/closed/MemorialProposalClosed.svelte';
	import MemorialProposalOption from '../memorial/closed/MemorialProposalOption.svelte';
	import MemorialHorizontal from '../memorial/horizontal/MemorialHorizontal.svelte';
	import {
		billToHorizontalContents,
		constitutionToHorizontalContents,
		proposalToHorizontalContents
	} from '../memorial/presentation';
	import {
		LEFT_KIND_LABELS,
		LEFT_METRIC_LABELS,
		createProposalSynthesisPreview,
		createSynthesisConfirmation,
		deriveSynthesisItems,
		filterArchiveItems,
		filterSelectionItems,
		getLeftSecondaryMode,
		getProposalGroupOptions,
		isSameLeftRef,
		moveSelectedProposalsFirst,
		proposalToMemorialMetrics,
		sortArchiveItems,
		toggleProposalSelection
	} from './left';
	import type {
		ArchiveFilterState,
		BillLeftItem,
		ConstitutionLeftItem,
		LeftItemKind,
		LeftMode,
		LeftProps,
		ProposalLeftItem,
		SynthesisFilterState
	} from './types';

	let {
		scene,
		items,
		baseline,
		activeMode = $bindable<LeftMode>('archive'),
		selection = { proposalRefs: [], policyDisplayNames: [] },
		onModeChange,
		onItemSelect,
		onSynthesisConfirm
	}: LeftProps = $props();
	let selectedProposals = $state<ProposalLeftItem[]>([]);
	let leftFilters = $state<ChoreFilters>({
		类型: {
			options: Object.values(LEFT_KIND_LABELS),
			selected: Object.values(LEFT_KIND_LABELS),
			multiple: true
		},
		指标: {
			options: Object.values(LEFT_METRIC_LABELS),
			selected: Object.values(LEFT_METRIC_LABELS),
			multiple: true
		},
		时间: false,
		数值: false
	});
	let secondaryFilters = $state<ChoreFilters>(
		untrack(() => scene) === 'office'
			? {
					利益集团: { options: [], selected: [], multiple: false },
					指标: {
						options: Object.values(LEFT_METRIC_LABELS),
						selected: ['投资'],
						multiple: true
					},
					时间: false,
					数值: false
				}
			: {
					类型: {
						options: ['法案', '提案', '政策'],
						selected: ['法案', '提案', '政策'],
						multiple: true
					},
					指标: {
						options: Object.values(LEFT_METRIC_LABELS),
						selected: Object.values(LEFT_METRIC_LABELS),
						multiple: true
					},
					时间: false,
					数值: false
				}
	);

	let secondaryMode = $derived(getLeftSecondaryMode(scene));
	let proposalItems: ProposalLeftItem[] = $derived(
		items.filter((item): item is ProposalLeftItem => item.kind === 'proposal')
	);
	let groupOptions = $derived(getProposalGroupOptions(proposalItems));
	let archiveState: ArchiveFilterState = $derived(makeArchiveState(leftFilters));
	let archiveItems = $derived(
		sortArchiveItems(filterArchiveItems(items, archiveState), archiveState)
	);
	let synthesisState: SynthesisFilterState = $derived({
		group: selectedOptions(secondaryFilters, '利益集团')[0],
		metrics: metricOptions(secondaryFilters),
		timeAscending: direction(secondaryFilters, '时间'),
		valueAscending: direction(secondaryFilters, '数值')
	});
	let availableSynthesisItems = $derived(deriveSynthesisItems(proposalItems, synthesisState));
	let synthesisItems = $derived(
		moveSelectedProposalsFirst(availableSynthesisItems, selectedProposals)
	);
	let selectionState: ArchiveFilterState = $derived(makeArchiveState(secondaryFilters));
	let selectionItems = $derived(
		sortArchiveItems(
			filterArchiveItems(filterSelectionItems(items, selection), selectionState),
			selectionState
		)
	);
	let confirming = $derived(selectedProposals.length === 3);
	let synthesisPreview = $derived(createProposalSynthesisPreview(selectedProposals));

	$effect(() => {
		if (secondaryMode || activeMode === 'archive') return;
		activeMode = 'archive';
	});

	$effect(() => {
		if (secondaryMode !== 'synthesis') return;
		const filter = secondaryFilters['利益集团'];
		if (typeof filter === 'boolean') return;
		const current = filter.selected[0];
		const selected =
			current && groupOptions.includes(current) ? [current] : groupOptions.slice(0, 1);
		if (
			filter.options.join('\u0000') !== groupOptions.join('\u0000') ||
			filter.selected.join('\u0000') !== selected.join('\u0000')
		) {
			secondaryFilters = {
				...secondaryFilters,
				利益集团: { ...filter, options: groupOptions, selected }
			};
		}
	});

	$effect(() => {
		const visible = selectedProposals.filter((selected) =>
			availableSynthesisItems.some((item) => isSameLeftRef(item.ref, selected.ref))
		);
		if (visible.length !== selectedProposals.length) selectedProposals = visible;
	});

	function setSecondary(next: boolean) {
		activeMode = next && secondaryMode ? secondaryMode : 'archive';
		onModeChange?.(activeMode);
	}

	function selectProposal(item: ProposalLeftItem) {
		if (
			confirming &&
			!selectedProposals.some((selected) => isSameLeftRef(selected.ref, item.ref))
		) {
			return;
		}
		selectedProposals = toggleProposalSelection(selectedProposals, item);
	}

	function confirmSynthesis(negativeBase: ProposalLeftItem) {
		if (selectedProposals.length !== 3) return;
		onSynthesisConfirm?.(createSynthesisConfirmation(selectedProposals, negativeBase));
		selectedProposals = [];
	}

	function optionFor(item: ProposalLeftItem): string {
		if (!confirming) return '選取';
		return isSameLeftRef(selectedProposals[2].ref, item.ref) ? '取消' : '確認';
	}

	function activateOption(item: ProposalLeftItem) {
		if (!confirming) return selectProposal(item);
		if (isSameLeftRef(selectedProposals[2].ref, item.ref)) {
			selectedProposals = [];
			return;
		}
		confirmSynthesis(item);
	}

	function makeArchiveState(filters: ChoreFilters): ArchiveFilterState {
		return {
			kinds: selectedOptions(filters, '类型').flatMap((label) =>
				(Object.entries(LEFT_KIND_LABELS) as [LeftItemKind, string][]).flatMap(([kind, text]) =>
					text === label ? [kind] : []
				)
			),
			metrics: metricOptions(filters),
			timeAscending: direction(filters, '时间'),
			valueAscending: direction(filters, '数值')
		};
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

	function activateSelection(item: (typeof selectionItems)[number]) {
		onItemSelect?.(item, 'selection');
	}
</script>

{#snippet closedMemorial(item: ConstitutionLeftItem | BillLeftItem | ProposalLeftItem)}
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
{/snippet}

<aside class="left-hover-area" aria-label="左侧案牍" data-block-world-input>
	<div class="left-content flex h-full w-[390px] flex-col items-start">
		{#if secondaryMode}
			<div class="filter-slot z-10 shrink-0">
				<ChoreFilter
					left="案牍"
					right={secondaryMode === 'synthesis' ? '合成' : '选择'}
					bind:leftFilters
					rightFilters={secondaryFilters}
					isSwitch={activeMode === secondaryMode}
					onRightFiltersChange={(filters) => (secondaryFilters = filters)}
					onSwitchChange={setSecondary}
				/>
			</div>
		{/if}

		<div
			class:mt-12={secondaryMode}
			class="left-list flex min-h-0 w-full flex-1 flex-col gap-12 overflow-y-auto pb-[120px]"
		>
			{#if activeMode === 'synthesis'}
				{#each synthesisItems as item (`${item.ref.collection}-${item.ref.index}`)}
					{@const selected = selectedProposals.some((current) =>
						isSameLeftRef(current.ref, item.ref)
					)}
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
			{:else if activeMode === 'selection'}
				{#each selectionItems as item (`${item.ref.collection}-${item.ref.index}`)}
					{#if item.kind === 'policy'}
						<div
							class="w-[230px] shrink-0 cursor-pointer"
							onclick={() => activateSelection(item)}
							onkeydown={(event) => event.key === 'Enter' && activateSelection(item)}
							role="button"
							tabindex="0"
						>
							<Mark policy={item.policy} {baseline} />
						</div>
					{:else if item.kind === 'bill' || item.kind === 'proposal'}
						<button
							type="button"
							class="w-[230px] shrink-0 cursor-pointer border-0 bg-transparent p-0 text-left"
							onclick={() => activateSelection(item)}
						>
							{@render closedMemorial(item)}
						</button>
					{/if}
				{/each}
			{:else}
				{#each archiveItems as item (`${item.ref.collection}-${item.ref.index}`)}
					{#if item.kind === 'policy'}
						<div
							class="w-[230px] shrink-0 cursor-pointer"
							onclick={() => onItemSelect?.(item, 'archive')}
							onkeydown={(event) => event.key === 'Enter' && onItemSelect?.(item, 'archive')}
							role="button"
							tabindex="0"
						>
							<Mark policy={item.policy} {baseline} />
						</div>
					{:else}
						<div class="shrink-0">
							<MemorialHorizontal
								contents={item.kind === 'constitution'
									? constitutionToHorizontalContents(item.constitution)
									: item.kind === 'bill'
										? billToHorizontalContents(item.bill)
										: proposalToHorizontalContents(item.proposal)}
								onOpenChange={() => onItemSelect?.(item, 'archive')}
							>
								{#snippet closed()}
									{@render closedMemorial(item)}
								{/snippet}
							</MemorialHorizontal>
						</div>
					{/if}
				{/each}
			{/if}
		</div>
	</div>
</aside>

<style>
	.left-hover-area {
		position: fixed;
		top: 190px;
		bottom: 20px;
		left: 0;
		z-index: 40;
		width: 390px;
	}

	.left-content {
		transform: translate3d(-115px, 0, 0);
		transition: transform 260ms ease-out;
	}

	.filter-slot {
		visibility: hidden;
		opacity: 0;
		transition: opacity 160ms ease-out;
	}

	.left-hover-area:hover .left-content,
	.left-hover-area:focus-within .left-content {
		transform: translate3d(0, 0, 0);
	}

	.left-hover-area:hover .filter-slot,
	.left-hover-area:focus-within .filter-slot {
		visibility: visible;
		opacity: 1;
	}

	.left-list {
		scrollbar-width: none;
		overscroll-behavior: contain;
	}

	.left-list::-webkit-scrollbar {
		display: none;
	}

	@media (prefers-reduced-motion: reduce) {
		.left-content,
		.filter-slot {
			transition-duration: 1ms;
		}
	}
</style>
