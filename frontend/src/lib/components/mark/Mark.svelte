<script lang="ts">
	import MarkFace from './MarkFace.svelte';
	import MarkSeal from './MarkSeal.svelte';
	import {
		MARK_FACE_HEIGHT,
		MARK_FACE_WIDTH,
		MARK_HEIGHT,
		MARK_PART_TRANSFORMS,
		MARK_SEAL_SIZE,
		MARK_STAGE_HEIGHT,
		MARK_STAGE_TRANSFORMS,
		MARK_STAGE_WIDTH,
		MARK_WIDTH,
		type MarkDirection,
		type MarkFaceContent
	} from './mark';

	type Props = {
		direction?: MarkDirection;
		policyName?: string;
		requirement?: Partial<MarkFaceContent>;
		effect?: Partial<MarkFaceContent>;
		disabled?: boolean;
		onDirectionChange?: (direction: MarkDirection) => void;
	};

	let {
		direction = $bindable<MarkDirection>('up'),
		policyName = '以工代赈',
		requirement,
		effect,
		disabled = false,
		onDirectionChange
	}: Props = $props();

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
	class="relative block h-[var(--mark-height)] w-[var(--mark-width)] cursor-pointer border-0 bg-transparent p-0 text-left disabled:cursor-default"
	style:--mark-width={`${MARK_WIDTH}px`}
	style:--mark-height={`${MARK_HEIGHT}px`}
	aria-label={direction === 'up' ? '查看政策效果' : '查看政策条件'}
	aria-pressed={direction === 'down'}
	{disabled}
	onclick={toggleDirection}
>
	<div
		class="mark-stage absolute left-0 top-0 h-[var(--stage-height)] w-[var(--stage-width)] origin-top-left will-change-transform"
		style:--stage-width={`${MARK_STAGE_WIDTH}px`}
		style:--stage-height={`${MARK_STAGE_HEIGHT}px`}
		style:transform={MARK_STAGE_TRANSFORMS[direction]}
	>
		<div
			class="mark-part absolute left-0 top-0 h-[var(--face-height)] w-[var(--face-width)] origin-top-left will-change-transform"
			style:--face-width={`${MARK_FACE_WIDTH}px`}
			style:--face-height={`${MARK_FACE_HEIGHT}px`}
			style:transform={MARK_PART_TRANSFORMS[direction].requirement}
		>
			<MarkFace face="requirement" headline={requirement?.headline} detail={requirement?.detail} />
		</div>
		<div
			class="mark-part absolute left-0 top-0 h-[var(--face-height)] w-[var(--face-width)] origin-top-left will-change-transform"
			style:--face-width={`${MARK_FACE_WIDTH}px`}
			style:--face-height={`${MARK_FACE_HEIGHT}px`}
			style:transform={MARK_PART_TRANSFORMS[direction].effect}
		>
			<MarkFace face="effect" headline={effect?.headline} detail={effect?.detail} />
		</div>
		<div
			class="mark-part absolute left-0 top-0 h-[var(--seal-size)] w-[var(--seal-size)] origin-top-left will-change-transform"
			style:--seal-size={`${MARK_SEAL_SIZE}px`}
			style:transform={MARK_PART_TRANSFORMS[direction].seal}
		>
			<MarkSeal text={policyName} />
		</div>
	</div>
</button>

<style>
	.mark-stage,
	.mark-part {
		transition-property: transform;
		transition-duration: 320ms;
		transition-timing-function: cubic-bezier(0.22, 0.8, 0.2, 1);
	}
</style>
