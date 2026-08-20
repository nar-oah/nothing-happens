<script lang="ts">
	import MemorialConstitutionRow from './MemorialConstitutionRow.svelte';
	import type { MemorialConstitutionRowData } from './memorial';

	type Props =
		| {
				title: string;
				locked: true;
				requirement: string | number;
				rows?: never;
		  }
		| {
				title: string;
				locked: false;
				requirement?: never;
				rows: MemorialConstitutionRowData[];
		  };

	let props: Props = $props();
</script>

<div
	class:gap-10={!props.locked}
	class="box-border flex h-[345px] w-[123px] flex-col items-center overflow-hidden py-[6px] text-ink-primary"
>
	<p class="m-0 whitespace-nowrap font-policy text-30 font-medium leading-[38px]">{props.title}</p>
	{#if props.locked}
		<div
			class="flex w-full flex-col items-center justify-center bg-ink-primary font-document text-[60px] font-light leading-[48px] text-surface-amber"
			aria-label={`解锁要求 ${props.requirement}`}
		>
			{#each Array(6) as _}
				<span>{props.requirement}</span>
			{/each}
		</div>
	{:else}
		<div class="flex flex-col gap-[20px]">
			{#each props.rows as row}
				<MemorialConstitutionRow {...row} />
			{/each}
		</div>
	{/if}
</div>
