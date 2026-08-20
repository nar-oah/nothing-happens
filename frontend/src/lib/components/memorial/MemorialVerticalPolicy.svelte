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
		proposal: MemorialProposalContentData;
		policies: MemorialPolicyContentData[];
		onTitleChange?: (isTitle: boolean) => void;
	};

	let {
		isTitle = $bindable(true),
		title,
		lag,
		metrics,
		proposal,
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
				<div class="absolute left-15 top-15">
					<MemorialTitleStrip text={title} vertical />
				</div>
			{/if}
		</button>
	</MemorialVerticalCoverFrame>
	<MemorialVertical count={policies.length + 1}>
		{#snippet page(index: number)}
			{#if index === 0}
				<MemorialProposalContent {...proposal} />
			{:else if policies[index - 1]}
				<MemorialPolicyContent {...policies[index - 1]} />
			{/if}
		{/snippet}
	</MemorialVertical>
</div>
