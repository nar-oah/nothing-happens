<script lang="ts">
	import ChoreItem from '../chore/ChoreItem.svelte';

	export type StateItem = {
		text: string;
		value?: string | number;
		limit?: number;
		isRow: boolean;
	};

	type Props = {
		primary: StateItem;
		secondary: StateItem;
	};

	let { primary, secondary }: Props = $props();
</script>

<aside class="flex flex-col items-end gap-[20px]" aria-label="游戏状态" data-block-world-input>
	<ChoreItem {...primary} />
	<ChoreItem {...secondary} />
</aside>
