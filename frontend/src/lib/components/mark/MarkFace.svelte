<script lang="ts">
	import type { MarkFaceContent, MarkFaceKind } from './mark';

	type Props = {
		face: MarkFaceKind;
		headline?: string;
		detail?: string;
	};

	const DEFAULT_CONTENT: Record<MarkFaceKind, MarkFaceContent> = {
		requirement: {
			headline: '所需　用工＜商贸六成',
			detail: '今数　42＜48　本批触发'
		},
		effect: {
			headline: '效用　用工补至商贸六成',
			detail: '本批　用工＋6'
		}
	};

	let { face, headline, detail }: Props = $props();
</script>

<div
	class:bg-surface-amber-pressed={face === 'requirement'}
	class:bg-accent-amber-deep={face === 'effect'}
	class="relative h-full w-full overflow-hidden"
>
	<p
		class:text-surface-indigo={face === 'requirement'}
		class:text-ink-primary={face === 'effect'}
		class="typo-seal-policy-clause absolute left-[12px] right-[12px] top-[8px] origin-center rotate-[0.35deg] whitespace-nowrap"
	>
		{headline ?? DEFAULT_CONTENT[face].headline}
	</p>
	<p
		class:text-surface-indigo={face === 'requirement'}
		class:text-ink-primary={face === 'effect'}
		class="typo-seal-policy-detail absolute left-[12px] right-[12px] origin-center rotate-[0.35deg] whitespace-nowrap"
	>
		{detail ?? DEFAULT_CONTENT[face].detail}
	</p>
</div>
