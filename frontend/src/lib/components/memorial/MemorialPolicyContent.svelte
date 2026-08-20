<script lang="ts">
	import MarkSeal from '../mark/MarkSeal.svelte';

	type Props = {
		title?: string;
		body?: string;
	};

	let {
		title = '以工代赈',
		body = '税课低于商贸时，按两者落差降低物价。'
	}: Props = $props();
</script>

<div
	class="box-border flex h-[345px] w-[123px] flex-col items-center gap-5 overflow-hidden py-12 text-ink-primary"
>
	<div class="h-80 w-80 shrink-0 overflow-hidden rounded-3">
		<MarkSeal text={title} />
	</div>
	<p class="typo-document-body-compact m-0 w-[92px] [word-break:break-word]">{body}</p>
</div>
