<script lang="ts">
	import type { MemorialConstitutionRowData } from '../types';

	type Props = MemorialConstitutionRowData & {
		empty?: boolean;
		onclick?: () => void;
		onSelectedChange?: (selected: boolean) => void;
	};

	let {
		text,
		number,
		selected = $bindable(),
		selectable,
		empty = false,
		onclick,
		onSelectedChange
	}: Props = $props();

	function handleClick() {
		if (empty) return;
		if (selectable) {
			selected = !selected;
			onSelectedChange?.(selected);
		}
		onclick?.();
	}
</script>

<button
	class="flex w-[99px] flex-col items-end overflow-hidden border-0 bg-transparent p-0 text-left"
	class:invisible={empty}
	type="button"
	aria-hidden={empty ? true : undefined}
	aria-pressed={!empty && selectable ? selected : undefined}
	aria-label={empty ? undefined : `查看${text}`}
	disabled={empty}
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
