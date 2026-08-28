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
		'raceItems' | 'interestGroupItems' | 'gameState' | 'term' | 'year' | 'month' | 'onNewspaperOpen'
	> & {
		title: string;
		constitution: MemorialConstitutionData;
		columns: ConstitutionColumnDto[];
		availableGoverningMonths: number;
		lifetimeGoverningMonths: number;
		onArticleSelectionChange?: (articleRef: number, selected: boolean) => void;
		onColumnUnlock?: (columnIndex: number) => void;
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
		columns,
		availableGoverningMonths,
		lifetimeGoverningMonths,
		onArticleSelectionChange,
		onColumnUnlock,
		onSubmit
	}: Props = $props();
	let confirmMode = $state(false);
	let lockedColumns = $derived(columns.filter((column) => !column.unlocked));

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
	<div class="progression" data-block-world-input>
		<div class="progression-summary">
			<span>可用执政月 {availableGoverningMonths}</span>
			<span>累计执政月 {lifetimeGoverningMonths}</span>
		</div>
		{#if lockedColumns.length > 0}
			<div class="unlock-list" aria-label="约法纵轴解锁">
				{#each lockedColumns as column (column.column_index)}
					<button
						type="button"
						disabled={!column.can_unlock}
						onclick={() => onColumnUnlock?.(column.column_index)}
					>
						{column.display_name}／{column.unlock_cost_months}月
					</button>
				{/each}
			</div>
		{/if}
	</div>
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

	.progression {
		position: absolute;
		top: 140px;
		left: 20px;
		z-index: 70;
		display: flex;
		max-width: 520px;
		flex-direction: column;
		gap: 8px;
		font-family: var(--font-document);
		color: var(--color-ink-primary);
	}

	.progression-summary,
	.unlock-list {
		display: flex;
		flex-wrap: wrap;
		gap: 8px 16px;
	}

	.unlock-list button {
		border: 1px solid currentColor;
		background: transparent;
		padding: 4px 8px;
		color: inherit;
		font: inherit;
		cursor: pointer;
	}

	.unlock-list button:disabled {
		opacity: 0.45;
		cursor: default;
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
