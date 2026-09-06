<script lang="ts">
	import { onDestroy, untrack } from 'svelte';
	import { language } from '$lib/i18n';

	type Props = {
		text: string;
		active?: boolean;
		stepMs?: number;
	};

	let { text, active = true, stepMs = 42 }: Props = $props();
	let displayed = $state(untrack(() => text));
	let previousLanguage = untrack(() => $language);
	let timers: ReturnType<typeof setTimeout>[] = [];

	function clearTimers() {
		for (const timer of timers) clearTimeout(timer);
		timers = [];
	}

	function morph(next: string) {
		clearTimers();
		if (
			!active ||
			typeof window === 'undefined' ||
			window.matchMedia('(prefers-reduced-motion: reduce)').matches
		) {
			displayed = next;
			return;
		}

		const from = Array.from(displayed);
		const to = Array.from(next);
		const length = Math.max(from.length, to.length);
		const cells = Array.from({ length }, (_, index) => from[index] ?? ' ');
		displayed = cells.join('');

		for (let index = 0; index < length; index += 1) {
			const scrambleTimer = setTimeout(() => {
				cells[index] = from[index] === to[index] ? (to[index] ?? ' ') : '?';
				displayed = cells.join('');
			}, index * stepMs);
			const settleTimer = setTimeout(
				() => {
					cells[index] = to[index] ?? ' ';
					displayed = cells.join('');
					if (index === length - 1) displayed = next;
				},
				index * stepMs + Math.max(54, stepMs)
			);
			timers.push(scrambleTimer, settleTimer);
		}
	}

	$effect(() => {
		const next = text;
		const locale = $language;
		if (locale !== previousLanguage) {
			previousLanguage = locale;
			clearTimers();
			displayed = next;
		} else if (next !== untrack(() => displayed)) {
			morph(next);
		}
	});

	onDestroy(clearTimers);
</script>

<span class="whitespace-pre">{displayed}</span>
