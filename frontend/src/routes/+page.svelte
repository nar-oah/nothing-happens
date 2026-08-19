<script lang="ts">
	import Memorial from '$lib/components/memorial/Memorial.svelte';
	import Mark from '$lib/components/mark/Mark.svelte';
	import {
		MetricText,
		MetricSymbol,
		type MemorialMetricData
	} from '$lib/components/memorial/memorial';

	var metrics: MemorialMetricData[] = [
		{
			text: MetricText.Price,
			symbol: MetricSymbol.Decrease,
			value: 5,
			isReverse: true
		},
		{ text: MetricText.Tax, symbol: MetricSymbol.Decrease, value: 8 },
		{ text: MetricText.Employment, symbol: MetricSymbol.Decrease, value: 5 }
	];
	let direction = $state<'up' | 'down'>('up');
</script>

<svelte:head>
	<title>Memorial Demo</title>
</svelte:head>

<main class="flex flex-col gap-lg box-border min-h-screen bg-surface-indigo-muted p-[80px]">
	<Memorial count={4} title="造身公所" lag={12} {metrics} />
	<Mark
		bind:direction
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
</main>
