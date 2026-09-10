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
	let editing = $state(false);
	let draft = $state('');
	let inputValue = $derived(editing ? draft : formatNumber(current));

	function normalizePrecision(next: number): number {
		return Number(next.toFixed(10));
	}

	function formatNumber(next: number): string {
		return String(normalizePrecision(next));
	}

	function parseDraft(): number | undefined {
		if (!draft.trim()) return undefined;
		const parsed = Number(draft);
		return Number.isFinite(parsed) ? parsed : undefined;
	}

	function write(next: number) {
		if (disabled) return;
		const clamped = clampNumberEditorValue(normalizePrecision(next), min, max);
		draft = formatNumber(clamped);
		if (clamped === current) return;
		onChange(clamped);
	}

	function beginEditing() {
		if (disabled) return;
		draft = formatNumber(current);
		editing = true;
	}

	function commitDraft() {
		if (!editing) return;
		const parsed = parseDraft();
		editing = false;
		if (parsed === undefined) {
			draft = formatNumber(current);
			return;
		}
		write(parsed);
	}

	function adjust(direction: 1 | -1) {
		const base = editing ? (parseDraft() ?? current) : current;
		write(base + direction * normalizedStep);
	}

	function handleKeydown(event: KeyboardEvent) {
		if (event.key === 'Enter') {
			commitDraft();
			(event.currentTarget as HTMLInputElement).blur();
		} else if (event.key === 'Escape') {
			draft = formatNumber(current);
			editing = false;
			(event.currentTarget as HTMLInputElement).blur();
		}
	}
</script>

<div
	class="flex h-[55px] w-[45px] flex-col items-center justify-center font-document text-30 font-light leading-auto text-shadow-deep"
>
	<button
		type="button"
		class="m-0 flex w-[45px] cursor-pointer items-center justify-center border-0 bg-transparent p-0 font-document text-30 font-light leading-auto text-shadow-deep disabled:cursor-default"
		disabled={incrementDisabled}
		onpointerdown={(event) => event.preventDefault()}
		onclick={() => adjust(1)}
	>+</button>
	<input
		type="number"
		value={inputValue}
		{min}
		{max}
		step={normalizedStep}
		disabled={disabled}
		class="m-0 w-[45px] border-0 bg-transparent p-0 text-center font-document text-30 font-light leading-auto text-shadow-deep outline-none [letter-spacing:-16px] disabled:cursor-default"
		onfocus={beginEditing}
		oninput={(event) => (draft = event.currentTarget.value)}
		onblur={commitDraft}
		onkeydown={handleKeydown}
	/>
	<button
		type="button"
		class="m-0 flex w-[45px] cursor-pointer items-center justify-center border-0 bg-transparent p-0 font-document text-30 font-light leading-auto text-shadow-deep disabled:cursor-default"
		disabled={decrementDisabled}
		onpointerdown={(event) => event.preventDefault()}
		onclick={() => adjust(-1)}
	>-</button>
</div>

<style>
	input[type='number'] {
		-moz-appearance: textfield;
	}

	input[type='number']::-webkit-inner-spin-button,
	input[type='number']::-webkit-outer-spin-button {
		-webkit-appearance: none;
		margin: 0;
	}
</style>
