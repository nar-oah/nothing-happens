<script lang="ts">
	import { playUiSfx } from '$lib/audio/ui-sfx';
	import { t } from '$lib/i18n';
	import MemorialNewspaper from '../memorial/MemorialNewspaper.svelte';

	type Props = {
		term: number;
		year: number;
		month: number;
		onOpen?: () => void;
	};

	let { term, year, month, onOpen }: Props = $props();

	function openNewspaper() {
		if (!onOpen) return;
		playUiSfx('memorial-toggle', true);
		onOpen();
	}
</script>

<aside class="newspaper-hover-area" aria-label={$t('newspaper.entry')} data-block-world-input>
	<div class="newspaper">
		<MemorialNewspaper {term} {year} {month} onclick={openNewspaper} />
	</div>
</aside>

<style>
	.newspaper-hover-area {
		position: fixed;
		top: 0;
		left: 0;
		z-index: 10;
		width: 282px;
		height: 237px;
	}

	.newspaper {
		position: absolute;
		top: 35px;
		left: 0;
		transform: translate3d(-120px, -62px, 0) rotate(-45deg);
		transform-origin: center;
		transition: transform 260ms ease-out;
	}

	.newspaper-hover-area:hover .newspaper,
	.newspaper-hover-area:focus-within .newspaper {
		transform: translate3d(-60px, -32px, 0) rotate(-45deg);
	}

	@media (prefers-reduced-motion: reduce) {
		.newspaper {
			transition-duration: 1ms;
		}
	}
</style>