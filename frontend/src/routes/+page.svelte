<script lang="ts">
	import Memorial from '$lib/components/memorial/Memorial.svelte';
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
</script>

<svelte:head>
	<title>Memorial Demo</title>
</svelte:head>

<main class="box-border min-h-screen bg-surface-indigo-muted p-[80px]">
	<Memorial count={4} title="造身公所" lag={12} {metrics} />
</main>
