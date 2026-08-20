<script lang="ts">
	import { FOLD_HEIGHT, FOLD_WIDTH } from './memorial';

	type Props = {
		title?: string;
		body: string;
	};

	let { title, body }: Props = $props();
</script>

<div
	class="box-border h-$height w-$width overflow-hidden px-12 text-ink-primary [word-break:break-word]"
	style:--width={`${FOLD_WIDTH}px`}
	style:--height={`${FOLD_HEIGHT}px`}
>
	{#if title}
		<div class="flex flex-col gap-2 pb-[6px] pt-8">
			<p class="m-0 h-20 w-full font-policy text-[22px] font-medium leading-20">{title}</p>
			<p class="typo-document-body-compact m-0 h-[52px] w-full overflow-hidden">{body}</p>
		</div>
	{:else}
		<p class="typo-document-body-compact m-0 h-full w-full overflow-hidden">{body}</p>
	{/if}
</div>
