<script lang="ts">
	import {
		MemorialBillClosed,
		MemorialConstitutionClosed,
		MemorialHorizontal,
		MemorialNewspaper,
		MemorialProposalClosed,
		MemorialProposalOption,
		MemorialVerticalConstitution,
		MemorialVerticalPolicy,
		MetricText,
		MetricSymbol,
		type MemorialConstitutionData,
		type MemorialMetricData,
		type MemorialPolicyContentData,
		type MemorialProposalContentData,
		type MemorialHorizontalContentData
	} from '$lib/components/memorial';
	import Mark from '$lib/components/mark/Mark.svelte';
	import ChoreFilter from '$lib/components/chore/ChoreFilter.svelte';
	import ChoreItem from '$lib/components/chore/ChoreItem.svelte';
	import ChoreSelect from '$lib/components/chore/ChoreSelect.svelte';
	import ChoreSwitch from '$lib/components/chore/ChoreSwitch.svelte';
	import Dialog from '$lib/components/dialog/Dialog.svelte';
	import TopDialog from '$lib/components/dialog/TopDialog.svelte';
	import {
		Metric,
		MetricConditionOperator,
		PolicyEffectFormula,
		type InterestGroupDefinition,
		type MetricValues,
		type PolicyDefinition,
		type Proposal
	} from '$lib/game';

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
	const guild: InterestGroupDefinition = {
		display_name: '造身公所',
		base_column_weight: 3,
		decrease_tax: false,
		decrease_price: false,
		decrease_wage: false,
		decrease_employment: true,
		decrease_trade: false
	};
	const billProposals: Proposal[] = [
		{
			source_group: guild,
			base_effect: { tax: 0, price: 0, wage: 0, employment: -8, trade: 0 },
			positive_effect: { tax: -5, price: 0, wage: 0, employment: 0, trade: 0 },
			lag_months: 6,
			collapse_impact: 1,
			donation_offer: 5,
			bonus_choice_resolved: true,
			positive_trait_accepted: true
		}
	];
	const markPolicy: PolicyDefinition = {
		display_name: '以工代賑',
		condition: {
			left_metric: Metric.EMPLOYMENT,
			operator: MetricConditionOperator.LESS_THAN,
			right_metric: Metric.TRADE,
			right_multiplier: 0.6
		},
		effects: [
			{
				target_metric: Metric.EMPLOYMENT,
				formula: PolicyEffectFormula.METRIC_VALUE,
				source_a: Metric.TRADE,
				source_b: Metric.EMPLOYMENT,
				multiplier: 0.075
			}
		],
		collapse_impact: 1
	};
	const markBaseline: MetricValues = {
		tax: 100,
		price: 100,
		wage: 100,
		employment: 42,
		trade: 80
	};
	var contents: MemorialHorizontalContentData[] = [
		{
			title: '通商章程',
			body: '蓬莱与大明相约通商，所有货物一体适用同一税则。蓬莱与大明相约通商，所有货物一体适用同一税则。蓬莱与大明相约通商，所有货物一体适用同一税则。蓬莱与大明相约通商，所有货物一体适用同一税则。蓬莱与大明相约通商，所有货物一体适用同一税则。蓬莱与大明相约通商，所有货物一体适用同一税则。蓬莱与大明相约通商，所有货物一体适用同一税则。'
		},
		{
			title: '通商章程',
			body: '蓬莱与大明相约通商，所有货物一体适用同一税则。'
		}
	];
	var proposal: MemorialProposalContentData = {
		proposalTitle: '自由贸易',
		content: {
			title: '通商章程',
			body: '蓬莱与大明相约通商，所有货物一体适用同一税则。'
		}
	};
	const policyOne: MemorialPolicyContentData = {
		policyTitle: '商',
		content: { title: '商船通行', body: '商船按新税则通行，不得另设关卡。' }
	};
	const policyTwo: MemorialPolicyContentData = {
		policyTitle: '税',
		content: { body: '同类货物适用相同税率。' }
	};
	let proposals = $state<MemorialProposalContentData[]>([proposal]);
	let policies = $state<MemorialPolicyContentData[]>([policyOne, policyTwo]);
	var constitution: MemorialConstitutionData = {
		公所议事: [
			{
				text: '商会',
				number: 40,
				selected: true,
				selectable: true,
				contents: [
					{ title: '商会席位', body: '商会推举代表参与公所议事。' },
					{ body: '席位依本地商户名册核定。' }
				],
				policies: [policyOne]
			},
			{
				text: '工所',
				number: 35,
				selected: false,
				selectable: false,
				contents: [{ body: '工所推举代表陈述工匠事务。' }],
				policies: [policyTwo]
			}
		],
		地方自治: 3
	};
	let direction = $state<'up' | 'down'>('up');
	let directionb = $state<'up' | 'down'>('up');
	let newspaperOpened = $state(false);
	let choreSwitch = $state(false);
	let choreSelect = $state(true);
	var dialogText = '如果每个人都要求现在回答，\n那么“迟一点”本身就会成为一种罪。';
	let leftFilters = $state({
		案牍: {
			options: ['约法', '法案', '提案', '政策'],
			selected: ['约法', '法案', '提案', '政策'],
			multiple: true
		},
		指标: {
			options: ['税课', '物价', '工钱', '用工', '商贸'],
			selected: ['税课'],
			multiple: false
		},
		时间: false,
		数值: false
	});
	let rightFilters = $state({
		案牍: {
			options: ['约法', '法案', '提案', '政策'],
			selected: ['提案', '政策'],
			multiple: true
		},
		指标: {
			options: ['税课', '物价', '工钱', '用工', '商贸'],
			selected: ['商贸'],
			multiple: false
		},
		时间: true,
		数值: true
	});
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
		<h2 class="m-0 font-policy text-30 font-medium text-ink-primary">对话框</h2>
		<div class="flex flex-col items-start gap-[32px]">
			<Dialog text={dialogText} />
			<TopDialog text={dialogText} />
		</div>
	</section>

	<section class="flex flex-col gap-[20px]">
		<h2 class="m-0 font-policy text-30 font-medium text-ink-primary">横向奏折</h2>
		<div class="flex flex-wrap items-start gap-[32px]">
			<MemorialHorizontal {contents}>
				{#snippet closed()}
					<MemorialProposalClosed title="造身公所" lag={12} {metrics} />
				{/snippet}
			</MemorialHorizontal>
			<MemorialHorizontal {contents}>
				{#snippet closed()}
					<MemorialBillClosed
						title="大而美法案"
						proposals={billProposals}
						policies={[markPolicy]}
					/>
				{/snippet}
			</MemorialHorizontal>
			<MemorialHorizontal contents={[{ title: '公所议事', body: '公所依席位表决本地事务。' }]}>
				{#snippet closed()}
					<MemorialConstitutionClosed title="蓬莱约法" />
				{/snippet}
			</MemorialHorizontal>
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
				bind:proposals
				bind:policies
			/>
			<MemorialVerticalConstitution title="蓬莱约法" {constitution} />
		</div>
	</section>

	<section class="flex flex-col gap-[20px]">
		<h2 class="m-0 font-policy text-30 font-medium text-ink-primary">印章</h2>
		<div class="flex flex-wrap gap-[32px]">
			<Mark
				bind:direction
				policy={markPolicy}
				baseline={markBaseline}
			/>
			<Mark
				bind:direction={directionb}
				policy={markPolicy}
				baseline={markBaseline}
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
		<ChoreFilter left="种族" right="利益集团" bind:leftFilters bind:rightFilters />
	</section>
</main>
