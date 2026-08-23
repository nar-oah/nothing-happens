<script lang="ts">
	import { MemorialVerticalConstitution } from '$lib/components/memorial';
	import GameStateDisplay from '$lib/components/state/GameStateDisplay.svelte';
	import Top from '$lib/components/top/Top.svelte';
	import {
		mockConstitution,
		mockConstitutionMemorial,
		mockInterestGroupTopItems,
		mockRaceTopItems,
		mockState
	} from '$lib/demo/mock';
</script>

<main class="game-view" aria-label="约法界面">
	<div class="top-slot">
		<Top raceItems={mockRaceTopItems} interestGroupItems={mockInterestGroupTopItems} />
	</div>
	<div class="state-slot"><GameStateDisplay {...mockState} /></div>
	<div class="constitution">
		<MemorialVerticalConstitution
			title={mockConstitution.title}
			constitution={mockConstitutionMemorial}
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
		left: 80px;
	}
</style>
