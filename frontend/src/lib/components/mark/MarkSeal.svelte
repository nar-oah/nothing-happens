<script lang="ts">
	type Props = {
		text?: string;
	};

	let { text = '以工代赈' }: Props = $props();
</script>

<div class="relative h-[80px] w-[80px] overflow-hidden rounded-[3px] bg-surface-indigo">
	<div
		class="typo-seal-policy-name absolute inset-0 flex items-center justify-center text-center text-surface-amber"
	>
		<span class="w-[72px] break-all">{text}</span>
	</div>
</div>
