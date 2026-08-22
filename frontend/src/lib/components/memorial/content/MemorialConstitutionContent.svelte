<script lang="ts">
	import type { Snippet } from 'svelte';

	type Props = {
		title: string;
		children: Snippet;
	};

	let { title, children }: Props = $props();
</script>

<div
	class="box-border flex h-[345px] w-[123px] flex-col items-center overflow-hidden py-[6px] text-ink-primary"
>
	<p class="m-0 shrink-0 whitespace-nowrap font-policy text-30 font-medium leading-[38px]">
		{title}
	</p>
	<div class="min-h-0 w-full flex-1 overflow-hidden">{@render children()}</div>
</div>
