<script lang="ts">
	import { onMount } from 'svelte';
	import DemoGame from '$lib/demo/DemoGame.svelte';
	import { hasCefBridge } from '$lib/bridge/client';
	import LiveGame from '$lib/game/state/LiveGame.svelte';

	type RuntimeMode = 'detecting' | 'demo' | 'live';

	let runtimeMode = $state<RuntimeMode>('detecting');
	onMount(() => {
		runtimeMode = hasCefBridge() ? 'live' : 'demo';
	});
</script>

{#if runtimeMode === 'live'}
	<LiveGame />
{:else if runtimeMode === 'demo'}
	<DemoGame />
{/if}
