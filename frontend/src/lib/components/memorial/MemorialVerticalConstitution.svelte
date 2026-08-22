<script lang="ts">
	import MemorialConstitutionContent from './MemorialConstitutionContent.svelte';
	import MemorialProposalContent from './MemorialProposalContent.svelte';
	import MemorialTitleStrip from './MemorialTitleStrip.svelte';
	import MemorialVertical from './MemorialVertical.svelte';
	import MemorialVerticalCoverFrame from './MemorialVerticalCoverFrame.svelte';
	import type { MemorialConstitutionContentData, MemorialProposalContentData } from './memorial';

	type Props = {
		title: string;
		proposals: MemorialProposalContentData[];
		articles: MemorialConstitutionContentData[];
	};

	let { title, proposals, articles }: Props = $props();
</script>

<div class="flex items-start">
	<MemorialVerticalCoverFrame>
		<div class="box-border flex h-full w-full items-center justify-center p-10">
			<MemorialTitleStrip text={title} vertical />
		</div>
	</MemorialVerticalCoverFrame>
	<MemorialVertical count={proposals.length + articles.length}>
		{#snippet page(index: number)}
			{#if proposals[index]}
				<MemorialProposalContent {...proposals[index]} />
			{:else if articles[index - proposals.length]}
				<MemorialConstitutionContent {...articles[index - proposals.length]} />
			{/if}
		{/snippet}
	</MemorialVertical>
</div>
