<script lang="ts">
	import MemorialMetric from './MemorialMetric.svelte';
	import MemorialPolicyContent from './MemorialPolicyContent.svelte';
	import MemorialProposalContent from './MemorialProposalContent.svelte';
	import MemorialTitleStrip from './MemorialTitleStrip.svelte';
	import MemorialVertical from './MemorialVertical.svelte';
	import MemorialVerticalCoverFrame from './MemorialVerticalCoverFrame.svelte';
	import {
		MetricText,
		type MemorialMetricData,
		type MemorialPolicyContentData,
		type MemorialProposalContentData
	} from './memorial';

	type Props = {
		isTitle?: boolean;
		title: string;
		lag: number;
		metrics: MemorialMetricData[];
		proposals: MemorialProposalContentData[];
		policies: MemorialPolicyContentData[];
		onTitleChange?: (isTitle: boolean) => void;
	};

	let {
		isTitle = $bindable(true),
		title,
		lag,
		metrics,
		proposals,
		policies,
		onTitleChange
	}: Props = $props();
	let coverMetrics: MemorialMetricData[] = $derived([
		...metrics,
		{ text: MetricText.Lag, value: lag, isReverse: true }
	]);

	function toggleTitle() {
		isTitle = !isTitle;
		onTitleChange?.(isTitle);
	}
</script>

<div class="flex items-start">
	<MemorialVerticalCoverFrame>
		<button
			class="relative h-full w-full border-0 bg-transparent p-0 text-left"
			type="button"
			aria-pressed={!isTitle}
			aria-label={isTitle ? '显示法案数值' : '显示法案标题'}
			onclick={toggleTitle}
		>
			<div class="absolute inset-0 flex flex-col gap-2">
				{#each coverMetrics as metric (metric)}
					<div class="flex h-58 w-116 items-center justify-center">
						<div class="-rotate-90">
							<MemorialMetric {metric} isBottom isColumn showValue={!isTitle} />
						</div>
					</div>
				{/each}
			</div>
			{#if isTitle}
				<div class="absolute left-[15px] top-[15px]">
					<MemorialTitleStrip text={title} vertical />
				</div>
			{/if}
		</button>
	</MemorialVerticalCoverFrame>
	<MemorialVertical count={proposals.length + policies.length}>
		{#snippet page(index: number)}
			{#if proposals[index]}
				<MemorialProposalContent {...proposals[index]} />
			{:else if policies[index - proposals.length]}
				<MemorialPolicyContent {...policies[index - proposals.length]} />
			{/if}
		{/snippet}
	</MemorialVertical>
</div>
