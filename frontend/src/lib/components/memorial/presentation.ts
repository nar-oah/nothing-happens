import {
	METRICS,
	getMetricDisplayName,
	MetricConditionOperator,
	PolicyEffectFormula,
	getMetricValue,
	getProposalTotalEffect,
	type Bill,
	type Constitution,
	type PolicyDefinition,
	type Proposal
} from '../../game/index.ts';
import { translate, type Translate } from '../../i18n/index.ts';
import type {
	MemorialHorizontalContentData,
	MemorialPolicyContentData,
	MemorialProposalContentData
} from './types';

const CONDITION_SYMBOLS: Record<MetricConditionOperator, string> = {
	[MetricConditionOperator.LESS_THAN]: '＜',
	[MetricConditionOperator.LESS_THAN_OR_EQUAL]: '≤',
	[MetricConditionOperator.GREATER_THAN]: '＞',
	[MetricConditionOperator.GREATER_THAN_OR_EQUAL]: '≥'
};

export function proposalToMemorialContent(
	proposal: Proposal,
	translator: Translate = translate,
	metricTranslator: Translate = translator
): MemorialProposalContentData {
	return {
		proposalTitle: proposal.source_group.display_name,
		content: {
			title: translator('memorial.metrics'),
			body: formatVector(getProposalTotalEffect(proposal), metricTranslator)
		}
	};
}

export function proposalToHorizontalContents(
	proposal: Proposal,
	translator: Translate = translate
): MemorialHorizontalContentData[] {
	return [
		{ title: proposal.source_group.display_name, body: proposal.source_group.description },
		{
			title: translator('memorial.metrics'),
			body: formatVector(getProposalTotalEffect(proposal), translator)
		},
		{
			body: translator('memorial.groupHappy', { group: proposal.source_group.display_name }),
			redacted: true
		}
	];
}

export function billToHorizontalContents(
	bill: Bill,
	translator: Translate = translate
): MemorialHorizontalContentData[] {
	return [
		{ title: bill.title, body: '' },
		{
			title: translator('archive.proposal'),
			body: bill.proposals.map((proposal) => proposal.source_group.display_name).join('\n')
		},
		{
			title: translator('archive.policy'),
			body: bill.policies.map((policy) => policy.display_name).join('\n')
		}
	];
}

export function constitutionToHorizontalContents(
	constitution: Constitution,
	translator: Translate = translate
): MemorialHorizontalContentData[] {
	return [
		...constitution.active_articles.map((article) => ({
			title: article.display_name,
			body: article.content
		})),
		{ body: translator('memorial.compromise'), redacted: true }
	];
}

export function policyToMemorialContent(
	policy: PolicyDefinition,
	translator: Translate = translate,
	metricTranslator: Translate = translator
): MemorialPolicyContentData {
	const condition = policy.condition;
	const multiplier = condition.right_multiplier === 1 ? '' : `×${condition.right_multiplier}`;
	const requirement = `${getMetricDisplayName(condition.left_metric, metricTranslator)}${CONDITION_SYMBOLS[condition.operator]}${getMetricDisplayName(condition.right_metric, metricTranslator)}${multiplier}`;
	const effects = policy.effects.map((effect) => {
		const source =
			effect.formula === PolicyEffectFormula.METRIC_VALUE
				? getMetricDisplayName(effect.source_a, metricTranslator)
				: `${getMetricDisplayName(effect.source_a, metricTranslator)}－${getMetricDisplayName(effect.source_b, metricTranslator)}`;
		return translator('memorial.effect', {
			target: getMetricDisplayName(effect.target_metric, metricTranslator),
			source,
			multiplier: effect.multiplier
		});
	});
	return {
		policyTitle: policy.display_name,
		content: {
			title: translator('memorial.condition', { requirement }),
			body: effects.length
				? effects.join(translator('memorial.effectSeparator'))
				: translator('memorial.noEffects')
		}
	};
}

function formatVector(values: Proposal['base_effect'], translator: Translate): string {
	return METRICS.flatMap((metric) => {
		const value = getMetricValue(values, metric);
		return value === 0
			? []
			: [`${getMetricDisplayName(metric, translator)} ${value > 0 ? '+' : '-'}${Math.abs(value)}`];
	}).join('\n');
}
