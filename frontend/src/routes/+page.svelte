<script lang="ts">
	import { onMount } from 'svelte';
	import DemoGame from '$lib/demo/DemoGame.svelte';
	import { isCefBridgeAvailable } from '$lib/bridge/client';
	import LiveGame from '$lib/game/state/LiveGame.svelte';

	let live = $state(false);
	onMount(() => (live = isCefBridgeAvailable()));
</script>

{#if live}
	<LiveGame />
{:else}
	<DemoGame />
{/if}
