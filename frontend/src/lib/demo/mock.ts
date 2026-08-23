import type { ContextDetailData } from '../components/detail/detail.ts';
import type {
	BillLeftItem,
	ConstitutionLeftItem,
	PolicyLeftItem,
	ProposalLeftItem
} from '../components/left/types.ts';
import { policyToMemorialContent } from '../components/memorial/presentation.ts';
import type { MemorialConstitutionData, MemorialMetricData } from '../components/memorial/types.ts';
import type { StateItem } from '../components/state/GameStateDisplay.svelte';
import type { TopItemData } from '../components/top/top.ts';
import {
	METRICS,
	METRIC_DISPLAY_NAMES,
	Metric,
	MetricConditionOperator,
	PolicyEffectFormula,
	getBillMetrics,
	getMetricValue,
	getProposalTotalEffect,
	type Bill,
	type Constitution,
	type InterestGroupDefinition,
	type MetricCondition,
	type MetricValues,
	type PolicyDefinition,
	type PolicyEffect,
	type Proposal
} from '../game/index.ts';

const vector = (values: Partial<MetricValues> = {}): MetricValues => ({
	tax: values.tax ?? 0,
	price: values.price ?? 0,
	wage: values.wage ?? 0,
	employment: values.employment ?? 0,
	trade: values.trade ?? 0
});

const makeGroup = (
	display_name: string,
	base_column_weight: number,
	decreases: Partial<Record<Metric, boolean>> = {}
): InterestGroupDefinition => ({
	display_name,
	base_column_weight,
	decrease_tax: decreases[Metric.TAX] ?? false,
	decrease_price: decreases[Metric.PRICE] ?? false,
	decrease_wage: decreases[Metric.WAGE] ?? false,
	decrease_employment: decreases[Metric.EMPLOYMENT] ?? false,
	decrease_trade: decreases[Metric.TRADE] ?? false
});

export const mockInterestGroups = {
	造身公所: makeGroup('造身公所', 5, {
		[Metric.PRICE]: true,
		[Metric.EMPLOYMENT]: true
	}),
	槐安公所: makeGroup('槐安公所', 5, {
		[Metric.WAGE]: true,
		[Metric.EMPLOYMENT]: true
	}),
	永乐轮运局: makeGroup('永乐轮运局', 5, {
		[Metric.EMPLOYMENT]: true,
		[Metric.TRADE]: true
	}),
	官药局: makeGroup('官药局', 2),
	铅字报馆: makeGroup('铅字报馆', 2, { [Metric.WAGE]: true }),
	会同成衣会: makeGroup('会同成衣会', 2, {
		[Metric.WAGE]: true,
		[Metric.TRADE]: true
	})
} satisfies Record<string, InterestGroupDefinition>;

const makeProposal = (
	source_group: InterestGroupDefinition,
	base_effect: Partial<MetricValues>,
	lag_months: number,
	positive_effect: Partial<MetricValues> = {}
): Proposal => {
	const positive = vector(positive_effect);
	const hasPositive = Object.values(positive).some((value) => value !== 0);
	return {
		source_group,
		base_effect: vector(base_effect),
		positive_effect: positive,
		lag_months,
		collapse_impact: 0,
		donation_offer: hasPositive ? 5 : 0,
		bonus_choice_resolved: true,
		positive_trait_accepted: hasPositive
	};
};

const condition = (
	left_metric: Metric,
	right_metric: Metric,
	operator = MetricConditionOperator.GREATER_THAN
): MetricCondition => ({
	left_metric,
	operator,
	right_metric,
	right_multiplier: 1
});

const effect = (
	target_metric: Metric,
	source_a: Metric,
	source_b: Metric,
	multiplier: number
): PolicyEffect => ({
	target_metric,
	formula: PolicyEffectFormula.METRIC_GAP,
	source_a,
	source_b,
	multiplier
});

const policy = (
	display_name: string,
	policyCondition: MetricCondition,
	effects: PolicyEffect[]
): PolicyDefinition => ({
	display_name,
	condition: policyCondition,
	effects
});

export const mockBaseline: MetricValues = {
	tax: 100,
	price: 100,
	wage: 100,
	employment: 100,
	trade: 100
};

