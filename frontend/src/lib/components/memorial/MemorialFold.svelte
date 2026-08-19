<script lang="ts">
	import type { Snippet } from 'svelte';
	import { FOLD_HEIGHT, FOLD_WIDTH } from './memorial';

	type Props = {
		x: number;
		open: boolean;
		index: number;
		count: number;
		skew: number;
		children: Snippet;
	};

	let { x, open, index, count, skew, children }: Props = $props();
</script>

<div
	class="memorial-fold-position absolute left-0 top-0 h-[var(--height)] w-[var(--width)] will-change-transform"
	aria-hidden={!open && index !== 0}
	style:--width={`${FOLD_WIDTH}px`}
	style:--height={`${FOLD_HEIGHT}px`}
	style:transform={`translate3d(${open ? x : 0}px, ${open ? index * FOLD_HEIGHT : 0}px, 0)`}
	style:z-index={count - index}
	style:transition-delay={`${open ? (count - index - 1) * 24 : index * 32}ms`}
>
	<div
		class="memorial-fold-shape box-border h-full w-full origin-top-left overflow-hidden will-change-transform"
		class:bg-surface-amber-pressed={index % 2 === 0}
		class:bg-accent-amber-deep={index % 2 === 1}
		style:transform={`skewX(${open ? skew : 0}deg)`}
		style:transition-delay={`${open ? 0 : 620}ms`}
	>
		<div class="box-border h-full w-full px-[12px] py-[10px]">
			{@render children()}
		</div>
	</div>
</div>

<style>
	.memorial-fold-position {
		transition-property: transform;
		transition-duration: 520ms;
		transition-timing-function: cubic-bezier(0.22, 0.8, 0.2, 1);
	}

	.memorial-fold-shape {
		transition-property: transform;
		transition-duration: 260ms;
		transition-timing-function: cubic-bezier(0.22, 0.8, 0.2, 1);
	}
</style>
