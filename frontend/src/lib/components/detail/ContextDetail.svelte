<script lang="ts">
	import { t } from '$lib/i18n';
	import ChoreItem from '../chore/ChoreItem.svelte';
	import ChoreSwitch from '../chore/ChoreSwitch.svelte';
	import type { ContextDetailData } from './detail';

	type Props = ContextDetailData & {
		isRight?: boolean;
		onModeChange?: (isRight: boolean) => void;
		onClose?: () => void;
	};

	let {
		title,
		leftLabel,
		rightLabel,
		leftBody,
		rightBody,
		isRight = $bindable(false),
		onModeChange,
		onClose
	}: Props = $props();
</script>

<section
	class="flex w-[500px] flex-col items-start"
	aria-label={$t('ui.details', { title })}
	data-block-world-input
>
	<ChoreItem
		text={title}
		value={isRight ? rightBody : leftBody}
		isRow
		isCenter={false}
		onTitleClick={onClose}
	/>
	<ChoreSwitch
		left={leftLabel}
		right={rightLabel}
		bind:isSwitch={isRight}
		onSwitchChange={onModeChange}
	/>
</section>
