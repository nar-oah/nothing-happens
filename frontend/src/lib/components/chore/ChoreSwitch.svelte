<script lang="ts">
	type Props = {
		left: string;
		right: string;
		isSwitch?: boolean;
		disabled?: boolean;
		onSwitchChange?: (isSwitch: boolean) => void;
	};

	let {
		left,
		right,
		isSwitch = $bindable(false),
		disabled = false,
		onSwitchChange
	}: Props = $props();

	function toggle() {
		isSwitch = !isSwitch;
		onSwitchChange?.(isSwitch);
	}
</script>

<button
	type="button"
	class="flex cursor-pointer flex-col items-start border-0 bg-transparent p-0 text-left disabled:cursor-default"
	aria-label={`切换至${isSwitch ? left : right}`}
	aria-pressed={isSwitch}
	{disabled}
	data-block-world-input
	onclick={toggle}
>
	{#if isSwitch}
		<span class="typo-filter-context-label -mb-[20px] bg-ink-primary text-surface-amber">
			{left}
		</span>
		<span class="pl-[30px]">
			<span class="typo-control-heading block bg-shadow-deep text-surface-amber">{right}</span>
		</span>
	{:else}
		<span class="typo-control-heading z-2 -mb-[20px] bg-shadow-deep text-surface-amber">
			{left}
		</span>
		<span class="z-1 pl-[50px]">
			<span class="typo-filter-context-label block bg-ink-primary text-surface-amber">
				{right}
			</span>
		</span>
	{/if}
</button>
