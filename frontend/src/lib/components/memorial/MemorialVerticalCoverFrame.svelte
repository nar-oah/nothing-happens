<script lang="ts">
	import type { Snippet } from 'svelte';
	import { VERTICAL_FOLD_HEIGHT, VERTICAL_FOLD_WIDTH } from './memorial';

	type Props = {
		children: Snippet;
	};

	let { children }: Props = $props();
</script>

<div class="flex shrink-0 items-center">
	<div
		class="h-$height w-$width overflow-hidden bg-ink-primary"
		style:--width={`${VERTICAL_FOLD_WIDTH}px`}
		style:--height={`${VERTICAL_FOLD_HEIGHT}px`}
	>
		{@render children()}
	</div>
	<div class="h-[335px] w-[6px] bg-shadow-deep"></div>
</div>
