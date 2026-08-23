<script lang="ts">
	import { resolve } from '$app/paths';
	import ChoreFilter from '$lib/components/chore/ChoreFilter.svelte';
	import ChoreItem from '$lib/components/chore/ChoreItem.svelte';
	import ContextDetail from '$lib/components/detail/ContextDetail.svelte';
	import { MemorialBillEditor, MemorialProposalClosed } from '$lib/components/memorial';
	import { proposalToMemorialMetrics } from '$lib/components/left/left';
	import {
		getMockBillPreview,
		mockObjectDetail,
		mockSavedBills,
		mockProposalItems
	} from '$lib/demo/mock';

	let leftFilters = $state({
		类型: { options: ['约法', '法案', '提案', '政策'], selected: ['提案'], multiple: true },
		时间: false
	});
	let rightFilters = $state({
		指标: { options: ['税课', '物价', '工钱', '用工', '商贸'], selected: ['商贸'], multiple: true },
		数值: false
	});
	let galleryBill = $state(mockSavedBills[0]);
</script>

<svelte:head><title>Component Gallery</title></svelte:head>

<main class="gallery">
	<header>
		<a href={resolve('/')}>← 返回四界面 Demo</a>
		<h1>基础与复合组件</h1>
	</header>
	<section>
		<ChoreItem text="政治献金" value={20} limit={24} />
		<ChoreFilter left="案牍" right="合成" bind:leftFilters bind:rightFilters />
	</section>
	<section>
		<MemorialProposalClosed
			title={mockProposalItems[0].proposal.source_group.display_name}
			lag={mockProposalItems[0].proposal.lag_months}
			metrics={proposalToMemorialMetrics(mockProposalItems[0].proposal)}
		/>
		<ContextDetail {...mockObjectDetail} onAction={() => undefined} />
	</section>
	<section class="wide">
		<MemorialBillEditor
			bill={galleryBill}
			preview={getMockBillPreview(galleryBill)}
			onTitleChange={(title) => (galleryBill = { ...galleryBill, title })}
		/>
	</section>
</main>

<style>
	.gallery {
		box-sizing: border-box;
		min-height: 100vh;
		display: flex;
		flex-direction: column;
		gap: 36px;
		padding: 48px;
		background: #537087;
	}
	header {
		display: flex;
		align-items: baseline;
		gap: 24px;
		color: #1e2e3b;
		font-family: 'RealTypeWriter';
	}
	header a {
		color: #1e2e3b;
	}
	section {
		display: flex;
		align-items: flex-start;
		gap: 32px;
	}
	.wide {
		overflow-x: auto;
		padding-bottom: 20px;
	}
</style>
