import assert from 'node:assert/strict';
import test from 'node:test';
import {
	calculateDraftProjectedMetrics,
	calculatePureProposalTarget,
	clampBillPolicyDelays,
	getPolicyDelayBounds,
	reconcileSavedBill
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

function makeProposal(lagMonths = 4): Proposal {
	return {
		source_group: sourceGroup,
		base_effect: { tax: -10, consumption: 0, production: 0, employment: 0, investment: 0 },
		positive_effect: { tax: 0, consumption: 0, production: 7, employment: 0, investment: 0 },
		lag_months: lagMonths,
		donation_offer: 0,
		bonus_choice_resolved: true,
		positive_trait_accepted: true
	};
}

test('proposal target keeps the backend-facing signed metric semantics', () => {
	assert.deepEqual(
		calculatePureProposalTarget(
			{ tax: 100, consumption: 100, production: 100, employment: 100, investment: 100 },
			[makeProposal()]
		),
		{ tax: 90, consumption: 100, production: 107, employment: 100, investment: 100 }
	);
});

test('policy projection batches equal delays and chains different delays', () => {
	const current = { tax: 100, consumption: 100, production: 100, employment: 100, investment: 100 };
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
	const copyGap: PolicyDefinition = {
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
			{ definition: copyGap, delay_months: 2 }
		]),
		{ ...current, investment: 110 }
	);
	assert.deepEqual(
		calculateDraftProjectedMetrics(current, [], [
			{ definition: copyGap, delay_months: 3 },
			{ definition: raiseInvestment, delay_months: 2 }
		]),
		{ ...current, production: 110, investment: 110 }
	);
});

test('policy delays use bill lag bounds and clamp per bill instance', () => {
	const proposal = makeProposal(5);
	assert.deepEqual(getPolicyDelayBounds([proposal]), { min: 3, max: 5 });
	const definition: PolicyDefinition = { display_name: '延期政策', effects: [] };
	const clamped = clampBillPolicyDelays(
		[
			{ definition, delay_months: 1 },
			{ definition, delay_months: 9 }
		],
		[proposal]
	);
	assert.deepEqual(
		clamped.map((policy) => policy.delay_months),
		[3, 5]
	);
	assert.equal(clamped[0].definition, definition);
});

test('saved bills drop missing proposals and unavailable policies', () => {
	const availableProposal = makeProposal();
	const availablePolicy: PolicyDefinition = { display_name: '现行政策', effects: [] };
	const reconciled = reconcileSavedBill(
		{
			title: '旧法案',
			proposals: [availableProposal, makeProposal(99)],
			policies: [
				{ definition: { ...availablePolicy }, delay_months: 9 },
				{ definition: { display_name: '已失效政策', effects: [] }, delay_months: 4 }
			]
		},
		[{ ...availableProposal, source_group: { ...availableProposal.source_group } }],
		[availablePolicy]
	);
	assert.equal(reconciled.proposals.length, 1);
	assert.deepEqual(reconciled.policies, [{ definition: availablePolicy, delay_months: 4 }]);
});
