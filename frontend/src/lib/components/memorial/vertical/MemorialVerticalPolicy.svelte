<script lang="ts">
	import MemorialPolicyContent from '../content/MemorialPolicyContent.svelte';
	import MemorialProposalContent from '../content/MemorialProposalContent.svelte';
	import MemorialMetric from '../shared/MemorialMetric.svelte';
	import MemorialTitleStrip from '../shared/MemorialTitleStrip.svelte';
	import MemorialVertical from './MemorialVertical.svelte';
	import MemorialVerticalCover from './MemorialVerticalCover.svelte';
	import {
		MetricText,
		type MemorialMetricData,
		type MemorialPolicyContentData,
		type MemorialProposalContentData
	} from '../types';

	type Props = {
		isTitle?: boolean;
		title: string;
		lag: number;
		metrics: MemorialMetricData[];
		proposals: MemorialProposalContentData[];
		policies: MemorialPolicyContentData[];
		onTitleChange?: (isTitle: boolean) => void;
		onProposalsChange?: (proposals: MemorialProposalContentData[]) => void;
		onPoliciesChange?: (policies: MemorialPolicyContentData[]) => void;
	};

	let {
		isTitle = $bindable(true),
		title,
		lag,
		metrics,
		proposals = $bindable<MemorialProposalContentData[]>(),
		policies = $bindable<MemorialPolicyContentData[]>(),
		onTitleChange,
		onProposalsChange,
		onPoliciesChange
	}: Props = $props();
	let coverMetrics: MemorialMetricData[] = $derived([
		...metrics,
		{ text: MetricText.Lag, value: lag, isReverse: true }
	]);

	function toggleTitle() {
		isTitle = !isTitle;
		onTitleChange?.(isTitle);
	}

	function removePage(index: number) {
		if (index < proposals.length) {
			proposals = proposals.filter((_, proposalIndex) => proposalIndex !== index);
			onProposalsChange?.(proposals);
			return;
		}

		const policyIndex = index - proposals.length;
		if (!policies[policyIndex]) return;
		policies = policies.filter((_, index) => index !== policyIndex);
		onPoliciesChange?.(policies);
	}
</script>

<div class="flex items-start">
	<MemorialVerticalCover>
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
	</MemorialVerticalCover>
	<MemorialVertical count={proposals.length + policies.length}>
		{#snippet page(index: number)}
			<button
				class="h-full w-full cursor-pointer border-0 bg-transparent p-0 text-left"
				type="button"
				aria-label={`删除第${index + 1}页`}
				onclick={() => removePage(index)}
			>
				{#if proposals[index]}
					<MemorialProposalContent {...proposals[index]} />
				{:else if policies[index - proposals.length]}
					<MemorialPolicyContent {...policies[index - proposals.length]} />
				{/if}
			</button>
		{/snippet}
	</MemorialVertical>
</div>
