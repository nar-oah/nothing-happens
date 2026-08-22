<script lang="ts">
	import MemorialClosedFrame from './MemorialClosedFrame.svelte';
	import MemorialTitleStrip from '../shared/MemorialTitleStrip.svelte';

	type Props = {
		title: string;
	};

	let { title }: Props = $props();
</script>

<MemorialClosedFrame>
	<div class="flex h-full w-full items-center justify-center">
		<MemorialTitleStrip text={title} />
	</div>
</MemorialClosedFrame>
