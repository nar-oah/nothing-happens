<script lang="ts">
	type Props = {
		text: string;
		is_ghost?: boolean;
	};
	let { text, is_ghost = false }: Props = $props();
</script>

<div
	class="relative h-full w-full overflow-hidden"
	class:bg-surface-indigo={!is_ghost}
	aria-label={text}
>
	<div
		class="typo-seal-policy-name absolute inset-0 flex items-center justify-center text-center"
		class:text-surface-indigo={is_ghost}
		class:text-surface-amber={!is_ghost}
	>
		<span class="break-all">{text}</span>
	</div>
</div>
