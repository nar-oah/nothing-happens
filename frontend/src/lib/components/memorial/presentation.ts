import {
	METRICS,
	METRIC_DISPLAY_NAMES,
	MetricConditionOperator,
	PolicyEffectFormula,
	getMetricValue,
	getProposalTotalEffect,
	type Bill,
	type Constitution,
	type PolicyDefinition,
	type Proposal
} from '../../game/index.ts';
import type { MemorialHorizontalContentData, MemorialPolicyContentData, MemorialProposalContentData } from './types';

const CONDITION_SYMBOLS: Record<MetricConditionOperator, string> = {
	[MetricConditionOperator.LESS_THAN]: '＜',
	[MetricConditionOperator.LESS_THAN_OR_EQUAL]: '≤',
	[MetricConditionOperator.GREATER_THAN]: '＞',
	[MetricConditionOperator.GREATER_THAN_OR_EQUAL]: '≥'
};

export function proposalToMemorialContent(proposal: Proposal): MemorialProposalContentData {
	return { proposalTitle: proposal.source_group.display_name, content: { title: '指标', body: formatVector(getProposalTotalEffect(proposal)) } };
}

export function proposalToHorizontalContents(proposal: Proposal): MemorialHorizontalContentData[] {
	return [
		{ title: proposal.source_group.display_name, body: '' },
		{ title: '指标', body: formatVector(getProposalTotalEffect(proposal)) },
		{ body: `如果你把该提案加入到法案中，${proposal.source_group.display_name}会很高兴。`, redacted: true }
	];
}

export function billToHorizontalContents(bill: Bill): MemorialHorizontalContentData[] {
	return [
		{ title: bill.title, body: '' },
		{ title: '提案', body: bill.proposals.map((proposal) => proposal.source_group.display_name).join('\n') },
		{ title: '政策', body: bill.policies.map((policy) => policy.display_name).join('\n') }
	];
}

export function constitutionToHorizontalContents(constitution: Constitution): MemorialHorizontalContentData[] {
	return [
		...constitution.active_articles.map((article) => ({ title: article.display_name, body: article.content })),
		{ body: '这是为了保证蓬莱岛的运转，各族妥协出的结果，尽管真正满意的人很少。', redacted: true }
	];
}

export function policyToMemorialContent(policy: PolicyDefinition): MemorialPolicyContentData {
	const condition = policy.condition;
	const multiplier = condition.right_multiplier === 1 ? '' : `×${condition.right_multiplier}`;
	const requirement = `${METRIC_DISPLAY_NAMES[condition.left_metric]}${CONDITION_SYMBOLS[condition.operator]}${METRIC_DISPLAY_NAMES[condition.right_metric]}${multiplier}`;
	const effects = policy.effects.map((effect) => {
		const source = effect.formula === PolicyEffectFormula.METRIC_VALUE ? METRIC_DISPLAY_NAMES[effect.source_a] : `${METRIC_DISPLAY_NAMES[effect.source_a]}－${METRIC_DISPLAY_NAMES[effect.source_b]}`;
		return `${METRIC_DISPLAY_NAMES[effect.target_metric]}按${source}×${effect.multiplier}变动`;
	});
	return { policyTitle: policy.display_name, content: { title: `条件：${requirement}`, body: effects.length ? effects.join('；') : '无指标效果' } };
}

function formatVector(values: Proposal['base_effect']): string {
	return METRICS.flatMap((metric) => {
		const value = getMetricValue(values, metric);
		return value === 0 ? [] : [`${METRIC_DISPLAY_NAMES[metric]} ${value > 0 ? '+' : '-'}${Math.abs(value)}`];
	}).join('\n');
}
