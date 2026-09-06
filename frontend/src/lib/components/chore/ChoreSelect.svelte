<script lang="ts">
	import { t } from '$lib/i18n';
	type Props = {
		text: string;
		isDirection?: boolean;
		isSelect?: boolean;
		onSelectChange?: (isSelect: boolean) => void;
	};

	let { text, isDirection = false, isSelect = $bindable(true), onSelectChange }: Props = $props();

	function toggle() {
		isSelect = !isSelect;
		onSelectChange?.(isSelect);
	}
</script>

<button
	type="button"
	class="flex cursor-pointer items-center overflow-hidden border-0 bg-transparent p-0 text-surface-amber"
	aria-label={isDirection
		? $t(isSelect ? 'ui.ascending' : 'ui.descending', { text })
		: $t(isSelect ? 'ui.deselectItem' : 'ui.selectItem', { text })}
	aria-pressed={isSelect}
	onclick={toggle}
>
	<span class:typo-filter-marker={!isDirection} class:typo-filter-option={isDirection}>
		{isDirection ? (isSelect ? '↑' : '↓') : isSelect ? '◆' : '◇'}
	</span>
	<span class="typo-filter-option">{text}</span>
</button>
