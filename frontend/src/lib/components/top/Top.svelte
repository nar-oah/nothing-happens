<script lang="ts">
	import ChoreItem from '../chore/ChoreItem.svelte';
	import ChoreSwitch from '../chore/ChoreSwitch.svelte';
	import ContextDetail from '../detail/ContextDetail.svelte';
	import type { TopItemData } from './top';

	type Props = {
		raceItems: TopItemData[];
		interestGroupItems: TopItemData[];
		isInterestGroups?: boolean;
		onModeChange?: (isInterestGroups: boolean) => void;
		onItemClick?: (item: TopItemData) => void;
	};

	let {
		raceItems,
		interestGroupItems,
		isInterestGroups = $bindable(false),
		onModeChange,
		onItemClick
	}: Props = $props();
	let expandedKey = $state<string>();
	let items = $derived(isInterestGroups ? interestGroupItems : raceItems);

	function open(item: TopItemData) {
		expandedKey = item.key;
		item.onSelect?.(item.payload);
		onItemClick?.(item);
	}

	function setMode(next: boolean) {
		isInterestGroups = next;
		expandedKey = undefined;
		onModeChange?.(next);
	}
</script>

<nav
	class="flex w-screen items-start justify-end gap-12 overflow-hidden"
	aria-label="顶部信息"
>
	<div class="top-items min-w-0 flex-1 overflow-x-auto">
		<div class="ml-auto flex w-max items-start justify-end gap-12" data-block-world-input>
			{#each items as item (item.key)}
				{#if expandedKey === item.key}
					<div class="shrink-0">
						<ContextDetail
							title={item.item.text}
							{...item.detail}
							onClose={() => (expandedKey = undefined)}
						/>
					</div>
				{:else}
					<button
						type="button"
						class="shrink-0 cursor-pointer border-0 bg-transparent p-0"
						aria-label={`展开${item.item.text}`}
						onclick={() => open(item)}
					>
						<ChoreItem {...item.item} isRow />
					</button>
				{/if}
			{/each}
		</div>
	</div>
	<div class="shrink-0">
		<ChoreSwitch
			left="种族"
			right="利益集团"
			bind:isSwitch={isInterestGroups}
			onSwitchChange={setMode}
		/>
	</div>
</nav>

<style>
	.top-items {
		scrollbar-width: none;
		overscroll-behavior: contain;
	}

	.top-items::-webkit-scrollbar {
		display: none;
	}
</style>
