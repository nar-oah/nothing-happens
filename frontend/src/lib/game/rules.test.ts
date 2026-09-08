import assert from 'node:assert/strict';
import test from 'node:test';
import {
	arePoliciesGameplayEquivalent,
	areProposalsGameplayEquivalent,
	calculateDraftProjectedMetrics,
	calculatePolicyEffectAmount,
	calculatePureProposalTarget,
	clampBillPolicyDelays,
	getPolicyDelayBounds,
	reconcileSavedBill,
	reconcileSavedBillProposals
} from './rules.ts';
import {
	Metric,
	PolicyEffectFormula,
	type InterestGroupDefinition,
	type PolicyDefinition,
	type Proposal
} from './types.ts';

const sourceGroup: InterestGroupDefinition = {
	display_name: 'source',
	description: 'source description',
	base_column_weight: 1,
	decrease_tax: true,
	decrease_consumption: false,
	decrease_production: false,
	decrease_employment: false,
	decrease_investment: false
};

function makeProposal(): Proposal {
	return {
		source_group: sourceGroup,
		base_effect: { tax: 8, consumption: 0, production: 0, employment: 0, investment: 0 },
		positive_effect: { tax: 0, consumption: 0, production: 0, employment: 0, investment: 0 },
		lag_months: 4,
		donation_offer: 0,
		bonus_choice_resolved: true,
		positive_trait_accepted: true
	};
}

test('settled historical bonus fields do not affect future gameplay equivalence', () => {
	const ordinary = makeProposal();
	const converted = {
		...makeProposal(),
		donation_offer: 20,
		positive_trait_accepted: false
	};
	assert.equal(areProposalsGameplayEquivalent(ordinary, converted), true);
	const staleChoiceFlag = { ...makeProposal(), bonus_choice_resolved: false };
	assert.equal(areProposalsGameplayEquivalent(ordinary, staleChoiceFlag), true);
});

test('actionable bonus state remains part of gameplay equivalence', () => {
	const pending = makeProposal();
	pending.positive_effect.production = 5;
	pending.bonus_choice_resolved = false;
	pending.positive_trait_accepted = false;
	pending.donation_offer = 10;
	const differentOffer = {
		...pending,
		positive_effect: { ...pending.positive_effect },
		donation_offer: 11
	};
	assert.equal(areProposalsGameplayEquivalent(pending, differentOffer), false);

	const accepted = { ...pending, bonus_choice_resolved: true, positive_trait_accepted: true };
	const acceptedWithHistoricalOffer = { ...accepted, donation_offer: 99 };
	assert.equal(areProposalsGameplayEquivalent(accepted, acceptedWithHistoricalOffer), true);
});

test('source groups match by serialized display name', () => {
	const deserializedSourceGroup: InterestGroupDefinition = { ...sourceGroup };
	const savedProposal = makeProposal();
	const handProposal: Proposal = {
		...makeProposal(),
		source_group: deserializedSourceGroup
	};

	assert.notEqual(deserializedSourceGroup, sourceGroup);
	assert.equal(areProposalsGameplayEquivalent(savedProposal, handProposal), true);
	assert.deepEqual(reconcileSavedBillProposals([savedProposal], [handProposal]), [handProposal]);
});

test('saved proposal reconciliation consumes each hand object at most once', () => {
	const saved = [makeProposal(), makeProposal()];
	const replacement = makeProposal();
	const oneMatch = reconcileSavedBillProposals(saved, [replacement]);
	assert.deepEqual(oneMatch, [replacement, null]);

	const secondReplacement = makeProposal();
	const twoMatches = reconcileSavedBillProposals(saved, [replacement, secondReplacement]);
	assert.deepEqual(twoMatches, [replacement, secondReplacement]);
});

test('pure proposal target follows the same proposal effects used by the backend', () => {
	const proposal = makeProposal();
	proposal.base_effect.tax = -10;
	proposal.positive_effect.production = 7;
	proposal.positive_trait_accepted = true;
	assert.deepEqual(
		calculatePureProposalTarget(
			{ tax: 100, consumption: 100, production: 100, employment: 100, investment: 100 },
			[proposal]
		),
		{ tax: 90, consumption: 100, production: 107, employment: 100, investment: 100 }
	);
});

