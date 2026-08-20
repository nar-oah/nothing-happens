<script lang="ts">
	import ChoreSelect from './ChoreSelect.svelte';
	import ChoreSwitch from './ChoreSwitch.svelte';
	import {
		CHORE_ARCHIVE_OPTIONS,
		CHORE_METRIC_OPTIONS,
		createChoreArchiveState,
		createChoreMetricState,
		type ChoreArchiveKey,
		type ChoreArchiveState,
		type ChoreFilterMode,
		type ChoreMetricKey,
		type ChoreMetricState
	} from './chore';

	type Props = {
		filter?: ChoreFilterMode;
		archives?: ChoreArchiveState;
		metrics?: ChoreMetricState;
		timeAscending?: boolean;
		valueAscending?: boolean;
		onFilterChange?: (filter: ChoreFilterMode) => void;
		onArchivesChange?: (archives: ChoreArchiveState) => void;
		onMetricsChange?: (metrics: ChoreMetricState) => void;
		onTimeDirectionChange?: (ascending: boolean) => void;
		onValueDirectionChange?: (ascending: boolean) => void;
	};

	let {
		filter = $bindable<ChoreFilterMode>('default'),
		archives = $bindable<ChoreArchiveState>(createChoreArchiveState()),
		metrics = $bindable<ChoreMetricState>(createChoreMetricState()),
		timeAscending = $bindable(true),
		valueAscending = $bindable(false),
		onFilterChange,
		onArchivesChange,
		onMetricsChange,
		onTimeDirectionChange,
		onValueDirectionChange
	}: Props = $props();

	let archiveCount = $derived(Object.values(archives).filter(Boolean).length);
	let metricCount = $derived(Object.values(metrics).filter(Boolean).length);

	function setFilter(next: ChoreFilterMode) {
		if (filter === next) return;
		filter = next;
		onFilterChange?.(next);
	}

	function setArchive(key: ChoreArchiveKey, selected: boolean) {
		archives = { ...archives, [key]: selected };
		onArchivesChange?.(archives);
	}

	function setMetric(key: ChoreMetricKey, selected: boolean) {
		metrics = { ...metrics, [key]: selected };
		onMetricsChange?.(metrics);
	}

	function setTimeDirection(ascending: boolean) {
		timeAscending = ascending;
		onTimeDirectionChange?.(ascending);
	}

	function setValueDirection(ascending: boolean) {
		valueAscending = ascending;
		onValueDirectionChange?.(ascending);
	}
</script>

<div class="flex flex-col items-start overflow-hidden">
	<div class="-mb-[5px] shrink-0">
		<ChoreSwitch
			left={filter === 'metric' ? '指标' : '案牍'}
			right="筛选条件"
			isSwitch={filter === 'default'}
			onSwitchChange={() => setFilter(filter === 'default' ? 'archives' : 'default')}
		/>
	</div>

	<div
		class:bg-ink-primary={filter === 'default'}
		class:bg-shadow-deep={filter !== 'default'}
		class="flex shrink-0 items-start gap-8 overflow-hidden whitespace-nowrap text-surface-amber"
	>
		{#if filter === 'archives'}
			{#each CHORE_ARCHIVE_OPTIONS as option (option.key)}
				<ChoreSelect
					text={option.text}
					isSelect={archives[option.key]}
					onSelectChange={(selected) => setArchive(option.key, selected)}
				/>
			{/each}
		{:else if filter === 'metric'}
			{#each CHORE_METRIC_OPTIONS as option (option.key)}
				<ChoreSelect
					text={option.text}
					isSelect={metrics[option.key]}
					onSelectChange={(selected) => setMetric(option.key, selected)}
				/>
			{/each}
		{:else}
			<button
				type="button"
				class="cursor-pointer border-0 bg-transparent p-0 font-document text-24 font-light leading-auto text-surface-amber"
				onclick={() => setFilter('archives')}
			>
				{archiveCount}案牍
			</button>
			<button
				type="button"
				class="cursor-pointer border-0 bg-transparent p-0 font-document text-24 font-light leading-auto text-surface-amber"
				onclick={() => setFilter('metric')}
			>
				{metricCount}指标
			</button>
			<ChoreSelect
				text="时间"
				isDirection
				isSelect={timeAscending}
				onSelectChange={setTimeDirection}
			/>
			<ChoreSelect
				text="数值"
				isDirection
				isSelect={valueAscending}
				onSelectChange={setValueDirection}
			/>
		{/if}
	</div>
</div>
