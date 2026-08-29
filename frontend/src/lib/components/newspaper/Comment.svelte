<script lang="ts">
	import { untrack } from 'svelte';
	import { NEWSPAPER_COMMENTS } from '$lib/content/newspaper-comments';
	import MorphText from '../text/MorphText.svelte';

	type Props = { title: string[]; comment: string[] };
	let { title, comment }: Props = $props();
	const items = $derived.by(() => {
		const providedCount = Math.min(title.length, comment.length);
		if (providedCount > 0) {
			return Array.from({ length: providedCount }, (_, index) => ({
				title: title[index] ?? '',
				comment: comment[index] ?? ''
			}));
		}
		return NEWSPAPER_COMMENTS;
	});
	let index = $state(
		untrack(() => (NEWSPAPER_COMMENTS.length > 0 ? Math.floor(Math.random() * NEWSPAPER_COMMENTS.length) : 0))
	);
	let hovering = $state(false);
	const count = $derived(items.length);
	const safeIndex = $derived(count > 0 ? index % count : 0);
	const nextIndex = $derived(count > 0 ? (safeIndex + 1) % count : 0);
	const displayIndex = $derived(hovering ? nextIndex : safeIndex);
	const displayTitle = $derived(items[displayIndex]?.title ?? '');
	const displayComment = $derived(items[displayIndex]?.comment ?? '');

	function advance() {
		index = nextIndex;
		hovering = false;
	}
</script>

<button
	class="flex h-full w-full flex-col items-start gap-[3px] overflow-hidden border-0 bg-transparent px-8 py-5 text-left text-ink-primary"
	type="button"
	aria-label="切换报纸评论"
	onmouseenter={() => (hovering = true)}
	onmouseleave={() => (hovering = false)}
	onfocus={() => (hovering = true)}
	onblur={() => (hovering = false)}
	onclick={advance}
>
	<div class="flex w-full shrink-0 items-start gap-8 overflow-hidden">
		<p class="typo-newspaper-headline min-w-0 flex-1">
			{#key displayIndex}
				<MorphText text={displayTitle} />
			{/key}
		</p>
		<div class="flex shrink-0 flex-col items-end px-5 py-2">
			<p class="typo-newspaper-caption whitespace-nowrap">COMMENT / BACK PAGE</p>
		</div>
	</div>
	<div class="h-px w-full shrink-0 bg-ink-primary"></div>
	<p class="typo-newspaper-subhead w-full shrink-0">
		{#key displayIndex}
			<MorphText text={displayComment} />
		{/key}
	</p>
</button>
