<script lang="ts">
	import { t } from '$lib/i18n';
	import { asset } from '$app/paths';

	type Props = {
		text: string;
	};

	let { text }: Props = $props();
</script>

<section
	class="relative w-full"
	style="aspect-ratio: 433 / 130"
	aria-label={$t('ui.visitor')}
	data-block-world-input
>
	<img
		src={asset('/images/dialog-top.svg')}
		alt=""
		aria-hidden="true"
		draggable="false"
		class="absolute inset-0 block h-full w-full select-none object-contain"
	/>
	<div
		class="absolute left-[4.142%] right-[1.183%] top-[41.872%] flex h-[86.7%] -translate-y-1/2 items-center overflow-hidden font-document font-light leading-auto text-surface-amber"
		style="font-size: clamp(16px, 2.6455vw, 40px)"
	>
		<p class="m-0 w-full whitespace-pre-line [overflow-wrap:anywhere]">{text}</p>
	</div>
</section>
