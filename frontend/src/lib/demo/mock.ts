import {
	METRIC_DISPLAY_NAMES,
	Metric,
	MetricConditionOperator,
	PolicyEffectFormula,
	getBillMetrics,
	type Bill,
	type InterestGroupDefinition,
	type MetricValues,
	type PolicyDefinition,
	type Proposal
} from '$lib/game';
import type { ContextDetailData } from '$lib/components/detail/detail';
import type {
	BillLeftItem,
	ConstitutionLeftItem,
	PolicyLeftItem,
	ProposalLeftItem
} from '$lib/components/left/types';
import type { MemorialConstitutionData, MemorialMetricData } from '$lib/components/memorial/types';
import type { StateItem } from '$lib/components/state/GameStateDisplay.svelte';
import type { TopItemData } from '$lib/components/top/top';

const makeGroup = (
	display_name: string,
	decreases: Partial<Record<Metric, boolean>> = {}
): InterestGroupDefinition => ({
	display_name,
	base_column_weight: 1,
	decrease_tax: decreases[Metric.TAX] ?? false,
	decrease_price: decreases[Metric.PRICE] ?? false,
	decrease_wage: decreases[Metric.WAGE] ?? false,
	decrease_employment: decreases[Metric.EMPLOYMENT] ?? false,
	decrease_trade: decreases[Metric.TRADE] ?? false
});

const merchants = makeGroup('通商公所', { [Metric.TAX]: true });
const workers = makeGroup('百工公所', { [Metric.WAGE]: true });
const farmers = makeGroup('农务公所', { [Metric.PRICE]: true });

const vector = (values: Partial<MetricValues> = {}): MetricValues => ({
	tax: values.tax ?? 0,
	price: values.price ?? 0,
	wage: values.wage ?? 0,
	employment: values.employment ?? 0,
	trade: values.trade ?? 0
});

const makeProposal = (
	source_group: InterestGroupDefinition,
	base_effect: Partial<MetricValues>,
	positive_effect: Partial<MetricValues> = {},
	lag_months = 3
): Proposal => ({
	source_group,
	base_effect: vector(base_effect),
	positive_effect: vector(positive_effect),
	lag_months,
	collapse_impact: 1,
	donation_offer: 12,
	bonus_choice_resolved: true,
	positive_trait_accepted: true
});

const makePolicy = (
	display_name: string,
	left_metric: Metric,
	target_metric: Metric,
	source_a: Metric,
	multiplier: number
): PolicyDefinition => ({
	display_name,
	condition: {
		left_metric,
		operator: MetricConditionOperator.LESS_THAN,
		right_metric: Metric.TRADE,
		right_multiplier: 1
	},
	effects: [
		{
			target_metric,
			formula: PolicyEffectFormula.METRIC_VALUE,
			source_a,
			source_b: Metric.TAX,
			multiplier
		}
	],
	collapse_impact: 1
});

export const mockBaseline: MetricValues = {
	tax: 72,
	price: 108,
	wage: 84,
	employment: 61,
	trade: 96
};

export const mockPolicies: PolicyDefinition[] = [
	makePolicy('均平税则', Metric.PRICE, Metric.TAX, Metric.TRADE, -0.08),
	makePolicy('平准仓法', Metric.PRICE, Metric.PRICE, Metric.TRADE, -0.05),
	makePolicy('工钱章程', Metric.WAGE, Metric.WAGE, Metric.TRADE, 0.06),
	makePolicy('以工代赈', Metric.EMPLOYMENT, Metric.EMPLOYMENT, Metric.TRADE, 0.08),
	makePolicy('商船通行', Metric.TAX, Metric.TRADE, Metric.TAX, 0.12)
];

export const mockProposalItems: ProposalLeftItem[] = [
	{
		kind: 'proposal',
		ref: { collection: 'proposals', index: 0 },
		proposal: makeProposal(merchants, { tax: -8, trade: 2 }, { trade: 8 }, 6)
	},
	{
		kind: 'proposal',
		ref: { collection: 'proposals', index: 1 },
		proposal: makeProposal(workers, { wage: 7, employment: -4 }, { tax: -5 }, 3)
	},
	{
		kind: 'proposal',
		ref: { collection: 'proposals', index: 2 },
		proposal: makeProposal(farmers, { price: -6, tax: 2 }, {}, 4)
	},
	{
		kind: 'proposal',
		ref: { collection: 'proposals', index: 3 },
		proposal: makeProposal(merchants, { trade: 9, price: 3 }, { wage: 6 }, 2)
	},
	{
		kind: 'proposal',
		ref: { collection: 'proposals', index: 4 },
		proposal: makeProposal(workers, { employment: 8, wage: -3 }, {}, 5)
	},
	{
		kind: 'proposal',
		ref: { collection: 'proposals', index: 5 },
		proposal: makeProposal(farmers, { price: -10, trade: -2 }, { employment: 7 }, 7)
	},
	{
		kind: 'proposal',
		ref: { collection: 'proposals', index: 6 },
		proposal: makeProposal(merchants, { tax: -4, trade: 5 }, {}, 1)
	},
	{
		kind: 'proposal',
		ref: { collection: 'proposals', index: 7 },
		proposal: makeProposal(workers, { wage: 4, employment: 6 }, { price: -8 }, 4)
	}
];

