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

<aside class="newspaper-area" aria-label="邸报入口">
	<div class="newspaper-paper">
		<MemorialNewspaper {term} {year} {month} onclick={onOpen} />
	</div>
</aside>

<style>
	.newspaper-area {
		position: fixed;
		top: 0;
		left: 0;
		z-index: 50;
		width: 390px;
		height: 350px;
	}

	.newspaper-paper {
		width: 345px;
		transform: translate3d(-205px, -62px, 0) rotate(-45deg);
		transform-origin: center;
		transition: transform 260ms ease-out;
	}

	.newspaper-area:hover .newspaper-paper,
	.newspaper-area:focus-within .newspaper-paper {
		transform: translate3d(18px, 50px, 0) rotate(-45deg);
	}

	@media (prefers-reduced-motion: reduce) {
		.newspaper-paper {
			transition-duration: 1ms;
		}
	}
</style>