test('draft projected metrics begin with the pure proposal target', () => {
	const current = {
		tax: 100,
		consumption: 100,
		production: 100,
		employment: 100,
		investment: 100
	};
	const proposal = makeProposal();
	proposal.base_effect.tax = -12;
	assert.deepEqual(calculateDraftProjectedMetrics(current, [proposal], []), {
		...current,
		tax: 88
	});
});

test('policies at the same delay use one pre-batch metrics snapshot', () => {
	const current = {
		tax: 100,
		consumption: 100,
		production: 100,
		employment: 100,
		investment: 100
	};
	const raiseInvestment: PolicyDefinition = {
		display_name: '增加投资',
		effects: [
			{
				target_metric: Metric.INVESTMENT,
				formula: PolicyEffectFormula.METRIC_VALUE,
				source_a: Metric.TAX,
				source_b: Metric.TAX,
				multiplier: 0.1
			}
		]
	};
	const copyInvestmentGap: PolicyDefinition = {
		display_name: '投资传导',
		effects: [
			{
				target_metric: Metric.PRODUCTION,
				formula: PolicyEffectFormula.METRIC_GAP,
				source_a: Metric.INVESTMENT,
				source_b: Metric.TAX,
				multiplier: 1
			}
		]
	};

	assert.deepEqual(
		calculateDraftProjectedMetrics(current, [], [
			{ definition: raiseInvestment, delay_months: 2 },
			{ definition: copyInvestmentGap, delay_months: 2 }
		]),
		{ ...current, investment: 110 }
	);
	assert.deepEqual(
		calculateDraftProjectedMetrics(current, [], [
			{ definition: raiseInvestment, delay_months: 2 },
			{ definition: copyInvestmentGap, delay_months: 3 }
		]),
		{ ...current, production: 110, investment: 110 }
	);
});

test('draft projection matches the backend serialized preview fixture', () => {
	const current = {
		tax: 100,
		consumption: 100,
		production: 100,
		employment: 100,
		investment: 100
	};
	const proposal = makeProposal();
	proposal.base_effect = {
		tax: 7,
		consumption: 0,
		production: 0,
		employment: 0,
		investment: 0
	};
	const policy: PolicyDefinition = {
		display_name: '投资政策',
		effects: [
			{
				target_metric: Metric.INVESTMENT,
				formula: PolicyEffectFormula.METRIC_VALUE,
				source_a: Metric.TAX,
				source_b: Metric.TAX,
				multiplier: 0.1
			}
		]
	};
	const pure = calculatePureProposalTarget(current, [proposal]);
	const projected = calculateDraftProjectedMetrics(current, [proposal], [
		{ definition: policy, delay_months: 1 }
	]);
	assert.deepEqual(pure, { ...current, tax: 107 });
	assert.deepEqual(projected, { ...current, tax: 107, investment: 111 });
});

test('different policy delays chain in delay order regardless of bill array order', () => {
	const current = {
		tax: 100,
		consumption: 100,
		production: 100,
		employment: 100,
		investment: 100
	};
	const earlier: PolicyDefinition = {
		display_name: '先到期',
		effects: [
			{
				target_metric: Metric.INVESTMENT,
				formula: PolicyEffectFormula.METRIC_VALUE,
				source_a: Metric.TAX,
				source_b: Metric.TAX,
				multiplier: 0.1
			}
		]
	};
	const later: PolicyDefinition = {
		display_name: '后到期',
		effects: [
			{
				target_metric: Metric.PRODUCTION,
				formula: PolicyEffectFormula.METRIC_GAP,
				source_a: Metric.INVESTMENT,
				source_b: Metric.TAX,
				multiplier: 1
			}
		]
	};

	assert.deepEqual(
		calculateDraftProjectedMetrics(current, [], [
			{ definition: later, delay_months: 4 },
			{ definition: earlier, delay_months: 2 }
		]),
		{ ...current, production: 110, investment: 110 }
	);
});

