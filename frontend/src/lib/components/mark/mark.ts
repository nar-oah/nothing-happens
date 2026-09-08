import {
	PolicyEffectFormula,
	calculatePolicyEffectAmount,
	getMetricDisplayName,
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
	label: string;
	headline: string;
	detail: string;
};

export function createPolicyMarkContent(
	policy: PolicyDefinition,
	baseline: MetricValues,
	translator: Translate = translate
): { gap: MarkFaceContent; smoothing: MarkFaceContent } {
	return {
		gap: createEffectFace(policy.effects.slice(0, 1), baseline, translator('mark.gap'), translator),
		smoothing: createEffectFace(
			policy.effects.slice(1),
			baseline,
			translator('mark.smoothing'),
			translator
		)
	};
}

function createEffectFace(
	effects: PolicyEffect[],
	baseline: MetricValues,
	label: string,
	translator: Translate
): MarkFaceContent {
	if (effects.length === 0) {
		return { label, headline: translator('mark.noChange'), detail: translator('mark.noFormula') };
	}
	return {
		label,
		headline: effects
			.map((effect) => {
				const amount = calculatePolicyEffectAmount(effect, baseline);
				return `${getMetricDisplayName(effect.target_metric, translator)}${formatSigned(amount)}`;
			})
			.join('\n'),
		detail: effects.map((effect) => formatEffectSource(effect, translator)).join('\n')
	};
}

function formatEffectSource(effect: PolicyEffect, translator: Translate): string {
	const sourceA = getMetricDisplayName(effect.source_a, translator);
	const source =
		effect.formula === PolicyEffectFormula.METRIC_VALUE
			? sourceA
			: `${sourceA}－${getMetricDisplayName(effect.source_b, translator)}`;
	const multiplier = Math.abs(effect.multiplier);
	if (multiplier === 1) return source;
	const wrapped = effect.formula === PolicyEffectFormula.METRIC_GAP ? `（${source}）` : source;
	return `${wrapped}×${formatNumber(multiplier)}`;
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
			gap: {
				height: largeHeight,
				transform: matrix(1, -slant / frontWidth, 0, 1, 0, slant)
			},
			smoothing: {
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
		gap: {
			height: smallHeight,
			transform: matrix(1, slant / frontWidth, -depth / smallHeight, 1, depth, 0)
		},
		smoothing: {
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
