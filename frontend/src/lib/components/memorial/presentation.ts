import {
	METRICS,
	METRIC_DISPLAY_NAMES,
	MetricConditionOperator,
	PolicyEffectFormula,
	getMetricValue,
	type PolicyDefinition,
	type Proposal
} from '../../game/index.ts';
import type { MemorialPolicyContentData, MemorialProposalContentData } from './types';

const CONDITION_SYMBOLS: Record<MetricConditionOperator, string> = {
	[MetricConditionOperator.LESS_THAN]: '＜',
	[MetricConditionOperator.LESS_THAN_OR_EQUAL]: '≤',
	[MetricConditionOperator.GREATER_THAN]: '＞',
	[MetricConditionOperator.GREATER_THAN_OR_EQUAL]: '≥'
};

export function proposalToMemorialContent(proposal: Proposal): MemorialProposalContentData {
	const base = formatVector(proposal.base_effect);
	const positive = formatVector(proposal.positive_effect);
	return {
		proposalTitle: proposal.source_group.display_name,
		content: {
			title: '提案效用',
			body: [base || '无普通指标变化', positive ? `附加：${positive}` : '无附加项'].join('。')
		}
	};
}

export function policyToMemorialContent(policy: PolicyDefinition): MemorialPolicyContentData {
	const condition = policy.condition;
	const multiplier = condition.right_multiplier === 1 ? '' : `×${condition.right_multiplier}`;
	const requirement = `${METRIC_DISPLAY_NAMES[condition.left_metric]}${CONDITION_SYMBOLS[condition.operator]}${METRIC_DISPLAY_NAMES[condition.right_metric]}${multiplier}`;
	const effects = policy.effects.map((effect) => {
		const source =
			effect.formula === PolicyEffectFormula.METRIC_VALUE
				? METRIC_DISPLAY_NAMES[effect.source_a]
				: `${METRIC_DISPLAY_NAMES[effect.source_a]}－${METRIC_DISPLAY_NAMES[effect.source_b]}`;
		return `${METRIC_DISPLAY_NAMES[effect.target_metric]}按${source}×${effect.multiplier}变动`;
	});
	return {
		policyTitle: policy.display_name,
		content: {
			title: `条件：${requirement}`,
			body: effects.length ? effects.join('；') : '无指标效果'
		}
	};
}

function formatVector(values: Proposal['base_effect']): string {
	return METRICS.flatMap((metric) => {
		const value = getMetricValue(values, metric);
		return value === 0
			? []
			: [`${METRIC_DISPLAY_NAMES[metric]}${value > 0 ? '＋' : '－'}${Math.abs(value)}`];
	}).join('；');
}
