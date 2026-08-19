<script lang="ts">
	import MemorialFold from './MemorialFold.svelte';
	import { FOLD_HEIGHT, FOLD_WIDTH } from './memorial';

	type Props = {
		open?: boolean;
		skews?: number[];
		onOpenChange?: (open: boolean) => void;
	};

	let { open = $bindable(false), skews = [4.5, -3.5, 3, -2.5], onOpenChange }: Props = $props();

	function getFoldX(skews: number[]): number {
		return skews.reduce((x, skew) => x + FOLD_HEIGHT * Math.tan((skew * Math.PI) / 180), 0);
	}

	function setOpen(next: boolean) {
		if (open === next) return;
		open = next;
		onOpenChange?.(next);
	}
</script>

<button
	class="relative w-[var(--width)] h-[var(--height)] overflow-visible"
	style:--width={`${FOLD_WIDTH}px`}
	style:--height={`${FOLD_HEIGHT}px`}
	onclick={() => setOpen(!open)}
>
	{#each skews as skew, index}
		<MemorialFold x={getFoldX(skews.slice(0, index))} {open} {index} count={skews.length} {skew}>
			<div class="flex h-full flex-col justify-between">
				<div>
					<div class="typo-document-kicker opacity-70">提案／造身公所</div>
					<div class="typo-document-section-heading mt-[2px]">扩充行身机件统采案</div>
				</div>
				<div class="typo-document-metadata flex items-center justify-between">
					<span>消化／中等</span>
					<span>造身公所提供本案政治支持</span>
				</div>
			</div>
		</MemorialFold>
	{/each}
</button>
