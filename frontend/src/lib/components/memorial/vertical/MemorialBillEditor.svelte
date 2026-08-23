<script lang="ts">
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
		onSubmit?: (bill: Bill) => void;
		onCoverChange?: (isTitle: boolean) => void;
	};

	let {
		bill,
		preview,
		isTitle = $bindable(true),
		onTitleChange,
		onRemoveProposal,
		onRemovePolicy,
		onSubmit,
		onCoverChange
	}: Props = $props();
	let lag = $derived(getBillLagMonths(bill.proposals));
	let proposalPages = $derived(bill.proposals.map(proposalToMemorialContent));
	let policyPages = $derived(bill.policies.map(policyToMemorialContent));
	let coverMetrics: MemorialMetricData[] = $derived([
		...preview,
		{ text: MetricText.Lag, value: lag, isReverse: true }
	]);

	function toggleCover() {
		isTitle = !isTitle;
		onCoverChange?.(isTitle);
	}

	function removePage(index: number) {
		if (index < bill.proposals.length) {
			onRemoveProposal?.(bill.proposals[index], index);
			return;
		}
		const policyIndex = index - bill.proposals.length;
		if (bill.policies[policyIndex]) onRemovePolicy?.(bill.policies[policyIndex], policyIndex);
	}
</script>

<section class="flex flex-col items-start gap-8" aria-label="法案编辑器">
	<div class="flex items-start">
		<MemorialVerticalCover>
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
				{#if isTitle}
					<div class="absolute left-[15px] top-[15px]">
						<MemorialTitleStrip text={bill.title} vertical />
					</div>
				{/if}
			</button>
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

	<div class="flex max-w-full items-center gap-8 bg-shadow-deep p-8">
		<label class="font-policy text-20 text-surface-amber" for="bill-title">案名</label>
		<input
			id="bill-title"
			class="min-w-0 flex-1 border-0 bg-surface-amber px-8 py-5 font-document text-20 text-ink-primary outline-none"
			value={bill.title}
			oninput={(event) => onTitleChange?.(event.currentTarget.value)}
		/>
		<button
			type="button"
			class="cursor-pointer border-0 bg-accent-amber-deep px-12 py-5 font-policy text-20 text-shadow-deep"
			onclick={() => onSubmit?.(bill)}
		>
			提交法案
		</button>
	</div>
</section>
