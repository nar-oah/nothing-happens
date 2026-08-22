<script lang="ts">
	import ChoreSelect from './ChoreSelect.svelte';
	import ChoreSwitch from './ChoreSwitch.svelte';

	type ChoreFilterValue = string[] | boolean;
	type Props = {
		filters?: Record<string, ChoreFilterValue>;
		onFiltersChange?: (filters: Record<string, ChoreFilterValue>) => void;
	};

	let {
		filters = $bindable<Record<string, ChoreFilterValue>>({}),
		onFiltersChange
	}: Props = $props();

	let options = $state<Record<string, string[]>>({});
	let activeFilter = $state<string>();
	let quickFilter = $state<string>();
	let filterEntries = $derived(Object.entries(filters));

	$effect(() => {
		const arrayFilters = filterEntries.filter((entry): entry is [string, string[]] =>
			Array.isArray(entry[1])
		);

		for (const [name, values] of arrayFilters) options[name] ??= [...values];
		if (!quickFilter || !arrayFilters.some(([name]) => name === quickFilter)) {
			quickFilter = arrayFilters[0]?.[0];
		}
	});

	function setFilter(name: string, value: ChoreFilterValue) {
		filters = { ...filters, [name]: value };
		onFiltersChange?.(filters);
	}

	function setOption(name: string, option: string, selected: boolean) {
		const selectedOptions = filters[name] as string[];
		const next = selected
			? options[name].filter((value) => value === option || selectedOptions.includes(value))
			: selectedOptions.filter((value) => value !== option);
		setFilter(name, next);
	}

	function openFilter(name: string) {
		quickFilter = name;
		activeFilter = name;
	}

	function toggleView() {
		if (activeFilter) {
			quickFilter = activeFilter;
			activeFilter = undefined;
			return;
		}
		activeFilter = quickFilter;
	}
</script>

<div class="flex flex-col items-start overflow-hidden">
	{#if quickFilter}
		<div class="-mb-[5px] shrink-0">
			<ChoreSwitch
				left={quickFilter}
				right="筛选条件"
				isSwitch={!activeFilter}
				onSwitchChange={toggleView}
			/>
		</div>
	{/if}

	<div
		class:bg-ink-primary={!activeFilter}
		class:bg-shadow-deep={!!activeFilter}
		class="flex shrink-0 items-start gap-8 overflow-hidden whitespace-nowrap text-surface-amber"
	>
		{#if activeFilter}
			{#each options[activeFilter] as option (option)}
				<ChoreSelect
					text={option}
					isSelect={(filters[activeFilter] as string[]).includes(option)}
					onSelectChange={(selected) => setOption(activeFilter, option, selected)}
				/>
			{/each}
		{:else}
			{#each filterEntries as [name, value] (name)}
				{#if Array.isArray(value)}
					<button
						type="button"
						class="typo-filter-option cursor-pointer border-0 bg-transparent p-0 text-surface-amber"
						onclick={() => openFilter(name)}
					>
						{value.length}{name}
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
