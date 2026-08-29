<script lang="ts">
	import ChoreSwitch from '$lib/components/chore/ChoreSwitch.svelte';
	import { MemorialVerticalConstitution } from '$lib/components/memorial';
	import type { MemorialConstitutionData } from '$lib/components/memorial/types';
	import NewspaperEntry from '$lib/components/newspaper/NewspaperEntry.svelte';
	import GameStateDisplay from '$lib/components/state/GameStateDisplay.svelte';
	import Top from '$lib/components/top/Top.svelte';
	import type { ConstitutionColumnDto } from '$lib/game/state/types';
	import type { ViewFrameProps } from './types';

	type Props = Pick<
		ViewFrameProps,
		'raceItems' | 'interestGroupItems' | 'term' | 'year' | 'month' | 'onNewspaperOpen'
	> & {
		title: string;
		constitution: MemorialConstitutionData;
		columns: ConstitutionColumnDto[];
		governingMonths: number;
		onArticleSelectionChange?: (articleRef: number, selected: boolean) => void;
		onColumnUnlock?: (columnIndex: number) => void;
		onSubmit?: () => void;
	};

	let {
		raceItems,
		interestGroupItems,
		term,
		year,
		month,
		onNewspaperOpen,
		title,
		constitution,
		columns,
		governingMonths,
		onArticleSelectionChange,
		onColumnUnlock,
		onSubmit
	}: Props = $props();
	let confirmMode = $state(false);
	let gameState = $derived({
		primary: { text: '执政年数', value: Math.floor(governingMonths / 12), isRow: false },
		secondary: { text: '执政月数', value: governingMonths % 12, limit: 12, isRow: false }
	});
	let unlockableSections = $derived(
		columns
			.filter((column) => !column.unlocked && column.can_unlock)
			.map((column) => column.display_name)
	);

	function submitRevision(isConfirm: boolean) {
		if (!isConfirm) return;
		onSubmit?.();
		queueMicrotask(() => (confirmMode = false));
	}

	function unlockSection(sectionTitle: string) {
		const column = columns.find((candidate) => candidate.display_name === sectionTitle);
		if (!column || column.unlocked || !column.can_unlock) return;
		onColumnUnlock?.(column.column_index);
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
				<MemorialVerticalConstitution
					{title}
					{constitution}
					{unlockableSections}
					{onArticleSelectionChange}
					onSectionUnlock={unlockSection}
				/>
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
