<script lang="ts">
	import ChoreItem from '../chore/ChoreItem.svelte';

	type Props = {
		language?: string;
		displayMode?: string;
		disabled?: boolean;
		onLanguageClick?: () => void;
		onDisplayClick?: () => void;
		onExitClick?: () => void;
	};

	let {
		language = '中文',
		displayMode = '窗口',
		disabled = false,
		onLanguageClick,
		onDisplayClick,
		onExitClick
	}: Props = $props();
</script>

<aside class="flex flex-col items-end gap-[20px]" aria-label="游戏设置" data-block-world-input>
	<button
		type="button"
		class="cursor-pointer border-0 bg-transparent p-0 disabled:cursor-default"
		aria-label={`语言：${language}`}
		{disabled}
		onclick={() => onLanguageClick?.()}
	>
		<ChoreItem text="语言" value={language} isRow={false} />
	</button>
	<button
		type="button"
		class="cursor-pointer border-0 bg-transparent p-0 disabled:cursor-default"
		aria-label={`显示：${displayMode}`}
		{disabled}
		onclick={() => onDisplayClick?.()}
	>
		<ChoreItem text="显示" value={displayMode} isRow={false} />
	</button>
	<button
		type="button"
		class="cursor-pointer border-0 bg-transparent p-0 disabled:cursor-default"
		aria-label="退出游戏"
		{disabled}
		onclick={() => onExitClick?.()}
	>
		<ChoreItem text="退出" isRow={false} />
	</button>
</aside>
