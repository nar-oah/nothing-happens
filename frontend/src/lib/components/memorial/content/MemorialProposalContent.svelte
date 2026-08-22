<script lang="ts">
	import MemorialHorizontalContent from './MemorialHorizontalContent.svelte';
	import type { MemorialProposalContentData as Props } from '../types';

	let { proposalTitle, content }: Props = $props();
</script>

<div class="flex h-[345px] w-[123px] overflow-hidden text-ink-primary">
	<div class="box-border flex min-w-0 flex-1 justify-center py-8">
		<div class="w-full text-center">
			<MemorialHorizontalContent {...content} />
		</div>
	</div>
	<div class="box-border flex flex-col items-center gap-[20px] px-[6px] py-8 text-ink-primary">
		<span class="font-archival text-24 font-normal leading-auto">◆</span>
		<p class="m-0 w-24 text-center font-document text-24 font-light leading-auto">
			{proposalTitle}
		</p>
	</div>
</div>
