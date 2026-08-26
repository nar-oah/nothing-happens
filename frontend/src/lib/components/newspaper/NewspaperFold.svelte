<script lang="ts">
	import type { Snippet } from 'svelte';
	import { VERTICAL_FOLD_HEIGHT, VERTICAL_FOLD_WIDTH } from '../memorial/constants';

	type Props = {
		index: number;
		children: Snippet;
	};

	let { index, children }: Props = $props();
</script>

<div
	class="box-border h-$height w-$width shrink-0 overflow-hidden text-ink-primary"
	class:bg-surface-amber-pressed={index % 2 === 0}
	class:bg-accent-amber-deep={index % 2 === 1}
	style:--width={`${VERTICAL_FOLD_HEIGHT}px`}
	style:--height={`${VERTICAL_FOLD_WIDTH}px`}
>
	{@render children()}
</div>
