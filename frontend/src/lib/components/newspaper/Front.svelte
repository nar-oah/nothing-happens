<script lang="ts">
	import {
		formatNewspaperNumber,
		getNewspaperEventStateLabel,
		getNewspaperMetricLabel,
		getNewspaperRaceLabel,
		type NewspaperEventData,
		type NewspaperFrontData
	} from './types';

	type Props = NewspaperEventData | NewspaperFrontData;

	let props: Props = $props();
</script>

{#if 'title' in props}
	<div
		class="flex h-full w-full flex-col items-start gap-2 overflow-hidden px-8 py-[6px] text-ink-primary"
	>
		<p class="typo-newspaper-headline shrink-0">{props.title}</p>
		<p class="typo-newspaper-body min-w-full w-min whitespace-pre-line">{props.content}</p>
	</div>
{:else}
	<div class="flex h-full w-full flex-col gap-[3px] overflow-hidden px-8 py-5">
		<div class="flex w-full shrink-0 items-start overflow-hidden bg-surface-indigo px-5 py-2">
			<p class="typo-newspaper-caption min-w-0 flex-1 text-surface-amber">
				頭版 / FRONT PAGE · 已核實事件
			</p>
		</div>
		<div class="flex min-h-0 w-full flex-1 items-start gap-8 overflow-hidden text-ink-primary">
			<div class="flex w-[215px] shrink-0 flex-col items-start gap-2 overflow-hidden">
				<div class="flex shrink-0 items-start gap-8 whitespace-nowrap">
					<p class="typo-newspaper-headline shrink-0">{getNewspaperRaceLabel(props.race)}</p>
					<div class="typo-newspaper-caption flex shrink-0 items-center gap-[3px]">
						<span>需求</span><span>/</span><span>{getNewspaperMetricLabel(props.metric)}</span><span
							>{props.value}</span
						>
					</div>
				</div>
				<p class="typo-newspaper-body min-w-full w-min">{props.description}</p>
			</div>
			<div
				class="flex h-full min-w-0 flex-1 flex-col items-center gap-px overflow-hidden pl-[6px] whitespace-nowrap"
			>
				<p class="typo-newspaper-data-hero shrink-0 text-center">
					{formatNewspaperNumber(props.countdown)}
				</p>
				<p class="typo-newspaper-caption shrink-0 text-center">个月</p>
				<div
					class="typo-newspaper-caption flex shrink-0 items-start gap-[6px] border-t border-ink-primary"
				>
					<span>強度 {props.strength}%</span><span>·</span><span
						>{getNewspaperEventStateLabel(props.state)}</span
					>
				</div>
			</div>
		</div>
	</div>
{/if}
