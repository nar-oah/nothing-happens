<script lang="ts">
	import { t } from '$lib/i18n';
	import { untrack } from 'svelte';
	import MemorialConstitutionContent from '../content/MemorialConstitutionContent.svelte';
	import MemorialConstitutionRow from '../content/MemorialConstitutionRow.svelte';
	import MemorialHorizontalContent from '../content/MemorialHorizontalContent.svelte';
	import MemorialPolicyContent from '../content/MemorialPolicyContent.svelte';
	import { paginateMemorialContents } from '../pagination';
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
		unlockableSections?: string[];
		onArticleSelectionChange?: (articleRef: number, selected: boolean) => void;
		onSectionUnlock?: (sectionTitle: string) => void;
	};
	const DETAIL_LINE_WIDTH = 7;
	const TITLED_DETAIL_BODY_LINES = 12;
	const UNTITLED_DETAIL_BODY_LINES = 13;

	type ConstitutionPage =
		| {
				type: 'section';
				title: string;
				content: number | MemorialConstitutionRowContentData[];
		  }
		| { type: 'detail'; title: string; contents: MemorialHorizontalContentData[] }
		| { type: 'policy'; content: MemorialPolicyContentData };
	type PendingArticleSelection = {
		sectionTitle: string;
		rowKey: string;
		articleRef: number;
	};

	let {
		title,
		constitution,
		unlockableSections = [],
		onArticleSelectionChange,
		onSectionUnlock
	}: Props = $props();
	let expandedRow = $state<{ sectionTitle: string; rowIndex: number }>();
	let pendingSelection = $state<PendingArticleSelection>();
	let appliedConstitution = untrack(() => constitution);
	let pages: ConstitutionPage[] = $derived.by(() => {
		const sectionPages = Object.entries(constitution).map(
			([sectionTitle, content]): ConstitutionPage => ({
				type: 'section',
				title: sectionTitle,
				content
			})
		);
		if (!expandedRow) return sectionPages;

		const content = constitution[expandedRow.sectionTitle];
		if (typeof content === 'number') return sectionPages;
		const row = content?.[expandedRow.rowIndex];
		if (!row || row.articleRef === undefined) return sectionPages;

		const detailPages = paginateMemorialContents(row.contents, {
			lineWidth: DETAIL_LINE_WIDTH,
			titledPageBodyLines: TITLED_DETAIL_BODY_LINES,
			untitledPageBodyLines: UNTITLED_DETAIL_BODY_LINES
		});
		return [
			...sectionPages,
			...detailPages.map((content, index): ConstitutionPage => ({
				type: 'detail',
				title: index === 0 ? row.text : '',
				contents: [content]
			})),
			...row.policies.map((policy): ConstitutionPage => ({ type: 'policy', content: policy }))
		];
	});

	$effect(() => {
		if (constitution === appliedConstitution) return;
		appliedConstitution = constitution;
		expandedRow = undefined;
		pendingSelection = undefined;
	});

	function openRow(
		sectionTitle: string,
		rowIndex: number,
		row: MemorialConstitutionRowContentData
	) {
		if (row.articleRef === undefined) return;
		expandedRow = { sectionTitle, rowIndex };
	}

	function getRowKey(
		sectionTitle: string,
		rowIndex: number,
		row: MemorialConstitutionRowContentData
	) {
		return row.articleRef === undefined
			? `${sectionTitle}-${rowIndex}`
			: `article-${row.articleRef}`;
	}

	function getRowSelected(
		sectionTitle: string,
		rowIndex: number,
		row: MemorialConstitutionRowContentData
	) {
		if (pendingSelection?.sectionTitle !== sectionTitle) return row.selected;
		return pendingSelection.rowKey === getRowKey(sectionTitle, rowIndex, row);
	}

	function setRowSelected(
		sectionTitle: string,
		rowIndex: number,
		row: MemorialConstitutionRowContentData,
		selected: boolean
	) {
		if (row.articleRef === undefined) return;
		const rowKey = getRowKey(sectionTitle, rowIndex, row);
		if (selected) {
			const previousArticleRef = pendingSelection?.articleRef;
			pendingSelection = { sectionTitle, rowKey, articleRef: row.articleRef };
			if (previousArticleRef !== undefined && previousArticleRef !== row.articleRef) {
				onArticleSelectionChange?.(previousArticleRef, false);
			}
			onArticleSelectionChange?.(row.articleRef, true);
			return;
		}
		if (pendingSelection?.articleRef !== row.articleRef) return;
		pendingSelection = undefined;
		onArticleSelectionChange?.(row.articleRef, false);
	}
</script>

<div class="flex items-start" data-block-world-input>
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
						<button
							class="flex h-full w-full flex-col items-center justify-center border-0 bg-ink-primary p-0 font-document text-[60px] font-light leading-[48px] text-surface-amber"
							type="button"
							disabled={!unlockableSections.includes(currentPage.title)}
							onclick={() => onSectionUnlock?.(currentPage.title)}
							aria-label={$t('memorial.unlock', { title: currentPage.title, years: currentPage.content })}
						>
							{#each [0, 1, 2, 3, 4, 5] as row (row)}
								<span>{currentPage.content}</span>
							{/each}
						</button>
					{:else}
						<div class="flex h-full flex-col items-center gap-[20px] pt-10">
							{#each currentPage.content as row, rowIndex (`${currentPage.title}-${row.text}-${rowIndex}`)}
								<MemorialConstitutionRow
									{...row}
									empty={row.articleRef === undefined && row.text === ''}
									selected={getRowSelected(currentPage.title, rowIndex, row)}
									onSelectedChange={(selected) =>
										setRowSelected(currentPage.title, rowIndex, row, selected)}
									onclick={() => openRow(currentPage.title, rowIndex, row)}
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
