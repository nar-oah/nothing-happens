import type { CefIpcClient } from './client.ts';
import type { NormalizedRect } from './protocol.ts';

const BLOCKER_SELECTOR = '[data-block-world-input]';

export type InputRegionReporterOptions = {
	targetWindow?: Window;
	root?: ParentNode;
};

export class InputRegionReporter {
	private readonly targetWindow: Window;
	private readonly root: ParentNode;
	private readonly sendRegions: (regions: NormalizedRect[]) => void;
	private readonly resizeObserver: ResizeObserver;
	private readonly mutationObserver: MutationObserver;
	private observed = new Set<Element>();
	private frame: number | null = null;
	private lastSerialized: string | null = null;
	private started = false;

	constructor(
		sendRegions: (regions: NormalizedRect[]) => void,
		options: InputRegionReporterOptions = {}
	) {
		this.targetWindow = options.targetWindow ?? window;
		this.root = options.root ?? document;
		this.sendRegions = sendRegions;
		this.resizeObserver = new this.targetWindow.ResizeObserver(() => this.schedule());
		this.mutationObserver = new this.targetWindow.MutationObserver(() => {
			this.syncObservedElements();
			this.schedule();
		});
	}

	start(): void {
		if (this.started) return;
		this.started = true;
		this.syncObservedElements();
		this.mutationObserver.observe(this.root, {
			attributes: true,
			childList: true,
			subtree: true
		});
		this.targetWindow.addEventListener('resize', this.schedule);
		this.schedule();
	}

	destroy(): void {
		if (!this.started) return;
		this.started = false;
		this.targetWindow.removeEventListener('resize', this.schedule);
		this.resizeObserver.disconnect();
		this.mutationObserver.disconnect();
		this.observed.clear();
		if (this.frame !== null) this.targetWindow.cancelAnimationFrame(this.frame);
		this.frame = null;
	}

	private readonly schedule = (): void => {
		if (!this.started || this.frame !== null) return;
		this.frame = this.targetWindow.requestAnimationFrame(() => {
			this.frame = null;
			this.report();
		});
	};

	private syncObservedElements(): void {
		const current = new Set(this.root.querySelectorAll(BLOCKER_SELECTOR));
		for (const element of this.observed) {
			if (!current.has(element)) this.resizeObserver.unobserve(element);
		}
		for (const element of current) {
			if (!this.observed.has(element)) this.resizeObserver.observe(element);
		}
		this.observed = current;
	}

	private report(): void {
		const regions = normalizeInputRegions(
			[...this.observed].map((element) => element.getBoundingClientRect()),
			this.targetWindow.innerWidth,
			this.targetWindow.innerHeight
		);
		const serialized = JSON.stringify(regions);
		if (serialized === this.lastSerialized) return;
		this.lastSerialized = serialized;
		this.sendRegions(regions);
	}
}

export function createInputRegionReporter(
	client: CefIpcClient,
	options: InputRegionReporterOptions = {}
): InputRegionReporter {
	return new InputRegionReporter(
		(regions) => client.send('ui.input_regions', { regions }),
		options
	);
}

export function normalizeInputRegions(
	rects: ArrayLike<Pick<DOMRect, 'left' | 'top' | 'right' | 'bottom'>>,
	viewportWidth: number,
	viewportHeight: number
): NormalizedRect[] {
	if (viewportWidth <= 0 || viewportHeight <= 0) return [];
	return Array.from(rects)
		.flatMap((rect): NormalizedRect[] => {
			const left = clamp(rect.left, 0, viewportWidth);
			const top = clamp(rect.top, 0, viewportHeight);
			const right = clamp(rect.right, 0, viewportWidth);
			const bottom = clamp(rect.bottom, 0, viewportHeight);
			return right <= left || bottom <= top
				? []
				: [
						{
							x: round(left / viewportWidth),
							y: round(top / viewportHeight),
							width: round((right - left) / viewportWidth),
							height: round((bottom - top) / viewportHeight)
						}
					];
		})
		.sort((first, second) =>
			first.x !== second.x
				? first.x - second.x
				: first.y !== second.y
					? first.y - second.y
					: first.width !== second.width
						? first.width - second.width
						: first.height - second.height
		);
}

function clamp(value: number, minimum: number, maximum: number): number {
	return Math.min(maximum, Math.max(minimum, value));
}

function round(value: number): number {
	return Math.round(value * 1_000_000) / 1_000_000;
}
