<script lang="ts">
	import favicon from '$lib/assets/favicon.svg';
	import 'virtual:uno.css';

	let { children } = $props();
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
