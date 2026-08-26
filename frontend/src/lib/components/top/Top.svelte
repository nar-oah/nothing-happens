<script lang="ts">
	import { onMount } from 'svelte';
	import ChoreItem from '../chore/ChoreItem.svelte';
	import ChoreSwitch from '../chore/ChoreSwitch.svelte';
	import ContextDetail from '../detail/ContextDetail.svelte';
	import type { TopItemData } from './top';

	const NEWSPAPER_SCROLL_RESERVE = 282;

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
	let scrollContainer: HTMLDivElement;
	let items = $derived(isInterestGroups ? interestGroupItems : raceItems);

	onMount(() => {
		scrollContainer.scrollLeft = NEWSPAPER_SCROLL_RESERVE;
	});

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

<nav class="flex w-screen items-start justify-end gap-12 overflow-hidden" aria-label="顶部信息">
	<div bind:this={scrollContainer} class="top-items min-w-0 flex-1 overflow-x-auto">
		<div class="ml-auto flex w-max items-start" data-block-world-input>
			<div class="w-[282px] shrink-0" aria-hidden="true"></div>

			<div class="flex items-start gap-12">
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