test('draft policy batches preserve negative metric results', () => {
	const current = {
		tax: 10,
		consumption: 0,
		production: 4,
		employment: 0,
		investment: 0
	};
	const policy: PolicyDefinition = {
		display_name: '负值政策',
		effects: [
			{
				target_metric: Metric.PRODUCTION,
				formula: PolicyEffectFormula.METRIC_VALUE,
				source_a: Metric.TAX,
				source_b: Metric.TAX,
				multiplier: -1
			}
		]
	};
	assert.equal(
		calculateDraftProjectedMetrics(current, [], [{ definition: policy, delay_months: 0 }])
			.production,
		-6
	);
});

test('policy delay bounds use half the bill lag rounded up, including zero lag', () => {
	assert.deepEqual(getPolicyDelayBounds([]), { min: 0, max: 0 });
	assert.deepEqual(getPolicyDelayBounds([{ ...makeProposal(), lag_months: 1 }]), {
		min: 1,
		max: 1
	});
	assert.deepEqual(getPolicyDelayBounds([{ ...makeProposal(), lag_months: 5 }]), {
		min: 3,
		max: 5
	});
	assert.deepEqual(
		getPolicyDelayBounds([
			{ ...makeProposal(), lag_months: 2 },
			{ ...makeProposal(), lag_months: 8 }
		]),
		{ min: 4, max: 8 }
	);
});

test('policy delay clamping changes the bill instance without changing its definition', () => {
	const definition: PolicyDefinition = { display_name: '延期政策', effects: [] };
	const policies = [
		{ definition, delay_months: 1 },
		{ definition, delay_months: 9 }
	];
	const clamped = clampBillPolicyDelays(policies, [{ ...makeProposal(), lag_months: 5 }]);
	assert.deepEqual(
		clamped.map((policy) => policy.delay_months),
		[3, 5]
	);
	assert.equal(clamped[0].definition, definition);
	assert.deepEqual(definition, { display_name: '延期政策', effects: [] });
});

test('policy effects preserve negative signed results', () => {
	assert.equal(
		calculatePolicyEffectAmount(
			{
				target_metric: Metric.PRODUCTION,
				formula: PolicyEffectFormula.METRIC_GAP,
				source_a: Metric.INVESTMENT,
				source_b: Metric.TAX,
				multiplier: 0.5
			},
			{ tax: 100, consumption: 100, production: 100, employment: 100, investment: 80 }
		),
		-10
	);
});

test('saved bill reconciliation removes missing proposals and unavailable policies', () => {
	const availableProposal = makeProposal();
	const missingProposal = { ...makeProposal(), lag_months: 99 };
	const availablePolicy: PolicyDefinition = {
		display_name: '现行政策',
		effects: [
			{
				target_metric: Metric.INVESTMENT,
				formula: PolicyEffectFormula.METRIC_VALUE,
				source_a: Metric.TAX,
				source_b: Metric.TAX,
				multiplier: 0.1
			}
		]
	};
	const stalePolicy = { ...availablePolicy, display_name: '已失效政策' };
	const reconciled = reconcileSavedBill(
		{
			title: '旧法案',
			proposals: [availableProposal, missingProposal],
			policies: [
				{ definition: { ...availablePolicy }, delay_months: 9 },
				{ definition: stalePolicy, delay_months: 4 }
			]
		},
		[{ ...availableProposal, source_group: { ...availableProposal.source_group } }],
		[availablePolicy]
	);
	assert.equal(reconciled.proposals.length, 1);
	assert.deepEqual(reconciled.policies, [{ definition: availablePolicy, delay_months: 4 }]);
});

test('policy identity uses display_name only', () => {
	const first: PolicyDefinition = {
		display_name: '同名政策',
		effects: []
	};
	const second: PolicyDefinition = {
		display_name: '同名政策',
		effects: [
			{
				target_metric: Metric.EMPLOYMENT,
				formula: PolicyEffectFormula.METRIC_VALUE,
				source_a: Metric.INVESTMENT,
				source_b: Metric.TAX,
				multiplier: 0.5
			}
		]
	};
	assert.equal(arePoliciesGameplayEquivalent(first, second), true);
	assert.deepEqual(
		reconcileSavedBill(
			{
				title: '',
				proposals: [],
				policies: [{ definition: first, delay_months: 3 }]
			},
			[],
			[second]
		),
		{
			title: '',
			proposals: [],
			policies: [{ definition: second, delay_months: 0 }]
		}
	);
});
