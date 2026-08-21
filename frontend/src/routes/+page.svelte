<script lang="ts">
	import ChoreItem from '$lib/components/chore/ChoreItem.svelte';
	import ChoreSwitch from '$lib/components/chore/ChoreSwitch.svelte';
	import Dialog from '$lib/components/dialog/Dialog.svelte';
	import MemorialConstitutionClosed from '$lib/components/memorial/MemorialConstitutionClosed.svelte';
	import MemorialNewspaper from '$lib/components/memorial/MemorialNewspaper.svelte';
	import MemorialPolicyClosed from '$lib/components/memorial/MemorialPolicyClosed.svelte';
	import MemorialProposalClosed from '$lib/components/memorial/MemorialProposalClosed.svelte';
	import MemorialProposalOption from '$lib/components/memorial/MemorialProposalOption.svelte';
	import {
		MetricSymbol,
		MetricText,
		type MemorialMetricData
	} from '$lib/components/memorial/memorial';
	import Mark from '$lib/components/mark/Mark.svelte';

	const proposalMetrics: MemorialMetricData[] = [
		{
			text: MetricText.Price,
			symbol: MetricSymbol.Decrease,
			value: 5,
			isReverse: true
		},
		{ text: MetricText.Tax, symbol: MetricSymbol.Decrease, value: 8 },
		{ text: MetricText.Employment, symbol: MetricSymbol.Decrease, value: 5 }
	];

	const policyMetrics: MemorialMetricData[] = [
		{ text: MetricText.Trade, value: 2 },
		{ text: MetricText.Employment, value: 5 },
		{ text: MetricText.Wage, value: 3 },
		{ text: MetricText.Price, value: 4 },
		{ text: MetricText.Tax, value: 1 }
	];

	const groups = [
		{ text: '人类', value: '+20' },
		{ text: '比翼', value: '+20' },
		{ text: '偃偶', value: '+20' },
		{ text: '桃花妖', value: '+20' },
		{ text: '南柯', value: '+20' },
		{ text: '驻岁', value: '+99' }
	];
	const dialogue = '如果每个人都要求现在回答，\n那么“迟一点”本身就会成为一种罪。';

	let groupSwitch = $state(false);
	let markDirection = $state<'up' | 'down'>('up');
</script>

<svelte:head>
	<title>Nothing Happens</title>
</svelte:head>

<main class="relative min-h-screen overflow-hidden bg-surface-amber">
	<div
		class="absolute left-[-122px] top-[-122px] flex h-[335px] w-[335px] rotate-[-45deg] items-center justify-center"
	>
		<MemorialNewspaper term={1} year={1} month={12} />
	</div>

	<div class="absolute left-[-91px] top-[200px] flex flex-col items-start gap-20 py-[82px]">
		<MemorialConstitutionClosed title="蓬莱约法" />
		<MemorialPolicyClosed title="大而美法案" lag={6} metrics={policyMetrics} />
		<MemorialProposalClosed title="造身公所" lag={12} metrics={proposalMetrics} />
		<MemorialProposalOption option="確認" lag={5} metrics={proposalMetrics} />
		<Mark
			bind:direction={markDirection}
			policyName="以工代赈"
			requirement={{
				headline: '所需　用工＜商贸六成',
				detail: '今数　42＜48　本批触发'
			}}
			effect={{
				headline: '效用　用工补至商贸六成',
				detail: '本批　用工＋6'
			}}
		/>
	</div>

	<div class="absolute right-0 top-0 flex items-start gap-30">
		<div class="flex items-start gap-20">
			{#each groups as group (group.text)}
				<ChoreItem text={group.text} value={group.value} isRate={false} isRow />
			{/each}
		</div>
		<ChoreSwitch bind:isSwitch={groupSwitch} left="种族" right="利益集团" />
	</div>

	<div class="absolute right-0 top-[88px] flex flex-col items-end gap-20">
		<ChoreItem text="政治献金" value={20} isRate={false} />
		<ChoreItem text="崩溃度" value={20} limit={24} />
	</div>

	<div class="absolute bottom-[clamp(16px,3.87vh,38px)] left-1/2 -translate-x-1/2">
		<Dialog text={dialogue} />
	</div>
</main>
