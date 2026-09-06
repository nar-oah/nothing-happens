import { translate, type Translate } from '../i18n/index.ts';
import {
	Metric,
	MetricConditionOperator,
	PolicyEffectFormula,
	type MetricCondition,
	type MetricValues,
	type MetricVector,
	type Bill,
	type PolicyDefinition,
	type PolicyEffect,
	type Proposal
} from './types.ts';

export const METRICS: Metric[] = [
	Metric.TAX,
	Metric.CONSUMPTION,
	Metric.PRODUCTION,
	Metric.EMPLOYMENT,
	Metric.INVESTMENT
];

const METRIC_KEYS: Record<Metric, keyof MetricValues> = {
	[Metric.TAX]: 'tax',
	[Metric.CONSUMPTION]: 'consumption',
	[Metric.PRODUCTION]: 'production',
	[Metric.EMPLOYMENT]: 'employment',
	[Metric.INVESTMENT]: 'investment'
};

export const METRIC_DISPLAY_NAMES: Record<Metric, string> = {
	[Metric.TAX]: translate('game.metric.tax', undefined, 'zh_CN'),
	[Metric.CONSUMPTION]: translate('game.metric.consumption', undefined, 'zh_CN'),
	[Metric.PRODUCTION]: translate('game.metric.production', undefined, 'zh_CN'),
	[Metric.EMPLOYMENT]: translate('game.metric.employment', undefined, 'zh_CN'),
	[Metric.INVESTMENT]: translate('game.metric.investment', undefined, 'zh_CN')
};

export function getMetricDisplayName(metric: Metric, translator: Translate = translate): string {
	return translator(`game.metric.${METRIC_KEYS[metric]}`);
}

export function getMetricValue(values: MetricValues, metric: Metric): number {
	return values[METRIC_KEYS[metric]];
}

export function isMetricConditionMet(condition: MetricCondition, values: MetricValues): boolean {
	const left = getMetricValue(values, condition.left_metric);
	const right = getMetricValue(values, condition.right_metric) * condition.right_multiplier;
	switch (condition.operator) {
		case MetricConditionOperator.LESS_THAN:
			return left < right;
		case MetricConditionOperator.LESS_THAN_OR_EQUAL:
			return left <= right;
		case MetricConditionOperator.GREATER_THAN:
			return left > right;
		case MetricConditionOperator.GREATER_THAN_OR_EQUAL:
			return left >= right;
	}
}

export function calculatePolicyEffectAmount(effect: PolicyEffect, values: MetricValues): number {
	const raw =
		effect.formula === PolicyEffectFormula.METRIC_VALUE
			? getMetricValue(values, effect.source_a)
			: getMetricValue(values, effect.source_a) - getMetricValue(values, effect.source_b);
	return roundLikeGodot(raw * effect.multiplier);
}

export function hasPositiveTrait(proposal: Proposal): boolean {
	return METRICS.some((metric) => getMetricValue(proposal.positive_effect, metric) !== 0);
}

export function isProposalBonusChoicePending(proposal: Proposal): boolean {
	return hasPositiveTrait(proposal) && !proposal.bonus_choice_resolved;
}

export function areProposalsGameplayEquivalent(first: Proposal, second: Proposal): boolean {
	if (
		first.source_group.display_name !== second.source_group.display_name ||
		!areMetricVectorsEqual(first.base_effect, second.base_effect) ||
		first.lag_months !== second.lag_months
	) {
		return false;
	}
	const firstHasPositive = hasPositiveTrait(first);
	if (firstHasPositive !== hasPositiveTrait(second)) return false;
	if (!firstHasPositive) return true;
	if (!areMetricVectorsEqual(first.positive_effect, second.positive_effect)) return false;
	const firstPending = isProposalBonusChoicePending(first);
	if (firstPending !== isProposalBonusChoicePending(second)) return false;
	if (firstPending) return isApproximatelyEqual(first.donation_offer, second.donation_offer);
	return first.positive_trait_accepted === second.positive_trait_accepted;
}

export function reconcileSavedBillProposals(
	savedProposals: Proposal[],
	hand: Proposal[]
): Array<Proposal | null> {
	const used = new Set<Proposal>();
	return savedProposals.map((savedProposal) => {
		const matched = hand.find(
			(candidate) =>
				!used.has(candidate) && areProposalsGameplayEquivalent(savedProposal, candidate)
		);
		if (!matched) return null;
		used.add(matched);
		return matched;
	});
}

export function arePoliciesGameplayEquivalent(
	first: PolicyDefinition,
	second: PolicyDefinition
): boolean {
	return first.display_name === second.display_name;
}

