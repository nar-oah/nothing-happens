<script lang="ts">
	import { tick } from 'svelte';
	import { getBillLagMonths, type Bill, type PolicyDefinition, type Proposal } from '$lib/game';
	import MemorialPolicyContent from '../content/MemorialPolicyContent.svelte';
	import MemorialProposalContent from '../content/MemorialProposalContent.svelte';
	import { policyToMemorialContent, proposalToMemorialContent } from '../presentation';
	import MemorialMetric from '../shared/MemorialMetric.svelte';
	import MemorialTitleStrip from '../shared/MemorialTitleStrip.svelte';
	import { MetricText, type MemorialMetricData } from '../types';
	import MemorialVertical from './MemorialVertical.svelte';
	import MemorialVerticalCover from './MemorialVerticalCover.svelte';

	type Props = {
		bill: Bill;
		preview: MemorialMetricData[];
		isTitle?: boolean;
		onTitleChange?: (title: string) => void;
		onRemoveProposal?: (proposal: Proposal, index: number) => void;
		onRemovePolicy?: (policy: PolicyDefinition, index: number) => void;
		onCoverChange?: (isTitle: boolean) => void;
	};

	let {
		bill,
		preview,
		isTitle = $bindable(true),
		onTitleChange,
		onRemoveProposal,
		onRemovePolicy,
		onCoverChange
	}: Props = $props();
	let editingTitle = $state(false);
	let titleDraft = $state(bill.title);
	let titleInput: HTMLInputElement;
	let lag = $derived(getBillLagMonths(bill.proposals));
	let proposalPages = $derived(bill.proposals.map(proposalToMemorialContent));
	let policyPages = $derived(bill.policies.map(policyToMemorialContent));
	let coverMetrics: MemorialMetricData[] = $derived([
		...preview,
		{ text: MetricText.Lag, value: lag, isReverse: true }
	]);

	function toggleCover() {
		if (editingTitle) commitTitle();
		isTitle = !isTitle;
		onCoverChange?.(isTitle);
	}

	function beginTitleEdit(event: MouseEvent) {
		event.stopPropagation();
		titleDraft = bill.title;
		editingTitle = true;
		void tick().then(() => {
			titleInput?.focus();
			titleInput?.select();
		});
	}

	function commitTitle() {
		if (!editingTitle) return;
		editingTitle = false;
		onTitleChange?.(titleDraft);
	}

	function handleTitleKeydown(event: KeyboardEvent) {
		if (event.key !== 'Enter') return;
		event.preventDefault();
		event.currentTarget.blur();
	}

	function removePage(index: number) {
		if (index < bill.proposals.length) {
			onRemoveProposal?.(bill.proposals[index], index);
			return;
		}
		const policyIndex = index - bill.proposals.length;
		if (bill.policies[policyIndex]) onRemovePolicy?.(bill.policies[policyIndex], policyIndex);
	}

	$effect(() => {
		if (!editingTitle) titleDraft = bill.title;
	});
</script>

<section class="flex items-start" aria-label="法案编辑器">
	<div class="flex items-start">
		<MemorialVerticalCover>
			<div class="relative h-full w-full">
				<button
					class="relative h-full w-full cursor-pointer border-0 bg-transparent p-0 text-left"
					type="button"
					aria-pressed={!isTitle}
					aria-label={isTitle ? '显示法案预测指标' : '显示法案标题'}
					onclick={toggleCover}
				>
					<div class="absolute inset-0 flex flex-col gap-2 overflow-hidden">
						{#each coverMetrics as metric (`${metric.text}-${metric.value}`)}
							<div class="flex h-58 w-116 items-center justify-center">
								<div class="-rotate-90">
									<MemorialMetric {metric} isBottom isColumn showValue={!isTitle} />
								</div>
							</div>
						{/each}
					</div>
				</button>
				{#if isTitle}
					{#if editingTitle}
						<input
							bind:this={titleInput}
							class="absolute left-[15px] top-[15px] h-[315px] w-45 border-0 bg-accent-amber-deep p-0 font-document text-[60px] font-light leading-[48px] text-ink-secondary outline-none [text-orientation:upright] [writing-mode:vertical-rl]"
							aria-label="法案名称"
							value={titleDraft}
							oninput={(event) => (titleDraft = event.currentTarget.value)}
							onkeydown={handleTitleKeydown}
							onblur={commitTitle}
							onclick={(event) => event.stopPropagation()}
						/>
					{:else}
						<button
							type="button"
							class="absolute left-[15px] top-[15px] cursor-pointer border-0 bg-transparent p-0"
							aria-label="重命名法案"
							onclick={beginTitleEdit}
						>
							<MemorialTitleStrip text={bill.title} vertical />
						</button>
					{/if}
				{/if}
			</div>
		</MemorialVerticalCover>
		<MemorialVertical count={proposalPages.length + policyPages.length}>
			{#snippet page(index: number)}
				<button
					class="h-full w-full cursor-pointer border-0 bg-transparent p-0 text-left"
					type="button"
					aria-label={`删除法案第${index + 1}页`}
					onclick={() => removePage(index)}
				>
					{#if proposalPages[index]}
						<MemorialProposalContent {...proposalPages[index]} />
					{:else if policyPages[index - proposalPages.length]}
						<MemorialPolicyContent {...policyPages[index - proposalPages.length]} />
					{/if}
				</button>
			{/snippet}
		</MemorialVertical>
	</div>
</section>
