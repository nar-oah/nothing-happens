<script lang="ts">
	import type { Snippet } from 'svelte';
	import { HORIZONTAL_FOLD_HEIGHT, HORIZONTAL_FOLD_WIDTH } from '../constants';

	type Props = {
		children: Snippet;
	};

	let { children }: Props = $props();
</script>

<div class="flex flex-col items-center">
	<div
		class="h-$height w-$width overflow-hidden bg-ink-primary"
		style:--width={`${HORIZONTAL_FOLD_WIDTH}px`}
		style:--height={`${HORIZONTAL_FOLD_HEIGHT}px`}
	>
		{@render children()}
	</div>
	<div class="h-4 w-$width bg-shadow-deep" style:--width={`${HORIZONTAL_FOLD_WIDTH - 10}px`}></div>
</div>
