<script lang="ts">
	import MarkFace from './MarkFace.svelte';
	import MarkSeal from './MarkSeal.svelte';
	import {
		MARK_DEPTH_RATIO,
		MARK_HEIGHT,
		MARK_SEAL_SOURCE_SIZE,
		MARK_SLANT_RATIO,
		MARK_SPLIT,
		MARK_WIDTH,
		createMarkGeometry,
		type MarkDirection,
		type MarkFaceContent
	} from './mark';

	type Props = {
		direction?: MarkDirection;
		width?: number;
		height?: number;
		split?: number;
		depthRatio?: number;
		slantRatio?: number;
		policyName?: string;
		requirement?: Partial<MarkFaceContent>;
		effect?: Partial<MarkFaceContent>;
		disabled?: boolean;
		onDirectionChange?: (direction: MarkDirection) => void;
	};

	let {
		direction = $bindable<MarkDirection>('up'),
		width = MARK_WIDTH,
		height = MARK_HEIGHT,
		split = MARK_SPLIT,
		depthRatio = MARK_DEPTH_RATIO,
		slantRatio = MARK_SLANT_RATIO,
		policyName = '以工代赈',
		requirement,
		effect,
		disabled = false,
		onDirectionChange
	}: Props = $props();

	let geometry = $derived(
		createMarkGeometry(width, height, split, direction, depthRatio, slantRatio)
	);

	function setDirection(next: MarkDirection) {
		if (direction === next) return;
		direction = next;
		onDirectionChange?.(next);
	}

	function toggleDirection() {
		setDirection(direction === 'up' ? 'down' : 'up');
	}
</script>

<button
	type="button"
	class="relative block h-[var(--mark-height)] w-[var(--mark-width)] cursor-pointer overflow-hidden border-0 bg-transparent p-0 text-left disabled:cursor-default"
	style:--mark-width={`${geometry.width}px`}
	style:--mark-height={`${geometry.height}px`}
	aria-label={direction === 'up' ? '查看政策效果' : '查看政策条件'}
	aria-pressed={direction === 'down'}
	{disabled}
	onclick={toggleDirection}
>
	<div
		class="absolute left-0 top-0 h-[var(--face-height)] w-[var(--front-width)] origin-top-left overflow-hidden"
		style:--face-height={`${geometry.requirementHeight}px`}
		style:--front-width={`${geometry.frontWidth}px`}
		style:transform={geometry.requirementTransform}
	>
		<MarkFace face="requirement" headline={requirement?.headline} detail={requirement?.detail} />
	</div>

	<div
		class="absolute left-0 top-0 h-[var(--face-height)] w-[var(--front-width)] origin-top-left overflow-hidden"
		style:--face-height={`${geometry.effectHeight}px`}
		style:--front-width={`${geometry.frontWidth}px`}
		style:transform={geometry.effectTransform}
	>
		<MarkFace face="effect" headline={effect?.headline} detail={effect?.detail} />
	</div>

	<div
		class="absolute left-0 top-0 h-[var(--seal-size)] w-[var(--seal-size)] origin-top-left overflow-hidden"
		style:--seal-size={`${MARK_SEAL_SOURCE_SIZE}px`}
		style:transform={geometry.sealTransform}
	>
		<MarkSeal text={policyName} />
	</div>
</button>
