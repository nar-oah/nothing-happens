<script lang="ts">
	import favicon from '$lib/assets/favicon.svg';
	import { installUiSfx } from '$lib/audio/ui-sfx';
	import { onMount } from 'svelte';
	import 'virtual:uno.css';

	let { children } = $props();

	onMount(() => {
		const removeUiSfx = installUiSfx();
		const handleWheel = (event: WheelEvent) => {
			if (event.defaultPrevented || !event.deltaY || Math.abs(event.deltaX) > Math.abs(event.deltaY)) {
				return;
			}
			const target = event.target;
			if (!(target instanceof Element)) return;
			const scroller = target.closest<HTMLElement>('.editor-slot');
			if (!scroller) return;
			const maxScroll = scroller.scrollWidth - scroller.clientWidth;
			if (maxScroll <= 0) return;
			const next = Math.max(0, Math.min(maxScroll, scroller.scrollLeft + event.deltaY));
			if (next === scroller.scrollLeft) return;
			event.preventDefault();
			scroller.scrollLeft = next;
		};
		document.addEventListener('wheel', handleWheel, { passive: false });
		return () => {
			removeUiSfx();
			document.removeEventListener('wheel', handleWheel);
		};
	});
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
</svelte:head>

{@render children()}

<style>
	:global(html),
	:global(body) {
		margin: 0;
		min-width: 960px;
		min-height: 100%;
		background: transparent;
	}

	:global(body),
	:global(body *) {
		-webkit-user-select: none;
		user-select: none;
	}

	:global(input),
	:global(textarea),
	:global([contenteditable='true']) {
		-webkit-user-select: text;
		user-select: text;
	}

	:global(img) {
		-webkit-user-drag: none;
	}

	:global(button),
	:global(input) {
		font: inherit;
	}
</style>