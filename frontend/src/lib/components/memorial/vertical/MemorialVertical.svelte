<script lang="ts">
	import type { Snippet } from 'svelte';
	import MemorialVerticalFold from './MemorialVerticalFold.svelte';
	import { VERTICAL_FOLD_HEIGHT, VERTICAL_FOLD_SKEW, VERTICAL_FOLD_WIDTH } from '../constants';

	type Props = {
		count: number;
		page: Snippet<[index: number]>;
	};

	let { count, page }: Props = $props();
	let skews = $derived(
		Array.from({ length: count }, (_, index) =>
			count === 1 ? 0 : index % 2 === 0 ? VERTICAL_FOLD_SKEW : -VERTICAL_FOLD_SKEW
		)
	);
	let positions = $derived(
		skews.map((_, index) =>
			skews
				.slice(0, index)
				.reduce((y, skew) => y + VERTICAL_FOLD_WIDTH * Math.tan((skew * Math.PI) / 180), 0)
		)
	);
	let minY = $derived(Math.min(0, ...positions));
	let maxY = $derived(Math.max(0, ...positions));
</script>

<div
	class="relative overflow-visible"
	style:width={`${count * VERTICAL_FOLD_WIDTH}px`}
	style:height={`${VERTICAL_FOLD_HEIGHT + maxY - minY}px`}
	aria-label="展开的竖版奏折"
	data-block-world-input
>
	{#each skews as skew, index (index)}
		<MemorialVerticalFold y={positions[index] - minY} {index} {skew}>
			{@render page(index)}
		</MemorialVerticalFold>
	{/each}
</div>
