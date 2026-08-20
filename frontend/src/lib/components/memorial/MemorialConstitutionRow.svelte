<script lang="ts">
	import type { MemorialConstitutionRowData } from './memorial';

	type Props = MemorialConstitutionRowData;
	let { text, number, selected }: Props = $props();
</script>

<div class="flex w-[99px] flex-col items-end overflow-hidden">
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
		class:text-surface-amber={!selected}
		class:text-ink-primary={selected}
		class="flex whitespace-nowrap font-document text-16 font-light leading-16 [word-break:break-word]"
	>
		<span>{number}</span><span>%</span>
	</div>
</div>
