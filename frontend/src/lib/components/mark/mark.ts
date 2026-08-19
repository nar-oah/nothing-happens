export const MARK_WIDTH = 230;
export const MARK_HEIGHT = 86;
export const MARK_SPLIT = 0.8;
export const MARK_RATIO = 20;
export const MARK_DEPTH_RATIO = MARK_RATIO / MARK_WIDTH;
export const MARK_SLANT_RATIO = MARK_RATIO / MARK_HEIGHT;
export const MARK_SEAL_SOURCE_SIZE = 80;

export type MarkDirection = 'up' | 'down';
export type MarkFaceKind = 'requirement' | 'effect';

export type MarkFaceContent = {
	headline: string;
	detail: string;
};

export type MarkGeometry = {
	width: number;
	height: number;
	frontWidth: number;
	depth: number;
	slant: number;
	bodyHeight: number;
	largeHeight: number;
	smallHeight: number;
	requirementHeight: number;
	effectHeight: number;
	requirementTransform: string;
	effectTransform: string;
	sealTransform: string;
};

function clamp(value: number, min: number, max: number): number {
	return Math.min(max, Math.max(min, value));
}

function matrix(a: number, b: number, c: number, d: number, e: number, f: number): string {
	return `matrix(${a}, ${b}, ${c}, ${d}, ${e}, ${f})`;
}

export function createMarkGeometry(
	direction: MarkDirection,
	width = MARK_WIDTH,
	height = MARK_HEIGHT,
	split = MARK_SPLIT,
	depthRatio = MARK_DEPTH_RATIO,
	slantRatio = MARK_SLANT_RATIO
): MarkGeometry {
	const safeWidth = Math.max(1, width);
	const safeHeight = Math.max(1, height);
	const safeSplit = clamp(split, 0.05, 0.95);
	const safeDepthRatio = clamp(depthRatio, 0.001, 0.45);
	const safeSlantRatio = clamp(slantRatio, 0, 0.45);

	const depth = safeWidth * safeDepthRatio;
	const frontWidth = safeWidth - depth;
	const slant = safeHeight * safeSlantRatio;
	const bodyHeight = safeHeight - slant;
	const largeHeight = bodyHeight * safeSplit;
	const smallHeight = bodyHeight - largeHeight;

	const requirementHeight = direction === 'up' ? largeHeight : smallHeight;
	const effectHeight = direction === 'up' ? smallHeight : largeHeight;

	if (direction === 'up') {
		return {
			width: safeWidth,
			height: safeHeight,
			frontWidth,
			depth,
			slant,
			bodyHeight,
			largeHeight,
			smallHeight,
			requirementHeight,
			effectHeight,
			requirementTransform: matrix(1, -slant / frontWidth, 0, 1, 0, slant),
			effectTransform: matrix(
				1,
				-slant / frontWidth,
				depth / smallHeight,
				1,
				0,
				slant + largeHeight
			),
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
		width: safeWidth,
		height: safeHeight,
		frontWidth,
		depth,
		slant,
		bodyHeight,
		largeHeight,
		smallHeight,
		requirementHeight,
		effectHeight,
		requirementTransform: matrix(1, slant / frontWidth, -depth / smallHeight, 1, depth, 0),
		effectTransform: matrix(1, slant / frontWidth, 0, 1, 0, smallHeight),
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
