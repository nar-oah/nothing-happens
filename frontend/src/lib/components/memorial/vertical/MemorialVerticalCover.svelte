<script lang="ts">
	import type { Snippet } from 'svelte';
	import { VERTICAL_FOLD_HEIGHT, VERTICAL_FOLD_WIDTH } from '../constants';

	type Props = {
		children: Snippet;
	};

	let { children }: Props = $props();
</script>

<div
	class="h-$height w-$width shrink-0 overflow-hidden bg-ink-primary"
	style:--width={`${VERTICAL_FOLD_WIDTH}px`}
	style:--height={`${VERTICAL_FOLD_HEIGHT}px`}
>
	{@render children()}
</div>
