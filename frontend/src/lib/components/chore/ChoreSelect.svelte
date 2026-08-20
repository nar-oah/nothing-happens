<script lang="ts">
	type Props = {
		text: string;
		isDirection?: boolean;
		isSelect?: boolean;
		onSelectChange?: (isSelect: boolean) => void;
	};

	let {
		text,
		isDirection = false,
		isSelect = $bindable(true),
		onSelectChange
	}: Props = $props();

	function toggle() {
		isSelect = !isSelect;
		onSelectChange?.(isSelect);
	}
</script>

<button
	type="button"
	class="flex cursor-pointer items-center overflow-hidden border-0 bg-transparent p-0 text-surface-amber"
	aria-label={isDirection
		? `${text}${isSelect ? '升序' : '降序'}`
		: `${isSelect ? '取消选择' : '选择'}${text}`}
	aria-pressed={isSelect}
	onclick={toggle}
>
	<span class:font-archival={!isDirection} class:font-document={isDirection} class="text-24 leading-auto">
		{isDirection ? (isSelect ? '↑' : '↓') : isSelect ? '◆' : '◇'}
	</span>
	<span class="font-document text-24 font-light leading-auto">{text}</span>
</button>
