<script lang="ts">
	import favicon from '$lib/assets/favicon.svg';
	import { installUiSfx } from '$lib/audio/ui-sfx';
	import { onMount } from 'svelte';
	import 'virtual:uno.css';

	let { children } = $props();

	onMount(installUiSfx);
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
</svelte:head>

{@render children()}

<style>
	:global(html),
	:global(body) {
		margin: 0;
		min-width: 960px;
		min-height: 100%;
		background: transparent;
	}

	:global(button),
	:global(input) {
		font: inherit;
	}
</style>