<script lang="ts">
	import MorphText from '../text/MorphText.svelte';
	type Props = { title: string; comment: string };
	let { title, comment }: Props = $props();
</script>

<div class="flex h-full w-full flex-col items-start gap-[3px] overflow-hidden px-8 py-5">
	<div class="flex w-full shrink-0 items-start gap-8 overflow-hidden">
		<p class="typo-newspaper-headline min-w-0 flex-1"><MorphText text={title} /></p>
		<div class="flex shrink-0 flex-col items-end px-5 py-2">
			<p class="typo-newspaper-caption whitespace-nowrap">COMMENT / BACK PAGE</p>
		</div>
	</div>
	<div class="h-px w-full shrink-0 bg-ink-primary"></div>
	<p class="typo-newspaper-subhead w-full shrink-0"><MorphText text={comment} /></p>
</div>
