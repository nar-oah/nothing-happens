import assert from 'node:assert/strict';
import test from 'node:test';
import { arePoliciesGameplayEquivalent, reconcileSavedBill } from './rules.ts';
import {
	Metric,
	MetricConditionOperator,
	PolicyEffectFormula,
	type InterestGroupDefinition,
	type PolicyDefinition,
	type Proposal
} from './types.ts';

type PolicyHasCollapseImpact = 'collapse_impact' extends keyof PolicyDefinition ? true : false;
const policyHasCollapseImpact: PolicyHasCollapseImpact = false;

const sourceGroup: InterestGroupDefinition = {
	display_name: 'source',
	base_column_weight: 1,
	decrease_tax: true,
	decrease_price: false,
	decrease_wage: false,
	decrease_employment: false,
	decrease_trade: false
};

function makeProposal(): Proposal {
	return {
		source_group: sourceGroup,
		base_effect: { tax: 8, price: 0, wage: 0, employment: 0, trade: 0 },
		positive_effect: { tax: 0, price: 0, wage: 0, employment: 0, trade: 0 },
		lag_months: 4,
		collapse_impact: 2,
		donation_offer: 0,
		bonus_choice_resolved: true,
		positive_trait_accepted: true
	};
}

test('saved bill reconciliation preserves proposals and removes unavailable policies', () => {
	const firstProposal = makeProposal();
	const secondProposal = { ...makeProposal(), lag_months: 99 };
	const availablePolicy: PolicyDefinition = {
		display_name: '现行政策',
		condition: {
			left_metric: Metric.TAX,
			operator: MetricConditionOperator.LESS_THAN,
			right_metric: Metric.TRADE,
			right_multiplier: 1
		},
		effects: [
			{
				target_metric: Metric.TRADE,
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
			proposals: [firstProposal, secondProposal],
			policies: [{ ...availablePolicy }, stalePolicy]
		},
		[availablePolicy]
	);
	assert.deepEqual(reconciled.proposals, [firstProposal, secondProposal]);
	assert.deepEqual(reconciled.policies, [availablePolicy]);
});

test('policy identity uses display_name only', () => {
	const first: PolicyDefinition = {
		display_name: '同名政策',
		condition: {
			left_metric: Metric.TAX,
			operator: MetricConditionOperator.LESS_THAN,
			right_metric: Metric.TRADE,
			right_multiplier: 1
		},
		effects: []
	};
	const second: PolicyDefinition = {
		display_name: '同名政策',
		condition: {
			left_metric: Metric.WAGE,
			operator: MetricConditionOperator.GREATER_THAN,
			right_metric: Metric.PRICE,
			right_multiplier: 2
		},
		effects: [
			{
				target_metric: Metric.EMPLOYMENT,
				formula: PolicyEffectFormula.METRIC_VALUE,
				source_a: Metric.TRADE,
				source_b: Metric.TAX,
				multiplier: 0.5
			}
		]
	};
	assert.equal(arePoliciesGameplayEquivalent(first, second), true);
	assert.deepEqual(
		reconcileSavedBill({ title: '', proposals: [], policies: [first] }, [second]),
		{
			title: '',
			proposals: [],
			policies: [second]
		}
	);
});

test('PolicyDefinition has no collapse_impact field', () => {
	assert.equal(policyHasCollapseImpact, false);
});
