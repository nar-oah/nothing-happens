import assert from 'node:assert/strict';
import test from 'node:test';
import {
	arePoliciesGameplayEquivalent,
	areProposalsGameplayEquivalent,
	reconcileSavedBill,
	reconcileSavedBillProposals
} from './rules.ts';
import {
	Metric,
	MetricConditionOperator,
	PolicyEffectFormula,
	type InterestGroupDefinition,
	type PolicyDefinition,
	type Proposal
} from './types.ts';

type PolicyHasCollapseImpact = 'collapse_impact' extends keyof PolicyDefinition ? true : false;
type ProposalHasCollapseImpact = 'collapse_impact' extends keyof Proposal ? true : false;
const policyHasCollapseImpact: PolicyHasCollapseImpact = false;
const proposalHasCollapseImpact: ProposalHasCollapseImpact = false;

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
	pending.positive_effect.wage = 5;
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

test('saved bill reconciliation removes missing proposals and unavailable policies', () => {
	const availableProposal = makeProposal();
	const missingProposal = { ...makeProposal(), lag_months: 99 };
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
			proposals: [availableProposal, missingProposal],
			policies: [{ ...availablePolicy }, stalePolicy]
		},
		[{ ...availableProposal, source_group: { ...availableProposal.source_group } }],
		[availablePolicy]
	);
	assert.equal(reconciled.proposals.length, 1);
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
		reconcileSavedBill({ title: '', proposals: [], policies: [first] }, [], [second]),
		{
			title: '',
			proposals: [],
			policies: [second]
		}
	);
});

test('Proposal and PolicyDefinition have no collapse_impact field', () => {
	assert.equal(proposalHasCollapseImpact, false);
	assert.equal(policyHasCollapseImpact, false);
});
