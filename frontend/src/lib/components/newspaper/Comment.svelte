<script lang="ts">
	import { onMount } from 'svelte';
	import MorphText from '../text/MorphText.svelte';
	type Props = { title: string[]; comment: string[] };
	let { title, comment }: Props = $props();
	let index = $state(0);
	let hovering = $state(false);
	const count = $derived(Math.min(title.length, comment.length));
	const nextIndex = $derived(count > 0 ? (index + 1) % count : 0);
	const displayIndex = $derived(hovering ? nextIndex : index);
	const displayTitle = $derived(title[displayIndex] ?? '');
	const displayComment = $derived(comment[displayIndex] ?? '');

	onMount(() => {
		if (count > 0) index = Math.floor(Math.random() * count);
	});

	function advance() {
		index = nextIndex;
		hovering = false;
	}
</script>

<button
	class="flex h-full w-full flex-col items-start gap-[3px] overflow-hidden border-0 bg-transparent px-8 py-5 text-left"
	type="button"
	aria-label="切换报纸评论"
	onmouseenter={() => (hovering = true)}
	onmouseleave={() => (hovering = false)}
	onfocus={() => (hovering = true)}
	onblur={() => (hovering = false)}
	onclick={advance}
>
	<div class="flex w-full shrink-0 items-start gap-8 overflow-hidden">
		<p class="typo-newspaper-headline min-w-0 flex-1"><MorphText text={displayTitle} /></p>
		<div class="flex shrink-0 flex-col items-end px-5 py-2">
			<p class="typo-newspaper-caption whitespace-nowrap">COMMENT / BACK PAGE</p>
		</div>
	</div>
	<div class="h-px w-full shrink-0 bg-ink-primary"></div>
	<p class="typo-newspaper-subhead w-full shrink-0"><MorphText text={displayComment} /></p>
</button>
