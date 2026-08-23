<script lang="ts">
	import ChoreItem from '../chore/ChoreItem.svelte';

	export type StateItem = {
		text: string;
		value?: string | number;
		limit?: number;
	};

	type Props = {
		primary: StateItem;
		secondary: StateItem;
	};

	let { primary, secondary }: Props = $props();
</script>

<aside class="flex items-end gap-12" aria-label="游戏状态">
	<ChoreItem {...primary} />
	<ChoreItem {...secondary} />
</aside>
