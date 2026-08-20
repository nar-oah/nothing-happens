<script lang="ts">
	import type { Snippet } from 'svelte';
	import { FOLD_HEIGHT, FOLD_WIDTH } from './memorial';

	type Props = {
		children: Snippet;
	};

	let { children }: Props = $props();
</script>

<div class="flex flex-col items-center">
	<div
		class="h-$height w-$width overflow-hidden bg-ink-primary"
		style:--width={`${FOLD_WIDTH}px`}
		style:--height={`${FOLD_HEIGHT}px`}
	>
		{@render children()}
	</div>
	<div class="h-4 w-$width bg-shadow-deep" style:--width={`${FOLD_WIDTH - 10}px`}></div>
</div>
