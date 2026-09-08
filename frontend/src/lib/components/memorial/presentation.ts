import {
	METRICS,
	getMetricDisplayName,
	PolicyEffectFormula,
	getMetricValue,
	getProposalTotalEffect,
	type Bill,
	type Constitution,
	type PolicyDefinition,
	type PolicyEffect,
	type Proposal
} from '../../game/index.ts';
import { translate, type Translate } from '../../i18n/index.ts';
import type {
	MemorialHorizontalContentData,
	MemorialPolicyContentData,
	MemorialProposalContentData
} from './types';

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
	return {
		policyTitle: policy.display_name,
		contents: [
			{
				title: translator('memorial.gap'),
				body: formatPolicyEffect(policy.effects[0], translator, metricTranslator)
			},
			{
				title: translator('memorial.smoothing'),
				body: formatPolicyEffect(policy.effects[1], translator, metricTranslator)
			}
		]
	};
}

function formatPolicyEffect(
	effect: PolicyEffect | undefined,
	translator: Translate,
	metricTranslator: Translate
): string {
	if (!effect) return translator('memorial.noEffects');
	const target = getMetricDisplayName(effect.target_metric, metricTranslator);
	const sourceA = getMetricDisplayName(effect.source_a, metricTranslator);
	const source =
		effect.formula === PolicyEffectFormula.METRIC_VALUE
			? sourceA
			: `${sourceA}－${getMetricDisplayName(effect.source_b, metricTranslator)}`;
	const multiplier = Math.abs(effect.multiplier);
	const wrapped =
		effect.formula === PolicyEffectFormula.METRIC_GAP && multiplier !== 1 ? `（${source}）` : source;
	const formula = multiplier === 1 ? wrapped : `${wrapped}×${formatNumber(multiplier)}`;
	return `${target}${effect.multiplier >= 0 ? '＋' : '－'}${formula}`;
}

function formatNumber(value: number): string {
	return Number.isInteger(value) ? String(value) : String(Number(value.toFixed(4)));
}

function formatVector(values: Proposal['base_effect'], translator: Translate): string {
	return METRICS.flatMap((metric) => {
		const value = getMetricValue(values, metric);
		return value === 0
			? []
			: [`${getMetricDisplayName(metric, translator)} ${value > 0 ? '+' : '-'}${Math.abs(value)}`];
	}).join('\n');
}
