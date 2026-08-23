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
	Metric.PRICE,
	Metric.WAGE,
	Metric.EMPLOYMENT,
	Metric.TRADE
];

const METRIC_KEYS: Record<Metric, keyof MetricValues> = {
	[Metric.TAX]: 'tax',
	[Metric.PRICE]: 'price',
	[Metric.WAGE]: 'wage',
	[Metric.EMPLOYMENT]: 'employment',
	[Metric.TRADE]: 'trade'
};

export const METRIC_DISPLAY_NAMES: Record<Metric, string> = {
	[Metric.TAX]: '税課',
	[Metric.PRICE]: '物價',
	[Metric.WAGE]: '工錢',
	[Metric.EMPLOYMENT]: '用工',
	[Metric.TRADE]: '商貿'
};

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

export function arePoliciesGameplayEquivalent(
	first: PolicyDefinition,
	second: PolicyDefinition
): boolean {
	return first.display_name === second.display_name;
}

export function reconcileSavedBill(savedBill: Bill, availablePolicies: PolicyDefinition[]): Bill {
	const policies = savedBill.policies.flatMap((savedPolicy) => {
		const available = availablePolicies.find((policy) =>
			arePoliciesGameplayEquivalent(savedPolicy, policy)
		);
		return available ? [available] : [];
	});
	return { title: savedBill.title, proposals: savedBill.proposals, policies };
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

function addVectorMetrics(involved: Set<Metric>, values: MetricValues): void {
	for (const metric of METRICS) {
		if (getMetricValue(values, metric) !== 0) involved.add(metric);
	}
}

function roundLikeGodot(value: number): number {
	return Math.sign(value) * Math.floor(Math.abs(value) + 0.5);
}
