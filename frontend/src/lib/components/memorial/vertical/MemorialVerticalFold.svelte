<script lang="ts">
	import type { Snippet } from 'svelte';
	import { VERTICAL_FOLD_HEIGHT, VERTICAL_FOLD_WIDTH } from '../constants';

	type Props = {
		y: number;
		index: number;
		skew: number;
		children: Snippet;
	};

	let { y, index, skew, children }: Props = $props();
</script>

<div
	class="absolute top-0 h-$height w-$width"
	style:--width={`${VERTICAL_FOLD_WIDTH}px`}
	style:--height={`${VERTICAL_FOLD_HEIGHT}px`}
	style:left={`${index * VERTICAL_FOLD_WIDTH}px`}
	style:transform={`translate3d(0, ${y}px, 0)`}
>
	<div
		class:bg-surface-amber-pressed={index % 2 === 0}
		class:bg-accent-amber-deep={index % 2 === 1}
		class="box-border h-full w-full origin-top-left overflow-hidden"
		style:transform={`skewY(${skew}deg)`}
	>
		{@render children()}
	</div>
</div>
