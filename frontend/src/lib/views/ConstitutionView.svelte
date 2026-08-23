<script lang="ts">
	import { MemorialVerticalConstitution } from '$lib/components/memorial';
	import type { MemorialConstitutionData } from '$lib/components/memorial/types';
	import GameStateDisplay from '$lib/components/state/GameStateDisplay.svelte';
	import Top from '$lib/components/top/Top.svelte';
	import type { ViewFrameProps } from './types';

	type Props = Pick<
		ViewFrameProps,
		'raceItems' | 'interestGroupItems' | 'gameState'
	> & {
		title: string;
		constitution: MemorialConstitutionData;
		onArticleSelectionChange?: (articleRef: number, selected: boolean) => void;
	};

	let {
		raceItems,
		interestGroupItems,
		gameState,
		title,
		constitution,
		onArticleSelectionChange
	}: Props = $props();
</script>

<main class="game-view" aria-label="约法界面">
	<div class="top-slot">
		<Top {raceItems} {interestGroupItems} />
	</div>
	<div class="state-slot"><GameStateDisplay {...gameState} /></div>
	<div class="constitution" data-block-world-input>
		<MemorialVerticalConstitution
			{title}
			{constitution}
			{onArticleSelectionChange}
		/>
	</div>
</main>

<style>
	.game-view {
		position: relative;
		height: 100vh;
		overflow: hidden;
	}

	.top-slot {
		position: absolute;
		top: 0;
		right: 0;
	}

	.state-slot {
		position: absolute;
		top: 72px;
		right: 0;
	}

	.constitution {
		position: absolute;
		bottom: 20px;
		left: 0;
		z-index: 60;
		display: flex;
		width: 100%;
		justify-content: center;
	}
</style>
