<script lang="ts">
	import type { MemorialHorizontalContentData as Props } from '../types';

	let { title, body }: Props = $props();
</script>

<div class="flex min-w-0 flex-col text-ink-primary [word-break:break-word]">
	{#if title}
		<p class="m-0 w-full font-policy text-[22px] font-medium leading-20">{title}</p>
		<p class="typo-document-body-compact m-0 mt-3 w-full whitespace-pre-line overflow-hidden">
			{body}
		</p>
	{:else}
		<p class="typo-document-body-compact m-0 w-full whitespace-pre-line overflow-hidden">{body}</p>
	{/if}
</div>
