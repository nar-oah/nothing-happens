<script lang="ts">
	import { t, type Language } from '$lib/i18n';
	import ChoreItem from '../chore/ChoreItem.svelte';

	type Props = {
		language?: Language;
		displayMode?: 'windowed' | 'fullscreen';
		disabled?: boolean;
		onLanguageClick?: () => void;
		onDisplayClick?: () => void;
		onExitClick?: () => void;
	};

	let {
		language = 'zh_CN',
		displayMode = 'windowed',
		disabled = false,
		onLanguageClick,
		onDisplayClick,
		onExitClick
	}: Props = $props();
	const languageLabel = $derived($t(`settings.${language}`));
	const displayLabel = $derived($t(`settings.${displayMode}`));
</script>

<aside class="flex flex-col items-end gap-[20px]" aria-label={$t('settings.title')} data-block-world-input>
	<button
		type="button"
		class="cursor-pointer border-0 bg-transparent p-0 disabled:cursor-default"
		aria-label={$t('settings.languageValue', { language: languageLabel })}
		{disabled}
		onclick={() => onLanguageClick?.()}
	>
		<ChoreItem text={$t('settings.language')} value={languageLabel} isRow={false} />
	</button>
	<button
		type="button"
		class="cursor-pointer border-0 bg-transparent p-0 disabled:cursor-default"
		aria-label={$t('settings.displayValue', { mode: displayLabel })}
		{disabled}
		onclick={() => onDisplayClick?.()}
	>
		<ChoreItem text={$t('settings.display')} value={displayLabel} isRow={false} />
	</button>
	<button
		type="button"
		class="cursor-pointer border-0 bg-transparent p-0 disabled:cursor-default"
		aria-label={$t('settings.quitAria')}
		{disabled}
		onclick={() => onExitClick?.()}
	>
		<ChoreItem text={$t('settings.quit')} isRow={false} />
	</button>
</aside>
