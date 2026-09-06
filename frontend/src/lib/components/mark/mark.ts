import {
	getMetricDisplayName,
	MetricConditionOperator,
	PolicyEffectFormula,
	calculatePolicyEffectAmount,
	getMetricValue,
	isMetricConditionMet,
	type MetricValues,
	type PolicyDefinition,
	type PolicyEffect
} from '../../game/index.ts';
import { translate, type Translate } from '../../i18n/index.ts';

export const MARK_WIDTH = 230;
export const MARK_HEIGHT = 86;
export const MARK_SPLIT = 0.8;
export const MARK_RATIO = 20;
export const MARK_DEPTH_RATIO = MARK_RATIO / MARK_WIDTH;
export const MARK_SLANT_RATIO = MARK_RATIO / MARK_HEIGHT;
export const MARK_SEAL_SOURCE_SIZE = 80;

export type MarkDirection = 'up' | 'down';

export type MarkFaceContent = {
	headline: string;
	detail: string;
};

const CONDITION_SYMBOLS: Record<MetricConditionOperator, string> = {
	[MetricConditionOperator.LESS_THAN]: '＜',
	[MetricConditionOperator.LESS_THAN_OR_EQUAL]: '≤',
	[MetricConditionOperator.GREATER_THAN]: '＞',
	[MetricConditionOperator.GREATER_THAN_OR_EQUAL]: '≥'
};

export function createPolicyMarkContent(
	policy: PolicyDefinition,
	baseline: MetricValues,
	translator: Translate = translate
): { requirement: MarkFaceContent; effect: MarkFaceContent } {
	const condition = policy.condition;
	const symbol = CONDITION_SYMBOLS[condition.operator];
	const leftName = getMetricDisplayName(condition.left_metric, translator);
	const rightName = getMetricDisplayName(condition.right_metric, translator);
	const leftValue = getMetricValue(baseline, condition.left_metric);
	const rightValue = getMetricValue(baseline, condition.right_metric) * condition.right_multiplier;
	const multiplier = formatMultiplier(condition.right_multiplier);
	const triggerText = translator(isMetricConditionMet(condition, baseline) ? 'mark.triggered' : 'mark.notTriggered');
	const effectRules = policy.effects.map((effect) => formatEffectRule(effect, translator));
	const effectAmounts = policy.effects.map((effect) => {
		const amount = calculatePolicyEffectAmount(effect, baseline);
		return `${getMetricDisplayName(effect.target_metric, translator)}${formatSigned(amount)}`;
	});
	return {
		requirement: {
			headline: translator('mark.required', { condition: `${leftName}${symbol}${rightName}${multiplier}` }),
			detail: translator('mark.current', { condition: `${formatNumber(leftValue)}${symbol}${formatNumber(rightValue)}`, trigger: triggerText })
		},
		effect: {
			headline: translator('mark.effect', { effects: effectRules.length > 0 ? effectRules.join(translator('common.listSeparator')) : translator('mark.noEffects') }),
			detail: translator('mark.once', { effects: effectAmounts.length > 0 ? effectAmounts.join(translator('common.listSeparator')) : translator('mark.noChange') })
		}
	};
}

function formatEffectRule(effect: PolicyEffect, translator: Translate): string {
	const target = getMetricDisplayName(effect.target_metric, translator);
	const sourceA = getMetricDisplayName(effect.source_a, translator);
	const multiplier = formatMultiplier(effect.multiplier);
	if (effect.formula === PolicyEffectFormula.METRIC_VALUE) {
		return translator('mark.change', { target, source: sourceA, multiplier });
	}
	const sourceB = getMetricDisplayName(effect.source_b, translator);
	return translator('mark.change', { target, source: `（${sourceA}－${sourceB}）`, multiplier });
}

function formatMultiplier(multiplier: number): string {
	return multiplier === 1 ? '' : `×${formatNumber(multiplier)}`;
}

function formatSigned(value: number): string {
	return `${value >= 0 ? '＋' : '－'}${formatNumber(Math.abs(value))}`;
}

function formatNumber(value: number): string {
	return Number.isInteger(value) ? String(value) : String(Number(value.toFixed(4)));
}

function clamp(value: number, min: number, max: number): number {
	return Math.min(max, Math.max(min, value));
}

function matrix(a: number, b: number, c: number, d: number, e: number, f: number): string {
	return `matrix(${a}, ${b}, ${c}, ${d}, ${e}, ${f})`;
}

export function createMarkGeometry(direction: MarkDirection) {
	const width = Math.max(1, MARK_WIDTH);
	const height = Math.max(1, MARK_HEIGHT);
	const split = clamp(MARK_SPLIT, 0.05, 0.95);
	const depthRatio = clamp(MARK_DEPTH_RATIO, 0.001, 0.45);
	const slantRatio = clamp(MARK_SLANT_RATIO, 0, 0.45);

	const depth = width * depthRatio;
	const frontWidth = width - depth;
	const slant = height * slantRatio;
	const bodyHeight = height - slant;

	const largeHeight = bodyHeight * split;
	const smallHeight = bodyHeight - largeHeight;

	if (direction === 'up') {
		return {
			width,
			height,
			frontWidth,
			requirement: {
				height: largeHeight,
				transform: matrix(1, -slant / frontWidth, 0, 1, 0, slant)
			},
			effect: {
				height: smallHeight,
				transform: matrix(1, -slant / frontWidth, depth / smallHeight, 1, 0, slant + largeHeight)
			},
			sealTransform: matrix(
				depth / MARK_SEAL_SOURCE_SIZE,
				smallHeight / MARK_SEAL_SOURCE_SIZE,
				0,
				largeHeight / MARK_SEAL_SOURCE_SIZE,
				frontWidth,
				0
			)
		};
	}

	return {
		width,
		height,
		frontWidth,
		requirement: {
			height: smallHeight,
			transform: matrix(1, slant / frontWidth, -depth / smallHeight, 1, depth, 0)
		},
		effect: {
			height: largeHeight,
			transform: matrix(1, slant / frontWidth, 0, 1, 0, smallHeight)
		},
		sealTransform: matrix(
			depth / MARK_SEAL_SOURCE_SIZE,
			-smallHeight / MARK_SEAL_SOURCE_SIZE,
			0,
			largeHeight / MARK_SEAL_SOURCE_SIZE,
			frontWidth,
			slant + smallHeight
		)
	};
}
