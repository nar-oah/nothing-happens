<script lang="ts">
	import type { MemorialConstitutionRowData } from '../types';

	type Props = MemorialConstitutionRowData & {
		onclick?: () => void;
		onSelectedChange?: (selected: boolean) => void;
	};

	let {
		text,
		number,
		selected = $bindable(),
		selectable,
		onclick,
		onSelectedChange
	}: Props = $props();

	function handleClick() {
		if (selectable) {
			selected = !selected;
			onSelectedChange?.(selected);
		}
		onclick?.();
	}
</script>

<button
	class="flex w-[99px] flex-col items-end overflow-hidden border-0 bg-transparent p-0 text-left"
	type="button"
	aria-pressed={selectable ? selected : undefined}
	aria-label={`查看${text}`}
	onclick={handleClick}
>
	<div
		class:bg-ink-primary={selected}
		class:text-surface-amber={selected}
		class:text-ink-primary={!selected}
		class="-mb-8 w-full"
	>
		<p
			class="m-0 whitespace-nowrap font-policy text-[22px] font-medium leading-20 [word-break:break-word]"
		>
			{text}
		</p>
	</div>
	<div
		class:bg-ink-primary={!selected}
		class:bg-surface-amber={selected}
		class:text-surface-amber={!selected}
		class:text-ink-primary={selected}
		class="flex whitespace-nowrap font-document text-16 font-light leading-16 [word-break:break-word] text-surface-amber"
	>
		<span>{number}</span><span>%</span>
	</div>
</button>
