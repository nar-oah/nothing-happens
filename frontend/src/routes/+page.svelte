<script lang="ts">
	import { resolve } from '$app/paths';
	import ConstitutionView from '$lib/views/ConstitutionView.svelte';
	import DialogueView from '$lib/views/DialogueView.svelte';
	import OfficeView from '$lib/views/OfficeView.svelte';
	import ParliamentView from '$lib/views/ParliamentView.svelte';

	type ViewName = 'Office' | 'Dialogue' | 'Parliament' | 'Constitution';
	const views: ViewName[] = ['Office', 'Dialogue', 'Parliament', 'Constitution'];
	let activeView = $state<ViewName>('Office');
</script>

<svelte:head>
	<title>Nothing Happens · Frontend UI Demo</title>
</svelte:head>

<div class="demo-stage">
	{#if activeView === 'Office'}
		<OfficeView />
	{:else if activeView === 'Dialogue'}
		<DialogueView />
	{:else if activeView === 'Parliament'}
		<ParliamentView />
	{:else}
		<ConstitutionView />
	{/if}

	<nav class="view-selector" aria-label="开发界面切换">
		{#each views as view (view)}
			<button type="button" class:active={activeView === view} onclick={() => (activeView = view)}>
				{view}
			</button>
		{/each}
		<a href={resolve('/components')}>Components</a>
	</nav>
</div>

<style>
	.demo-stage {
		min-height: 100vh;
	}

	.view-selector {
		position: fixed;
		z-index: 100;
		left: 50%;
		bottom: 8px;
		display: flex;
		gap: 2px;
		transform: translateX(-50%);
	}

	.view-selector button,
	.view-selector a {
		cursor: pointer;
		border: 0;
		background: #344654;
		padding: 6px 10px;
		color: #efb836;
		font: 300 14px 'RealTypeWriter';
		text-decoration: none;
	}

	.view-selector button.active {
		background: #efb836;
		color: #1e2e3b;
	}
</style>
