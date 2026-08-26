<script lang="ts">
	import Left from '$lib/components/left/Left.svelte';
	import NewspaperEntry from '$lib/components/newspaper/NewspaperEntry.svelte';
	import GameStateDisplay from '$lib/components/state/GameStateDisplay.svelte';
	import Top from '$lib/components/top/Top.svelte';
	import type { SynthesisConfirmation } from '$lib/components/left/types';
	import type { ViewFrameProps } from './types';

	type Props = ViewFrameProps & {
		onSynthesisConfirm?: (confirmation: SynthesisConfirmation) => void;
	};

	let {
		items,
		baseline,
		raceItems,
		interestGroupItems,
		gameState,
		term,
		year,
		month,
		onNewspaperOpen,
		onSynthesisConfirm
	}: Props = $props();
</script>

<main class="game-view" aria-label="办公室界面">
	<Left scene="office" {items} {baseline} {onSynthesisConfirm} />
	<NewspaperEntry {term} {year} {month} onOpen={onNewspaperOpen} />
	<div class="top-slot">
		<Top {raceItems} {interestGroupItems} />
	</div>
	<div class="state-slot"><GameStateDisplay {...gameState} /></div>
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
</style>
