<script lang="ts">
	import Left from '$lib/components/left/Left.svelte';
	import Newspaper from '$lib/components/newspaper/Newspaper.svelte';
	import GameStateDisplay from '$lib/components/state/GameStateDisplay.svelte';
	import Top from '$lib/components/top/Top.svelte';
	import {
		mockBaseline,
		mockInterestGroupTopItems,
		mockLeftItems,
		mockRaceTopItems,
		mockState
	} from '$lib/demo/mock';
</script>

<main class="game-view" aria-label="办公室界面">
	<Left
		scene="office"
		items={mockLeftItems}
		baseline={mockBaseline}
		onItemSelect={(item) => console.info('Office archive item', item)}
		onSynthesisConfirm={(result) => console.info('Office synthesis', result)}
	/>
	<Newspaper term={2} year={3} month={7} onOpen={() => console.info('Open newspaper')} />
	<div class="top-slot">
		<Top raceItems={mockRaceTopItems} interestGroupItems={mockInterestGroupTopItems} />
	</div>
	<div class="state-slot"><GameStateDisplay {...mockState} /></div>
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
