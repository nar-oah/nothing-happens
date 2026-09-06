<script lang="ts">
	import { t } from '$lib/i18n';
	import MarkFace from './MarkFace.svelte';
	import MarkSeal from './MarkSeal.svelte';
	import { MARK_SEAL_SOURCE_SIZE, createMarkGeometry, createPolicyMarkContent } from './mark';
	import type { MarkDirection } from './mark';
	import type { MetricValues, PolicyDefinition } from '$lib/game';

	type Props = {
		direction?: MarkDirection;
		policy: PolicyDefinition;
		baseline: MetricValues;
		onDirectionChange?: (direction: MarkDirection) => void;
	};

	let {
		direction = $bindable<MarkDirection>('up'),
		policy,
		baseline,
		onDirectionChange
	}: Props = $props();

	let geometry = $derived(createMarkGeometry(direction));
	let content = $derived(createPolicyMarkContent(policy, baseline));

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
	class="relative block h-$mark-height w-$mark-width cursor-pointer overflow-hidden border-0 bg-transparent p-0 text-left disabled:cursor-default"
	style:--mark-width={`${geometry.width}px`}
	style:--mark-height={`${geometry.height}px`}
	aria-label={$t(direction === 'up' ? 'mark.viewEffect' : 'mark.viewCondition')}
	aria-pressed={direction === 'down'}
	onclick={toggleDirection}
>
	<div
		class="absolute left-0 top-0 h-$face-height w-$front-width origin-top-left overflow-hidden"
		style:--face-height={`${geometry.requirement.height}px`}
		style:--front-width={`${geometry.frontWidth}px`}
		style:transform={geometry.requirement.transform}
	>
		<MarkFace
			headline={content.requirement.headline}
			detail={content.requirement.detail}
			is_show={direction === 'up'}
		/>
	</div>

	<div
		class="absolute left-0 top-0 h-$face-height w-$front-width origin-top-left overflow-hidden"
		style:--face-height={`${geometry.effect.height}px`}
		style:--front-width={`${geometry.frontWidth}px`}
		style:transform={geometry.effect.transform}
	>
		<MarkFace
			headline={content.effect.headline}
			detail={content.effect.detail}
			is_show={direction === 'down'}
		/>
	</div>

	<div
		class="absolute left-0 top-0 h-$seal-size w-$seal-size origin-top-left overflow-hidden"
		style:--seal-size={`${MARK_SEAL_SOURCE_SIZE}px`}
		style:transform={geometry.sealTransform}
	>
		<MarkSeal text={policy.display_name} />
	</div>
</button>
