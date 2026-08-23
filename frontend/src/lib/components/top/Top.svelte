<script lang="ts">
	import ChoreItem from '../chore/ChoreItem.svelte';
	import ContextDetail from '../detail/ContextDetail.svelte';
	import type { TopItemData } from './top';

	type Props = {
		items: TopItemData[];
		onItemClick?: (item: TopItemData) => void;
	};

	let { items, onItemClick }: Props = $props();
	let expandedKey = $state<string>();

	function open(item: TopItemData) {
		expandedKey = expandedKey === item.key ? undefined : item.key;
		item.onSelect?.(item.payload);
		onItemClick?.(item);
	}
</script>

<nav class="flex items-start justify-end gap-12" aria-label="顶部信息">
	{#each items as item (item.key)}
		{#if expandedKey === item.key}
			<ContextDetail
				title={item.item.text}
				value={item.item.value}
				limit={item.item.limit}
				{...item.detail}
				onClose={() => (expandedKey = undefined)}
				onAction={(isRight) => item.onAction?.(item.payload, isRight)}
			/>
		{:else}
			<button
				type="button"
				class="cursor-pointer border-0 bg-transparent p-0"
				aria-label={`展开${item.item.text}`}
				onclick={() => open(item)}
			>
				<ChoreItem {...item.item} />
			</button>
		{/if}
	{/each}
</nav>
