<script lang="ts">
	import Memorial from '$lib/components/memorial/Memorial.svelte';
	import { type MemorialMetricData } from '$lib/components/memorial/memorial';

	var metrics: MemorialMetricData[] = [
		{ text: '物價', symbol: '-', value: 5, isReverse: true },
		{ text: '税課', symbol: '-', value: 8 },
		{ text: '用工', symbol: '-', value: 5 }
	];
</script>

<svelte:head>
	<title>Memorial Demo</title>
</svelte:head>

<main class="box-border min-h-screen bg-surface-indigo-muted p-[80px]">
	<Memorial title="造身公所" lag={12} {metrics} />
</main>
