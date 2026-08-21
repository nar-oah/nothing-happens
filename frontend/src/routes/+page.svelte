<script lang="ts">
	import Memorial from '$lib/components/memorial/Memorial.svelte';
	import MemorialConstitutionClosed from '$lib/components/memorial/MemorialConstitutionClosed.svelte';
	import MemorialNewspaper from '$lib/components/memorial/MemorialNewspaper.svelte';
	import MemorialPolicyClosed from '$lib/components/memorial/MemorialPolicyClosed.svelte';
	import MemorialProposalClosed from '$lib/components/memorial/MemorialProposalClosed.svelte';
	import MemorialProposalOption from '$lib/components/memorial/MemorialProposalOption.svelte';
	import MemorialVerticalConstitution from '$lib/components/memorial/MemorialVerticalConstitution.svelte';
	import MemorialVerticalPolicy from '$lib/components/memorial/MemorialVerticalPolicy.svelte';
	import Mark from '$lib/components/mark/Mark.svelte';
	import ChoreFilter from '$lib/components/chore/ChoreFilter.svelte';
	import ChoreItem from '$lib/components/chore/ChoreItem.svelte';
	import ChoreSelect from '$lib/components/chore/ChoreSelect.svelte';
	import ChoreSwitch from '$lib/components/chore/ChoreSwitch.svelte';
	import {
		MetricText,
		MetricSymbol,
		type MemorialConstitutionContentData,
		type MemorialMetricData,
		type MemorialPolicyContentData,
		type MemorialProposalContentData
	} from '$lib/components/memorial/memorial';

	var metrics: MemorialMetricData[] = [
		{
			text: MetricText.Price,
			symbol: MetricSymbol.Decrease,
			value: 5,
			isReverse: true
		},
		{ text: MetricText.Tax, symbol: MetricSymbol.Decrease, value: 8 },
		{ text: MetricText.Employment, symbol: MetricSymbol.Decrease, value: 5 }
	];
	var policyMetrics: MemorialMetricData[] = [
		{ text: MetricText.Trade, value: 2 },
		{ text: MetricText.Employment, value: 5 },
		{ text: MetricText.Wage, value: 3 },
		{ text: MetricText.Price, value: 4 },
		{ text: MetricText.Tax, value: 1 }
	];
	var proposal: MemorialProposalContentData = {
		title: '自由贸易',
		body: '蓬莱与大明相约通商，所有货物一体适用同一税则。'
	};
	var policies: MemorialPolicyContentData[] = [
		{ title: '商', body: '商船按新税则通行，不得另设关卡。' },
		{ title: '税', body: '同类货物适用相同税率。' }
	];
	var articles: MemorialConstitutionContentData[] = [
		{
			title: '公所议事',
			locked: false,
			rows: [
				{ text: '商会', number: 40, selected: true },
				{ text: '工所', number: 35, selected: false }
			]
		},
		{ title: '地方自治', locked: true, requirement: 3 }
	];
	let direction = $state<'up' | 'down'>('up');
	let directionb = $state<'up' | 'down'>('up');
	let newspaperOpened = $state(false);
	let choreSwitch = $state(false);
	let choreSelect = $state(true);
</script>

<svelte:head>
	<title>Memorial Demo</title>
</svelte:head>

<main class="box-border flex min-h-screen flex-col gap-[48px] bg-surface-indigo-muted p-[80px]">
	<section class="flex flex-col gap-[20px]">
		<h2 class="m-0 font-policy text-30 font-medium text-ink-primary">邸报按钮</h2>
		<div class="flex items-end gap-[20px]">
			<MemorialNewspaper term={1} year={1} month={12} onclick={() => (newspaperOpened = true)} />
			{#if newspaperOpened}
				<p class="m-0 font-document text-16 text-ink-primary" aria-live="polite">邸报按钮已触发</p>
			{/if}
		</div>
	</section>

	<section class="flex flex-col gap-[20px]">
		<h2 class="m-0 font-policy text-30 font-medium text-ink-primary">横向奏折</h2>
		<div class="flex flex-wrap items-start gap-[32px]">
			<Memorial count={4} contentTitle={proposal.title} contentBody={proposal.body}>
				{#snippet closed()}
					<MemorialProposalClosed title="造身公所" lag={12} {metrics} />
				{/snippet}
			</Memorial>
			<Memorial count={2} contentTitle={proposal.title} contentBody={proposal.body}>
				{#snippet closed()}
					<MemorialPolicyClosed title="大而美法案" lag={6} metrics={policyMetrics} />
				{/snippet}
			</Memorial>
			<Memorial count={2} contentTitle="公所议事" contentBody="公所依席位表决本地事务。">
				{#snippet closed()}
					<MemorialConstitutionClosed title="蓬莱约法" />
				{/snippet}
			</Memorial>
			<MemorialProposalOption option="確認" lag={5} {metrics} />
		</div>
	</section>

	<section class="flex flex-col gap-[20px]">
		<h2 class="m-0 font-policy text-30 font-medium text-ink-primary">竖版奏折（始终展开）</h2>
		<div class="flex flex-wrap items-start gap-[32px]">
			<MemorialVerticalPolicy
				title="大而美法案"
				lag={6}
				metrics={policyMetrics}
				{proposal}
				{policies}
			/>
			<MemorialVerticalConstitution title="蓬莱约法" {proposal} {articles} />
		</div>
	</section>

	<section class="flex flex-col gap-[20px]">
		<h2 class="m-0 font-policy text-30 font-medium text-ink-primary">印章</h2>
		<div class="flex flex-wrap gap-[32px]">
			<Mark
				bind:direction
				policyName="以工代赈"
				requirement={{
					headline: '所需　用工＜商贸六成',
					detail: '今数　42＜48　本批触发'
				}}
				effect={{
					headline: '效用　用工补至商贸六成',
					detail: '本批　用工＋6'
				}}
			/>
			<Mark
				bind:direction={directionb}
				policyName="以工代赈"
				requirement={{
					headline: '所需　用工＜商贸六成',
					detail: '今数　42＜48　本批触发'
				}}
				effect={{
					headline: '效用　用工补至商贸六成',
					detail: '本批　用工＋6'
				}}
			/>
		</div>
	</section>

	<section class="flex flex-col gap-[20px]">
		<h2 class="m-0 font-policy text-30 font-medium text-ink-primary">杂项控件</h2>
		<div class="flex flex-wrap items-start gap-[36px]">
			<ChoreItem text="政治献金" value={20} limit={24} />
			<ChoreItem text="政治献金" value={8} />
			<ChoreItem text="政治献金" value={20} isRow />
			<ChoreItem text="政治献金" value="限制说明" isRow isCenter={false} />
		</div>
		<div class="flex flex-wrap items-start gap-[36px]">
			<ChoreSwitch bind:isSwitch={choreSwitch} left="种族" right="利益集团" />
			<ChoreSelect bind:isSelect={choreSelect} text="约法" />
		</div>
		<ChoreFilter />
	</section>
</main>