export function reconcileSavedBill(
	savedBill: Bill,
	hand: Proposal[],
	availablePolicies: PolicyDefinition[]
): Bill {
	const proposals = reconcileSavedBillProposals(savedBill.proposals, hand).filter(
		(proposal): proposal is Proposal => proposal !== null
	);
	const policies = savedBill.policies.flatMap((savedPolicy) => {
		const available = availablePolicies.find((policy) =>
			arePoliciesGameplayEquivalent(savedPolicy, policy)
		);
		return available ? [available] : [];
	});
	return { title: savedBill.title, proposals, policies };
}

export function getProposalTotalEffect(proposal: Proposal): MetricVector {
	const result: MetricVector = { ...proposal.base_effect };
	if (!proposal.positive_trait_accepted) return result;
	for (const metric of METRICS) {
		const key = METRIC_KEYS[metric];
		result[key] += getMetricValue(proposal.positive_effect, metric);
	}
	return result;
}

export function calculatePureProposalTarget(
	current: MetricValues,
	proposals: Proposal[]
): MetricValues {
	const result: MetricValues = { ...current };
	for (const proposal of proposals) {
		const effect = getProposalTotalEffect(proposal);
		for (const metric of METRICS) {
			const key = METRIC_KEYS[metric];
			result[key] += getMetricValue(effect, metric);
		}
	}
	return result;
}

export function calculateDraftProjectedMetrics(
	current: MetricValues,
	proposals: Proposal[],
	policies: PolicyDefinition[]
): MetricValues {
	const pureTarget = calculatePureProposalTarget(current, proposals);
	const triggered = new Set<number>();
	const immediate = resolvePolicyChain(current, policies, triggered);
	const projected: MetricValues = { ...pureTarget };
	for (const metric of METRICS) {
		const key = METRIC_KEYS[metric];
		projected[key] += getMetricValue(immediate, metric) - getMetricValue(current, metric);
	}
	return resolvePolicyChain(projected, policies, triggered);
}

export function getBillLagMonths(proposals: Proposal[]): number {
	return proposals.reduce((maximum, proposal) => Math.max(maximum, proposal.lag_months), 0);
}

export function getBillMetrics(proposals: Proposal[], policies: PolicyDefinition[]): Metric[] {
	const involved = new Set<Metric>();
	for (const proposal of proposals) {
		addVectorMetrics(involved, proposal.base_effect);
		if (proposal.positive_trait_accepted) addVectorMetrics(involved, proposal.positive_effect);
	}
	for (const policy of policies) getPolicyMetrics(policy).forEach((metric) => involved.add(metric));
	return METRICS.filter((metric) => involved.has(metric));
}

export function getPolicyMetrics(policy: PolicyDefinition): Metric[] {
	const involved = new Set<Metric>([policy.condition.left_metric, policy.condition.right_metric]);
	for (const effect of policy.effects) {
		involved.add(effect.target_metric);
		involved.add(effect.source_a);
		if (effect.formula === PolicyEffectFormula.METRIC_GAP) involved.add(effect.source_b);
	}
	return METRICS.filter((metric) => involved.has(metric));
}

function resolvePolicyChain(
	start: MetricValues,
	policies: PolicyDefinition[],
	triggered: Set<number>
): MetricValues {
	const result: MetricValues = { ...start };
	while (true) {
		const batch = policies.flatMap((policy, index) =>
			!triggered.has(index) && isMetricConditionMet(policy.condition, result)
				? [{ policy, index }]
				: []
		);
		if (batch.length === 0) return result;
		const snapshot: MetricValues = { ...result };
		const delta: MetricVector = {
			tax: 0,
			consumption: 0,
			production: 0,
			employment: 0,
			investment: 0
		};
		for (const { policy, index } of batch) {
			triggered.add(index);
			for (const effect of policy.effects) {
				const key = METRIC_KEYS[effect.target_metric];
				delta[key] += calculatePolicyEffectAmount(effect, snapshot);
			}
		}
		for (const metric of METRICS) {
			const key = METRIC_KEYS[metric];
			result[key] += getMetricValue(delta, metric);
		}
	}
}

function addVectorMetrics(involved: Set<Metric>, values: MetricValues): void {
	for (const metric of METRICS) {
		if (getMetricValue(values, metric) !== 0) involved.add(metric);
	}
}

function areMetricVectorsEqual(first: MetricValues, second: MetricValues): boolean {
	return METRICS.every(
		(metric) => getMetricValue(first, metric) === getMetricValue(second, metric)
	);
}

function isApproximatelyEqual(first: number, second: number): boolean {
	if (first === second) return true;
	const tolerance = Math.max(0.00001, 0.00001 * Math.abs(first));
	return Math.abs(first - second) < tolerance;
}

function roundLikeGodot(value: number): number {
	return Math.sign(value) * Math.floor(Math.abs(value) + 0.5);
}
