<script lang="ts">
	import { onMount } from 'svelte';
	import type { Component } from 'svelte';
	import { hasCefBridge } from '$lib/bridge/client';

	let RuntimeGame = $state<Component>();

	onMount(() => {
		void loadRuntime();
	});

	async function loadRuntime(): Promise<void> {
		RuntimeGame = hasCefBridge()
			? (await import('$lib/game/state/LiveGame.svelte')).default
			: (await import('$lib/demo/DemoGame.svelte')).default;
	}
</script>

{#if RuntimeGame}
	<RuntimeGame />
{/if}
