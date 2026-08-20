<script lang="ts">
	import MemorialConstitutionRow from './MemorialConstitutionRow.svelte';
	import type { MemorialConstitutionRowData } from './memorial';

	const defaultRows: MemorialConstitutionRowData[] = [
		{ text: '朝贡', number: 0 },
		{ text: '汉化', number: 0, selected: true },
		{ text: '承认', number: 50, selected: true },
		{ text: '', number: '' },
		{ text: '互助', number: 0 },
		{ text: '有限监管', number: '', selected: true }
	];

	type Props = {
		title?: string;
		locked?: boolean;
		requirement?: string | number;
		rows?: MemorialConstitutionRowData[];
	};

	let { title = '偏制', locked = false, requirement = 5, rows = defaultRows }: Props = $props();
</script>

<div
	class:gap-10={!locked}
	class="box-border flex h-[345px] w-[123px] flex-col items-center overflow-hidden py-[6px] text-ink-primary"
>
	<p class="m-0 whitespace-nowrap font-policy text-30 font-medium leading-[38px]">{title}</p>
	{#if locked}
		<div
			class="flex w-full flex-col items-center justify-center bg-ink-primary font-document text-[60px] font-light leading-[48px] text-surface-amber"
			aria-label={`解锁要求 ${requirement}`}
		>
			{#each Array(6) as _}
				<span>{requirement}</span>
			{/each}
		</div>
	{:else}
		<div class="flex flex-col gap-[20px]">
			{#each rows as row}
				<MemorialConstitutionRow {...row} />
			{/each}
		</div>
	{/if}
</div>
