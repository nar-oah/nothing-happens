<script lang="ts">
	import { t } from '$lib/i18n';
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

<aside
	class="flex flex-col items-end gap-[20px]"
	aria-label={$t('ui.state')}
	data-block-world-input
>
	<ChoreItem {...primary} />
	<ChoreItem {...secondary} />
</aside>
