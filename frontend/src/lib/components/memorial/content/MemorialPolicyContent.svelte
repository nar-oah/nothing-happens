<script lang="ts">
	import MarkSeal from '../../mark/MarkSeal.svelte';
	import MemorialHorizontalContent from './MemorialHorizontalContent.svelte';
	import type { MemorialPolicyContentData as Props } from '../types';

	let { policyTitle, content }: Props = $props();
</script>

<div
	class="box-border flex h-[345px] w-[123px] flex-col items-center gap-5 overflow-hidden py-12 text-ink-primary"
>
	<div class="h-80 w-80 shrink-0 overflow-hidden rounded-3">
		<MarkSeal text={policyTitle} is_ghost={true} />
	</div>
	<div class="w-[92px]">
		<MemorialHorizontalContent {...content} />
	</div>
</div>
