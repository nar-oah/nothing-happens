<script lang="ts">
	import ChoreItem from '../chore/ChoreItem.svelte';
	import ChoreSwitch from '../chore/ChoreSwitch.svelte';
	import type { ContextDetailData } from './detail';

	type Props = ContextDetailData & {
		isRight?: boolean;
		onModeChange?: (isRight: boolean) => void;
		onAction?: (isRight: boolean) => void;
		onClose?: () => void;
	};

	let {
		title,
		value,
		limit,
		leftLabel,
		rightLabel,
		leftBody,
		rightBody,
		actionLabel = '执行',
		isRight = $bindable(false),
		onModeChange,
		onAction,
		onClose
	}: Props = $props();
</script>

<section class="flex w-[360px] flex-col items-start" aria-label={`${title}详情`}>
	<div class="flex w-full items-end justify-between gap-10 bg-shadow-deep p-10">
		<ChoreItem text={title} {value} {limit} isRow />
		{#if onClose}
			<button
				type="button"
				class="cursor-pointer border-0 bg-transparent font-document text-24 text-surface-amber"
				aria-label={`关闭${title}详情`}
				onclick={onClose}>×</button
			>
		{/if}
	</div>
	<div class="box-border flex min-h-[150px] w-full flex-col bg-ink-primary p-12 text-surface-amber">
		<ChoreSwitch
			left={leftLabel}
			right={rightLabel}
			bind:isSwitch={isRight}
			onSwitchChange={onModeChange}
		/>
		<p class="mb-12 mt-8 whitespace-pre-line font-document text-20 leading-28">
			{isRight ? rightBody : leftBody}
		</p>
		{#if onAction}
			<button
				type="button"
				class="self-end cursor-pointer border-0 bg-accent-amber-deep px-12 py-5 font-policy text-20 text-shadow-deep"
				onclick={() => onAction?.(isRight)}
			>
				{actionLabel}
			</button>
		{/if}
	</div>
</section>
