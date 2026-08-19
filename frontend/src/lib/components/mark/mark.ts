export const MARK_WIDTH = 230;
export const MARK_HEIGHT = 82;
export const MARK_STAGE_WIDTH = 230;
export const MARK_STAGE_HEIGHT = MARK_HEIGHT * 0.7;
export const MARK_FACE_WIDTH = 220;
export const MARK_FACE_HEIGHT = 65;
export const MARK_SEAL_SIZE = 80;

export type MarkDirection = 'up' | 'down';
export type MarkFaceKind = 'requirement' | 'effect';

export type MarkFaceContent = {
	headline: string;
	detail: string;
};

export const MARK_STAGE_TRANSFORMS: Record<MarkDirection, string> = {
	up: 'translate3d(4.188px, 0, 0) rotate(2.5deg)',
	down: 'translate3d(0, 10.034px, 0) rotate(-2.5deg)'
};

export const MARK_PART_TRANSFORMS: Record<
	MarkDirection,
	Record<'requirement' | 'effect' | 'seal', string>
> = {
	up: {
		requirement: 'matrix(1, -0.0454545455, 0, 0.8461538462, 0, 10)',
		effect: 'matrix(1, -0.0454545455, 0.1538461538, 0.4769230769, 0, 65)',
		seal: 'matrix(0.125, 0.3875, 0, 0.6875, 220, 0)'
	},
	down: {
		requirement: 'matrix(1, 0.0454545455, -0.1538461538, 0.4769230769, 10, 0)',
		effect: 'matrix(1, 0.0454545455, 0, 0.8461538462, 0, 31)',
		seal: 'matrix(0.125, -0.3875, 0, 0.6875, 220, 41)'
	}
};
