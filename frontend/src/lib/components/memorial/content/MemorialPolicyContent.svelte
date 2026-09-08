<script lang="ts">
	import NumberEditor from '../../chore/NumberEditor.svelte';
	import MarkSeal from '../../mark/MarkSeal.svelte';
	import MemorialHorizontalContent from './MemorialHorizontalContent.svelte';
	import type { MemorialPolicyContentData } from '../types';

	type Props = MemorialPolicyContentData & {
		lagMonths?: number;
		min?: number;
		max?: number;
		step?: number;
		disabled?: boolean;
		onChange?: (value: number) => void;
	};

	let {
		policyTitle,
		contents,
		lagMonths,
		min,
		max,
		step = 1,
		disabled = false,
		onChange
	}: Props = $props();
	let showLagEditor = $derived(lagMonths !== undefined && min !== undefined && max !== undefined);
</script>

<div
	class="box-border flex h-[345px] w-[123px] flex-col items-center gap-5 overflow-hidden py-12 text-ink-primary"
>
	<div class="flex w-full shrink-0 items-center justify-center gap-2">
		<div class="h-80 w-80 shrink-0 overflow-hidden rounded-3">
			<MarkSeal text={policyTitle} is_ghost={true} />
		</div>
		{#if showLagEditor && lagMonths !== undefined && min !== undefined && max !== undefined}
			<div class="pointer-events-auto relative z-10">
				<NumberEditor
					value={lagMonths}
					{min}
					{max}
					{step}
					disabled={disabled || !onChange}
					onChange={(value) => onChange?.(value)}
				/>
			</div>
		{/if}
	</div>
	<div class="flex w-[92px] flex-col gap-4">
		{#each contents as content, index (`${content.title ?? ''}-${index}`)}
			<MemorialHorizontalContent {...content} />
		{/each}
	</div>
</div>
