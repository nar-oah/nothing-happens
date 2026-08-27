<script lang="ts">
	import ChoreSwitch from '$lib/components/chore/ChoreSwitch.svelte';
	import { MemorialVerticalConstitution } from '$lib/components/memorial';
	import type { MemorialConstitutionData } from '$lib/components/memorial/types';
	import NewspaperEntry from '$lib/components/newspaper/NewspaperEntry.svelte';
	import GameStateDisplay from '$lib/components/state/GameStateDisplay.svelte';
	import Top from '$lib/components/top/Top.svelte';
	import type { ViewFrameProps } from './types';

	type Props = Pick<
		ViewFrameProps,
		'raceItems' | 'interestGroupItems' | 'gameState' | 'term' | 'year' | 'month' | 'onNewspaperOpen'
	> & {
		title: string;
		constitution: MemorialConstitutionData;
		onArticleSelectionChange?: (articleRef: number, selected: boolean) => void;
		onSubmit?: () => void;
	};

	let {
		raceItems,
		interestGroupItems,
		gameState,
		term,
		year,
		month,
		onNewspaperOpen,
		title,
		constitution,
		onArticleSelectionChange,
		onSubmit
	}: Props = $props();
	let confirmMode = $state(false);

	function submitRevision(isConfirm: boolean) {
		if (!isConfirm) return;
		onSubmit?.();
		queueMicrotask(() => (confirmMode = false));
	}
</script>

<main class="game-view" aria-label="约法界面">
	<NewspaperEntry {term} {year} {month} onOpen={onNewspaperOpen} />
	<div class="top-slot">
		<Top {raceItems} {interestGroupItems} />
	</div>
	<div class="state-slot"><GameStateDisplay {...gameState} /></div>
	<div class="constitution">
		<div class="constitution-track">
			<div class="constitution-content">
				<div class="confirm-switch">
					<ChoreSwitch
						left="约法"
						right="确认"
						bind:isSwitch={confirmMode}
						onSwitchChange={submitRevision}
					/>
				</div>
				<MemorialVerticalConstitution {title} {constitution} {onArticleSelectionChange} />
			</div>
		</div>
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
		width: 100%;
		overflow-x: auto;
		scrollbar-width: none;
		overscroll-behavior-x: contain;
	}

	.constitution::-webkit-scrollbar {
		display: none;
	}

	.constitution-track {
		display: flex;
		width: max-content;
		min-width: 100%;
		justify-content: center;
	}

	.constitution-content {
		display: flex;
		width: max-content;
		flex-direction: column;
		align-items: flex-end;
	}

	.confirm-switch {
		margin-bottom: 8px;
	}
</style>
