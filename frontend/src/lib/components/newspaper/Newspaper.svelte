<script lang="ts">
	import MemorialNewspaper from '../memorial/MemorialNewspaper.svelte';

	type Props = {
		term: number;
		year: number;
		month: number;
		onOpen?: () => void;
	};

	let { term, year, month, onOpen }: Props = $props();
</script>

<aside class="newspaper" aria-label="邸报入口">
	<MemorialNewspaper {term} {year} {month} onclick={onOpen} />
</aside>

<style>
	.newspaper {
		position: fixed;
		top: 0;
		left: 0;
		z-index: 50;
		transform: translate3d(-205px, -62px, 0) rotate(-45deg);
		transform-origin: center;
		transition: transform 260ms ease-out;
		filter: drop-shadow(0 10px 0 rgb(30 46 59 / 0.22));
	}

	.newspaper:hover,
	.newspaper:focus-within {
		transform: translate3d(18px, 50px, 0) rotate(-45deg);
	}

	@media (prefers-reduced-motion: reduce) {
		.newspaper {
			transition-duration: 1ms;
		}
	}
</style>
