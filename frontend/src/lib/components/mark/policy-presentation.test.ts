import assert from 'node:assert/strict';
import test from 'node:test';
import { Metric, MetricConditionOperator, PolicyEffectFormula, type PolicyDefinition } from '../../game/types.ts';
import { translate, type Translate } from '../../i18n/index.ts';
import { policyToMemorialContent } from '../memorial/presentation.ts';
import { createPolicyMarkContent } from './mark.ts';

const zh: Translate = (key, params) => translate(key, params, 'zh_CN');
const en: Translate = (key, params) => translate(key, params, 'en');

const policy: PolicyDefinition = {
	display_name: '测试政策',
	condition: {
		left_metric: Metric.PRODUCTION,
		operator: MetricConditionOperator.GREATER_THAN,
		right_metric: Metric.CONSUMPTION,
		right_multiplier: 1
	},
	effects: [
		{
			target_metric: Metric.PRODUCTION,
			formula: PolicyEffectFormula.METRIC_GAP,
			source_a: Metric.PRODUCTION,
			source_b: Metric.CONSUMPTION,
			multiplier: -0.5
		},
		{
			target_metric: Metric.TAX,
			formula: PolicyEffectFormula.METRIC_GAP,
			source_a: Metric.PRODUCTION,
			source_b: Metric.CONSUMPTION,
			multiplier: 1
		}
	]
};

const baseline = {
	tax: 100,
	consumption: 100,
	production: 150,
	employment: 100,
	investment: 100
};

test('policy mark faces show gap and stabilization effects instead of condition state', () => {
	assert.deepEqual(createPolicyMarkContent(policy, baseline, zh), {
		gap: { label: '落差', headline: '生産－25', detail: '（生産－消費）×0.5' },
		smoothing: { label: '平抑', headline: '税課＋50', detail: '生産－消費' }
	});
	assert.equal(createPolicyMarkContent(policy, baseline, en).smoothing.label, 'Stabilization');
});

test('vertical memorial policy content has fixed gap and stabilization blocks', () => {
	assert.deepEqual(policyToMemorialContent(policy, zh, zh), {
		policyTitle: '测试政策',
		contents: [
			{ title: '落差', body: '生産－（生産－消費）×0.5' },
			{ title: '平抑', body: '税課＋生産－消費' }
		]
	});
	assert.deepEqual(
		policyToMemorialContent(policy, en, en).contents.map((content) => content.title),
		['Gap', 'Stabilization']
	);
});
