<script lang="ts">
	import MemorialConstitutionContent from '../content/MemorialConstitutionContent.svelte';
	import MemorialConstitutionRow from '../content/MemorialConstitutionRow.svelte';
	import MemorialHorizontalContent from '../content/MemorialHorizontalContent.svelte';
	import MemorialPolicyContent from '../content/MemorialPolicyContent.svelte';
	import MemorialTitleStrip from '../shared/MemorialTitleStrip.svelte';
	import MemorialVertical from './MemorialVertical.svelte';
	import MemorialVerticalCover from './MemorialVerticalCover.svelte';
	import type {
		MemorialConstitutionData,
		MemorialConstitutionRowContentData,
		MemorialHorizontalContentData,
		MemorialPolicyContentData
	} from '../types';

	type Props = {
		title: string;
		constitution: MemorialConstitutionData;
	};

	type ConstitutionPage =
		| {
				type: 'section';
				title: string;
				content: number | MemorialConstitutionRowContentData[];
		  }
		| { type: 'detail'; title: string; contents: MemorialHorizontalContentData[] }
		| { type: 'policy'; content: MemorialPolicyContentData };

	let { title, constitution }: Props = $props();
	let expandedRow = $state<{ sectionTitle: string; rowIndex: number }>();
	let pages: ConstitutionPage[] = $derived.by(() =>
		Object.entries(constitution).flatMap(([sectionTitle, content]) => {
			const sectionPage: ConstitutionPage = { type: 'section', title: sectionTitle, content };
			if (
				typeof content === 'number' ||
				expandedRow?.sectionTitle !== sectionTitle ||
				!content[expandedRow.rowIndex]
			) {
				return [sectionPage];
			}

			const row = content[expandedRow.rowIndex];
			return [
				sectionPage,
				{ type: 'detail', title: row.text, contents: row.contents },
				...row.policies.map((policy): ConstitutionPage => ({ type: 'policy', content: policy }))
			];
		})
	);

	function openRow(sectionTitle: string, rowIndex: number) {
		expandedRow = { sectionTitle, rowIndex };
	}
</script>

<div class="flex items-start">
	<MemorialVerticalCover>
		<div class="box-border flex h-full w-full items-center justify-center p-10">
			<MemorialTitleStrip text={title} vertical />
		</div>
	</MemorialVerticalCover>
	<MemorialVertical count={pages.length}>
		{#snippet page(index: number)}
			{@const currentPage = pages[index]}
			{#if currentPage?.type === 'section'}
				<MemorialConstitutionContent title={currentPage.title}>
					{#if typeof currentPage.content === 'number'}
						<div
							class="flex h-full w-full flex-col items-center justify-center bg-ink-primary font-document text-[60px] font-light leading-[48px] text-surface-amber"
							aria-label={`解锁要求 ${currentPage.content}`}
						>
							{#each [0, 1, 2, 3, 4, 5] as row (row)}
								<span>{currentPage.content}</span>
							{/each}
						</div>
					{:else}
						<div class="flex h-full flex-col items-center gap-[20px] pt-10">
							{#each currentPage.content as row, rowIndex (`${currentPage.title}-${row.text}-${rowIndex}`)}
								<MemorialConstitutionRow
									{...row}
									onclick={() => openRow(currentPage.title, rowIndex)}
								/>
							{/each}
						</div>
					{/if}
				</MemorialConstitutionContent>
			{:else if currentPage?.type === 'detail'}
				<MemorialConstitutionContent title={currentPage.title}>
					<div class="flex h-full flex-col gap-10 overflow-hidden px-12 pt-10">
						{#each currentPage.contents as content, contentIndex (contentIndex)}
							<MemorialHorizontalContent {...content} />
						{/each}
					</div>
				</MemorialConstitutionContent>
			{:else if currentPage?.type === 'policy'}
				<MemorialPolicyContent {...currentPage.content} />
			{/if}
		{/snippet}
	</MemorialVertical>
</div>
