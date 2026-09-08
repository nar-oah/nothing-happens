<script lang="ts">
	import { clampNumberEditorValue } from './chore';

	type Props = {
		value: number;
		min: number;
		max: number;
		step?: number;
		disabled?: boolean;
		onChange: (value: number) => void;
	};

	let { value, min, max, step = 1, disabled = false, onChange }: Props = $props();
	let current = $derived(clampNumberEditorValue(value, min, max));
	let normalizedStep = $derived(Math.abs(step) || 1);
	let incrementDisabled = $derived(disabled || current >= Math.max(min, max));
	let decrementDisabled = $derived(disabled || current <= Math.min(min, max));

	function normalizePrecision(next: number): number {
		return Number(next.toFixed(10));
	}

	function write(next: number) {
		if (disabled) return;
		const clamped = clampNumberEditorValue(normalizePrecision(next), min, max);
		if (clamped === current) return;
		onChange(clamped);
	}

	function formatNumber(next: number): string {
		return String(normalizePrecision(next));
	}
</script>

<div
	class="flex flex-col items-center justify-center font-document text-30 font-light leading-auto text-shadow-deep"
>
	<button
		type="button"
		class="cursor-pointer border-0 bg-transparent p-0 font-document text-30 font-light leading-auto text-shadow-deep disabled:cursor-default"
		disabled={incrementDisabled}
		onclick={() => write(current + normalizedStep)}
	>+</button>
	<span class="whitespace-nowrap text-shadow-deep">{formatNumber(current)}</span>
	<button
		type="button"
		class="cursor-pointer border-0 bg-transparent p-0 font-document text-30 font-light leading-auto text-shadow-deep disabled:cursor-default"
		disabled={decrementDisabled}
		onclick={() => write(current - normalizedStep)}
	>-</button>
</div>
