import {
	METRIC_DISPLAY_NAMES,
	MetricConditionOperator,
	PolicyEffectFormula,
	calculatePolicyEffectAmount,
	getMetricValue,
	isMetricConditionMet,
	type MetricValues,
	type PolicyDefinition,
	type PolicyEffect
} from '$lib/game';

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
	baseline: MetricValues
): { requirement: MarkFaceContent; effect: MarkFaceContent } {
	const condition = policy.condition;
	const symbol = CONDITION_SYMBOLS[condition.operator];
	const leftName = METRIC_DISPLAY_NAMES[condition.left_metric];
	const rightName = METRIC_DISPLAY_NAMES[condition.right_metric];
	const leftValue = getMetricValue(baseline, condition.left_metric);
	const rightValue = getMetricValue(baseline, condition.right_metric) * condition.right_multiplier;
	const multiplier = formatMultiplier(condition.right_multiplier);
	const triggerText = isMetricConditionMet(condition, baseline) ? '本批觸發' : '本批不觸發';
	const effectRules = policy.effects.map(formatEffectRule);
	const effectAmounts = policy.effects.map((effect) => {
		const amount = calculatePolicyEffectAmount(effect, baseline);
		return `${METRIC_DISPLAY_NAMES[effect.target_metric]}${formatSigned(amount)}`;
	});
	if (policy.collapse_impact !== 0) {
		effectAmounts.push(`崩潰${formatSigned(policy.collapse_impact)}`);
	}
	return {
		requirement: {
			headline: `所需　${leftName}${symbol}${rightName}${multiplier}`,
			detail: `今數　${formatNumber(leftValue)}${symbol}${formatNumber(rightValue)}　${triggerText}`
		},
		effect: {
			headline: `效用　${effectRules.length > 0 ? effectRules.join('；') : '無指標效果'}`,
			detail: `單次　${effectAmounts.length > 0 ? effectAmounts.join('；') : '無變化'}`
		}
	};
}

function formatEffectRule(effect: PolicyEffect): string {
	const target = METRIC_DISPLAY_NAMES[effect.target_metric];
	const sourceA = METRIC_DISPLAY_NAMES[effect.source_a];
	const multiplier = formatMultiplier(effect.multiplier);
	if (effect.formula === PolicyEffectFormula.METRIC_VALUE) {
		return `${target}按${sourceA}${multiplier}變動`;
	}
	const sourceB = METRIC_DISPLAY_NAMES[effect.source_b];
	return `${target}按（${sourceA}－${sourceB}）${multiplier}變動`;
}

function formatMultiplier(multiplier: number): string {
	return multiplier === 1 ? '' : `×${formatNumber(multiplier)}`;
}

function formatSigned(value: number): string {
	return `${value >= 0 ? '＋' : '－'}${formatNumber(Math.abs(value))}`;
}

function formatNumber(value: number): string {
	return Number.isInteger(value) ? String(value) : String(Number(value.toFixed(2)));
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
