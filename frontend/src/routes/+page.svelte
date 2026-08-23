<script lang="ts">
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
		<a href="/components">Components</a>
	</nav>
</div>

<style>
	.demo-stage {
		min-height: 100vh;
		background-color: #537087;
		background-image:
			linear-gradient(45deg, rgb(52 70 84 / 0.18) 25%, transparent 25%),
			linear-gradient(-45deg, rgb(52 70 84 / 0.18) 25%, transparent 25%),
			linear-gradient(45deg, transparent 75%, rgb(52 70 84 / 0.18) 75%),
			linear-gradient(-45deg, transparent 75%, rgb(52 70 84 / 0.18) 75%);
		background-position:
			0 0,
			0 8px,
			8px -8px,
			-8px 0;
		background-size: 16px 16px;
	}

	.view-selector {
		position: fixed;
		z-index: 100;
		left: 50%;
		bottom: 8px;
		display: flex;
		gap: 2px;
		transform: translateX(-50%);
		box-shadow: 0 4px 0 rgb(30 46 59 / 0.3);
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
