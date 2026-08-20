<script lang="ts">
	import MemorialConstitutionContent from './MemorialConstitutionContent.svelte';
	import MemorialProposalContent from './MemorialProposalContent.svelte';
	import MemorialTitleStrip from './MemorialTitleStrip.svelte';
	import MemorialVertical from './MemorialVertical.svelte';
	import MemorialVerticalCoverFrame from './MemorialVerticalCoverFrame.svelte';
	import type { MemorialConstitutionContentData, MemorialProposalContentData } from './memorial';

	type Props = {
		title: string;
		proposal: MemorialProposalContentData;
		articles: MemorialConstitutionContentData[];
	};

	let { title, proposal, articles }: Props = $props();
</script>

<div class="flex items-start">
	<MemorialVerticalCoverFrame>
		<div class="box-border flex h-full w-full items-center justify-center p-10">
			<MemorialTitleStrip text={title} vertical />
		</div>
	</MemorialVerticalCoverFrame>
	<MemorialVertical count={articles.length + 1}>
		{#snippet page(index: number)}
			{#if index === 0}
				<MemorialProposalContent {...proposal} />
			{:else if articles[index - 1]}
				<MemorialConstitutionContent {...articles[index - 1]} />
			{/if}
		{/snippet}
	</MemorialVertical>
</div>