export const mockPolicyItems: PolicyLeftItem[] = mockPolicies.map((policy, index) => ({
	kind: 'policy',
	ref: { collection: 'policies', index },
	policy
}));

const missingProposal = makeProposal(makeGroup('旧港商会'), { tax: -99 }, {}, 12);
const stalePolicy = makePolicy('旧港专卖', Metric.TAX, Metric.TRADE, Metric.TAX, -0.5);

export const mockSavedBills: Bill[] = [
	{
		title: '海贸整饬案',
		proposals: [
			{ ...mockProposalItems[0].proposal, source_group: { ...merchants } },
			{ ...mockProposalItems[4].proposal, source_group: { ...workers } }
		],
		policies: [{ ...mockPolicies[0] }, mockPolicies[4]]
	},
	{
		title: '旧港遗案',
		proposals: [
			{ ...mockProposalItems[2].proposal, source_group: { ...farmers } },
			missingProposal
		],
		policies: [mockPolicies[1], stalePolicy]
	}
];

export const mockBillItems: BillLeftItem[] = mockSavedBills.map((bill, index) => ({
	kind: 'bill',
	ref: { collection: 'bills', index },
	bill
}));

export const mockConstitutionItems: ConstitutionLeftItem[] = [
	{
		kind: 'constitution',
		ref: { collection: 'constitutions', index: 0 },
		constitution: { title: '蓬莱约法', policies: [mockPolicies[0], mockPolicies[3]] }
	},
	{
		kind: 'constitution',
		ref: { collection: 'constitutions', index: 1 },
		constitution: { title: '港区补充约法', policies: [mockPolicies[2], mockPolicies[4]] }
	}
];

export const mockArchiveItems = [...mockConstitutionItems, ...mockBillItems];
export const mockLeftItems = [...mockArchiveItems, ...mockProposalItems, ...mockPolicyItems];

export const mockTopItems: TopItemData[] = [
	{
		key: 'penglai',
		item: { text: '蓬莱人', value: 46 },
		detail: {
			leftLabel: '人口',
			rightLabel: '诉求',
			leftBody: '港区多数居民，商业与工匠人口并居。',
			rightBody: '要求稳定物价，并保障商路不断。',
			actionLabel: '查看族群'
		},
		payload: 'penglai'
	},
	{
		key: 'guild',
		item: { text: '通商公所', value: 31 },
		detail: {
			leftLabel: '势力',
			rightLabel: '态度',
			leftBody: '控制主要码头与远洋商船。',
			rightBody: '支持降低税课与扩大商贸。',
			actionLabel: '联系公所'
		},
		payload: 'guild'
	},
	{
		key: 'workers',
		item: { text: '百工公所', value: 24 },
		detail: {
			leftLabel: '势力',
			rightLabel: '态度',
			leftBody: '组织城内工匠、雇工与作坊。',
			rightBody: '关注工钱和用工，反对突然停产。',
			actionLabel: '联系公所'
		},
		payload: 'workers'
	}
];

export const mockState: { primary: StateItem; secondary: StateItem } = {
	primary: { text: '民望', value: 68, limit: 100 },
	secondary: { text: '崩溃', value: 17, limit: 100 }
};

export const mockObjectDetail: ContextDetailData = {
	title: '世界地图',
	value: '港区',
	leftLabel: '概况',
	rightLabel: '行动',
	leftBody: '航路把各港口、产地和市场连接起来。',
	rightBody: '可以查看下一批可能抵达的货物。',
	actionLabel: '查看地图'
};

export const mockLegislatorDetail: ContextDetailData = {
	title: '商席议员',
	value: 12,
	limit: 20,
	leftLabel: '立场',
	rightLabel: '交涉',
	leftBody: '倾向支持商贸政策，但担忧物价上涨。',
	rightBody: '可用政治献金争取本次表决支持。',
	actionLabel: '进行交涉'
};

export const mockConstitution: MemorialConstitutionData = {
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
			policies: [
				{ policyTitle: '商', content: { title: '商船通行', body: '商船依统一税则通行。' } }
			]
		},
		{
			text: '工所',
			number: 35,
			selected: false,
			selectable: true,
			contents: [{ body: '工所推举代表陈述工匠事务。' }],
			policies: [{ policyTitle: '工', content: { body: '作坊雇工须登记于册。' } }]
		}
	],
	地方自治: 3,
	年度权限: 5
};

export const mockMergedProposal = makeProposal(
	makeGroup('联席公所'),
	{ tax: -5, price: -3, trade: 6 },
	{ trade: 9 },
	4
);

export function getMockBillPreview(bill: Bill): MemorialMetricData[] {
	const values: Record<Metric, string> = {
		[Metric.TAX]: '-12~-4',
		[Metric.PRICE]: '-8~3',
		[Metric.WAGE]: '-3~7',
		[Metric.EMPLOYMENT]: '-4~8',
		[Metric.TRADE]: '2~12'
	};
	return getBillMetrics(bill.proposals, bill.policies).map((metric) => ({
		text: METRIC_DISPLAY_NAMES[metric],
		value: values[metric]
	}));
}