export const mockPolicies: PolicyDefinition[] = [
	policy('勘合互市', condition(Metric.TRADE, Metric.TAX), [
		effect(Metric.PRICE, Metric.TRADE, Metric.TAX, -0.4),
		effect(Metric.TRADE, Metric.TRADE, Metric.TAX, -0.3)
	]),
	policy('岁贡折征', condition(Metric.TAX, Metric.TRADE), [
		effect(Metric.TAX, Metric.TAX, Metric.TRADE, -0.25),
		effect(Metric.TRADE, Metric.TAX, Metric.TRADE, 0.5)
	]),
	policy('港务调停', condition(Metric.PRICE, Metric.WAGE), [
		effect(Metric.PRICE, Metric.PRICE, Metric.WAGE, -0.35),
		effect(Metric.TRADE, Metric.PRICE, Metric.WAGE, -0.2)
	]),
	policy('集体议价', condition(Metric.TRADE, Metric.WAGE), [
		effect(Metric.TRADE, Metric.TRADE, Metric.WAGE, -0.3),
		effect(Metric.WAGE, Metric.TRADE, Metric.WAGE, 0.6)
	]),
	policy('轮班限制', condition(Metric.EMPLOYMENT, Metric.WAGE), [
		effect(Metric.EMPLOYMENT, Metric.EMPLOYMENT, Metric.WAGE, -0.35),
		effect(Metric.WAGE, Metric.EMPLOYMENT, Metric.WAGE, 0.5)
	]),
	policy('生活津贴', condition(Metric.PRICE, Metric.WAGE), [
		effect(Metric.WAGE, Metric.PRICE, Metric.WAGE, 0.4),
		effect(Metric.TAX, Metric.PRICE, Metric.WAGE, 0.25)
	])
];

const unavailablePolicy = policy('公开预算', condition(Metric.TAX, Metric.EMPLOYMENT), [
	effect(Metric.TAX, Metric.TAX, Metric.EMPLOYMENT, -0.4),
	effect(Metric.EMPLOYMENT, Metric.TAX, Metric.EMPLOYMENT, 0.6)
]);

export const mockProposalItems: ProposalLeftItem[] = [
	makeProposal(mockInterestGroups.造身公所, { price: 8, employment: -5 }, 6, { trade: 8 }),
	makeProposal(mockInterestGroups.造身公所, { price: 5, employment: -9 }, 3),
	makeProposal(mockInterestGroups.槐安公所, { wage: -6, price: 7 }, 4, { employment: 6 }),
	makeProposal(mockInterestGroups.槐安公所, { wage: -4, price: 10 }, 7),
	makeProposal(mockInterestGroups.永乐轮运局, { price: 6, trade: -8 }, 5, { tax: -5 }),
	makeProposal(mockInterestGroups.官药局, { tax: 7, price: 4 }, 2),
	makeProposal(mockInterestGroups.铅字报馆, { tax: 5, wage: -7 }, 4),
	makeProposal(mockInterestGroups.会同成衣会, { price: 6, wage: -5 }, 6)
].map((proposal, index) => ({
	kind: 'proposal',
	ref: { collection: 'proposals', index },
	proposal
}));

export const mockPolicyItems: PolicyLeftItem[] = mockPolicies.map((policyDefinition, index) => ({
	kind: 'policy',
	ref: { collection: 'policies', index },
	policy: policyDefinition
}));

const unavailableProposal: Proposal = {
	...mockProposalItems[0].proposal,
	base_effect: { ...mockProposalItems[0].proposal.base_effect },
	positive_effect: { ...mockProposalItems[0].proposal.positive_effect },
	lag_months: 99
};

export const mockSavedBills: Bill[] = [
	{
		title: '勘合互市',
		proposals: [mockProposalItems[0].proposal, mockProposalItems[3].proposal],
		policies: [mockPolicies[0], mockPolicies[2]]
	},
	{
		title: '集体议价',
		proposals: [mockProposalItems[2].proposal, unavailableProposal],
		policies: [mockPolicies[3], unavailablePolicy]
	}
];

export const mockBillItems: BillLeftItem[] = mockSavedBills.map((bill, index) => ({
	kind: 'bill',
	ref: { collection: 'bills', index },
	bill
}));

