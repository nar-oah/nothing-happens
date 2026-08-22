<script lang="ts">
	import ChoreSelect from './ChoreSelect.svelte';
	import ChoreSwitch from './ChoreSwitch.svelte';

	type ChoreFilterOptions = {
		options: string[];
		selected: string[];
		multiple: boolean;
	};
	type ChoreFilterValue = ChoreFilterOptions | boolean;
	type ChoreFilters = Record<string, ChoreFilterValue>;
	type Props = {
		left: string;
		right: string;
		leftFilters: ChoreFilters;
		rightFilters: ChoreFilters;
		isSwitch?: boolean;
		onLeftFiltersChange?: (filters: ChoreFilters) => void;
		onRightFiltersChange?: (filters: ChoreFilters) => void;
		onSwitchChange?: (isSwitch: boolean) => void;
	};

	let {
		left,
		right,
		leftFilters = $bindable<ChoreFilters>(),
		rightFilters = $bindable<ChoreFilters>(),
		isSwitch = $bindable(false),
		onLeftFiltersChange,
		onRightFiltersChange,
		onSwitchChange
	}: Props = $props();

	let filters = $derived(isSwitch ? rightFilters : leftFilters);
	let filterEntries = $derived(Object.entries(filters));
	let activeFilter = $state<string>();

	function setFilter(name: string, value: ChoreFilterValue) {
		const next = { ...filters, [name]: value };
		if (isSwitch) {
			rightFilters = next;
			onRightFiltersChange?.(next);
			return;
		}
		leftFilters = next;
		onLeftFiltersChange?.(next);
	}

	function setOption(name: string, option: string, selected: boolean) {
		const filter = filters[name];
		if (typeof filter === 'boolean') return;
		const nextSelected = filter.multiple
			? selected
				? filter.options.filter((value) => value === option || filter.selected.includes(value))
				: filter.selected.filter((value) => value !== option)
			: [option];
		setFilter(name, { ...filter, selected: nextSelected });
	}

	function openFilter(name: string) {
		activeFilter = name;
	}

	function setSwitch(next: boolean) {
		isSwitch = next;
		activeFilter = undefined;
		onSwitchChange?.(next);
	}
</script>

<div class="flex flex-col items-start overflow-hidden">
	<div>
		<ChoreSwitch {left} {right} {isSwitch} onSwitchChange={setSwitch} />
	</div>

	<div
		class:bg-ink-primary={!activeFilter}
		class:bg-shadow-deep={!!activeFilter}
		class="flex shrink-0 items-start gap-8 overflow-hidden whitespace-nowrap text-surface-amber"
	>
		{#if activeFilter}
			{@const filter = filters[activeFilter]}
			{#if filter && typeof filter !== 'boolean'}
				{#each filter.options as option (option)}
					<ChoreSelect
						text={option}
						isSelect={filter.multiple
							? filter.selected.includes(option)
							: filter.selected[0] === option}
						onSelectChange={(selected) => setOption(activeFilter!, option, selected)}
					/>
				{/each}
			{/if}
		{:else}
			{#each filterEntries as [name, value] (name)}
				{#if typeof value !== 'boolean'}
					<button
						type="button"
						class="typo-filter-option cursor-pointer border-0 bg-transparent p-0 text-surface-amber"
						onclick={() => openFilter(name)}
					>
						{value.multiple ? `${value.selected.length}${name}` : (value.selected[0] ?? name)}
					</button>
				{:else}
					<ChoreSelect
						text={name}
						isDirection
						isSelect={value}
						onSelectChange={(selected) => setFilter(name, selected)}
					/>
				{/if}
			{/each}
		{/if}
	</div>
</div>
