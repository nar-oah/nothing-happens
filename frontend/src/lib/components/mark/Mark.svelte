<script lang="ts">
	import MarkFace from './MarkFace.svelte';
	import MarkSeal from './MarkSeal.svelte';
	import { MARK_SEAL_SOURCE_SIZE, createMarkGeometry } from './mark';
	import type { MarkDirection, MarkFaceContent } from './mark';

	type Props = {
		direction?: MarkDirection;
		policyName: string;
		requirement: MarkFaceContent;
		effect: MarkFaceContent;
		onDirectionChange?: (direction: MarkDirection) => void;
	};

	let {
		direction = $bindable<MarkDirection>('up'),
		policyName,
		requirement,
		effect,
		onDirectionChange
	}: Props = $props();

	let geometry = $derived(createMarkGeometry(direction));

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
	onclick={toggleDirection}
>
	<div
		class="absolute left-0 top-0 h-[var(--face-height)] w-[var(--front-width)] origin-top-left overflow-hidden"
		style:--face-height={`${geometry.requirementHeight}px`}
		style:--front-width={`${geometry.frontWidth}px`}
		style:transform={geometry.requirementTransform}
	>
		<MarkFace
			headline={requirement.headline}
			detail={requirement.detail}
			is_show={direction === 'up'}
		/>
	</div>

	<div
		class="absolute left-0 top-0 h-[var(--face-height)] w-[var(--front-width)] origin-top-left overflow-hidden"
		style:--face-height={`${geometry.effectHeight}px`}
		style:--front-width={`${geometry.frontWidth}px`}
		style:transform={geometry.effectTransform}
	>
		<MarkFace headline={effect.headline} detail={effect.detail} is_show={direction === 'down'} />
	</div>

	<div
		class="absolute left-0 top-0 h-[var(--seal-size)] w-[var(--seal-size)] origin-top-left overflow-hidden"
		style:--seal-size={`${MARK_SEAL_SOURCE_SIZE}px`}
		style:transform={geometry.sealTransform}
	>
		<MarkSeal text={policyName} />
	</div>
</button>
