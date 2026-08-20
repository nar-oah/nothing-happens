<script lang="ts">
	type Props = {
		text: string;
		vertical?: boolean;
	};

	let { text, vertical = false }: Props = $props();
</script>

<div
	class:h-29={!vertical}
	class:w-128={!vertical}
	class:w-45={vertical}
	class:text-40={!vertical}
	class:text-60={vertical}
	class:leading-32={!vertical}
	class:leading-[48px]={vertical}
	class="flex shrink-0 items-center justify-center overflow-hidden bg-accent-amber-deep font-document font-light text-ink-secondary"
>
	<p class="m-0 text-center [word-break:break-word]">{text}</p>
</div>
