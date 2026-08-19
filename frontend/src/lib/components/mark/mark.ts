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