export const mockConstitution: Constitution = {
	title: '蓬莱约法',
	active_articles: [
		{
			display_name: '外藩',
			content: '',
			policies: mockPolicies.slice(0, 3)
		},
		{
			display_name: '工会',
			content: '',
			policies: mockPolicies.slice(3)
		}
	]
};

export const mockConstitutionItem: ConstitutionLeftItem = {
	kind: 'constitution',
	ref: { collection: 'constitution', index: 0 },
	constitution: mockConstitution
};

export const mockArchiveItems = [mockConstitutionItem, ...mockBillItems];
export const mockLeftItems = [...mockArchiveItems, ...mockProposalItems, ...mockPolicyItems];

const makeTopDetail = (leftLabel: string, leftBody = ''): Omit<ContextDetailData, 'title'> => ({
	leftLabel,
	rightLabel: '政治献金',
	leftBody,
	rightBody: ''
});

export const mockRaceTopItems: TopItemData[] = [
	{
		key: 'human',
		item: { text: '人类', value: -20 },
		detail: makeTopDetail(
			'-22',
			'明朝的特使，尽管内心极度恐惧，但还在尽力维持体面\n种族：-20\n利益集团：-2'
		)
	},
	{ key: 'biyi', item: { text: '比翼', value: 20 }, detail: makeTopDetail('20') },
	{ key: 'yano', item: { text: '偃偶', value: 20 }, detail: makeTopDetail('20') },
	{ key: 'peach', item: { text: '桃花妖', value: 20 }, detail: makeTopDetail('20') },
	{ key: 'nanke', item: { text: '南柯', value: 20 }, detail: makeTopDetail('20') },
	{ key: 'zhushui', item: { text: '驻岁', value: 99 }, detail: makeTopDetail('99') }
];

export const mockInterestGroupTopItems: TopItemData[] = Object.values(mockInterestGroups).map(
	(group) => ({
		key: group.display_name,
		item: { text: group.display_name, value: group.base_column_weight },
		detail: makeTopDetail(String(group.base_column_weight))
	})
);

export const mockState: { primary: StateItem; secondary: StateItem } = {
	primary: { text: '政治献金', value: 20, isRow: false },
	secondary: { text: '崩溃度', value: 20, limit: 24, isRow: false }
};

export const mockContextDetail: ContextDetailData = {
	title: '人类',
	leftLabel: '-22',
	rightLabel: '政治献金',
	leftBody: '明朝的特使，尽管内心极度恐惧，但还在尽力维持体面\n种族：-20\n利益集团：-2',
	rightBody: 'UI test：切换后正文变化。'
};

export const mockConstitutionMemorial: MemorialConstitutionData = {
	人类: [
		{
			text: mockConstitution.active_articles[0].display_name,
			number: '',
			selected: true,
			selectable: true,
			contents: [{ body: mockConstitution.active_articles[0].content }],
			policies: mockConstitution.active_articles[0].policies.map(policyToMemorialContent)
		}
	],
	南柯: [
		{
			text: mockConstitution.active_articles[1].display_name,
			number: '',
			selected: true,
			selectable: true,
			contents: [{ body: mockConstitution.active_articles[1].content }],
			policies: mockConstitution.active_articles[1].policies.map(policyToMemorialContent)
		}
	]
};

export function getMockBillPreview(bill: Bill): MemorialMetricData[] {
	const totals = bill.proposals.reduce((result, proposal) => {
		const proposalEffect = getProposalTotalEffect(proposal);
		for (const metric of METRICS) {
			const key = {
				[Metric.TAX]: 'tax',
				[Metric.PRICE]: 'price',
				[Metric.WAGE]: 'wage',
				[Metric.EMPLOYMENT]: 'employment',
				[Metric.TRADE]: 'trade'
			}[metric] as keyof MetricValues;
			result[key] += getMetricValue(proposalEffect, metric);
		}
		return result;
	}, vector());
	return getBillMetrics(bill.proposals, bill.policies).map((metric) => ({
		text: METRIC_DISPLAY_NAMES[metric],
		value: getMetricValue(totals, metric)
	}));
}
