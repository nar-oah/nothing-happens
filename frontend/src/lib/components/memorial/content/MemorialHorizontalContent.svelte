<script lang="ts">
	import type { MemorialHorizontalContentData as Props } from '../types';

	let { title, body, redacted = false }: Props = $props();
	const lines = $derived(body.split('\n'));
</script>

<div class="memorial-content flex min-w-0 flex-col text-ink-primary [word-break:break-word]" class:redacted>
	{#if title}
		<p class="m-0 w-full font-policy text-[22px] font-medium leading-20">{title}</p>
	{/if}
	<div class:mt-3={title} class="typo-document-body-compact m-0 w-full overflow-hidden">
		{#each lines as line, index (index)}
			<div class="redaction-line relative min-h-[21px] w-full">
				<span class="whitespace-pre-wrap">{line || ' '}</span>
				{#if redacted && line}
					<span class="redaction absolute inset-x-0 top-[2px] h-[17px] bg-ink-primary" aria-hidden="true"></span>
				{/if}
			</div>
		{/each}
	</div>
</div>

<style>
	.redaction {
		transform-origin: right center;
		transition: transform 460ms cubic-bezier(0.22, 0.8, 0.2, 1);
	}

	.redacted:hover .redaction,
	.redacted:focus-within .redaction {
		transform: scaleX(0);
	}

	.redacted .redaction-line:nth-child(2n) .redaction { transition-delay: 35ms; }
	.redacted .redaction-line:nth-child(3n) .redaction { transition-delay: 70ms; }

	@media (prefers-reduced-motion: reduce) {
		.redaction { transition-duration: 1ms; transition-delay: 0ms !important; }
	}
</style>
