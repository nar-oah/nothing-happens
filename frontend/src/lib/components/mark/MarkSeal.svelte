<script lang="ts">
	type Props = {
		text?: string;
	};

	let { text = '以工代赈' }: Props = $props();
</script>

<div class="relative h-full w-full overflow-hidden bg-surface-indigo" aria-label={text}>
	<div
		class="typo-seal-policy-name absolute inset-0 flex items-center justify-center text-center text-surface-amber"
	>
		<span class="break-all">{text}</span>
	</div>
</div>
