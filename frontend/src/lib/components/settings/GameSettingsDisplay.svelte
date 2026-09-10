<script lang="ts">
	import { t, type Language } from '$lib/i18n';
	import ChoreItem from '../chore/ChoreItem.svelte';
	import type { ChoreNumberEditorValue } from '../chore/chore';

	type Props = {
		language?: Language;
		displayMode?: 'windowed' | 'fullscreen';
		musicVolume?: number;
		disabled?: boolean;
		onLanguageClick?: () => void;
		onDisplayClick?: () => void;
		onMusicVolumeChange?: (value: number) => void;
		onExitClick?: () => void;
	};

	let {
		language = 'zh_CN',
		displayMode = 'windowed',
		musicVolume = 100,
		disabled = false,
		onLanguageClick,
		onDisplayClick,
		onMusicVolumeChange,
		onExitClick
	}: Props = $props();
	const languageLabel = $derived($t(`settings.${language}`));
	const displayLabel = $derived($t(`settings.${displayMode}`));
	const musicVolumeLabel = $derived(language === 'en' ? 'Volume' : '音量');
	const musicVolumeValue: ChoreNumberEditorValue = $derived({
		value: musicVolume,
		min: 0,
		max: 100,
		disabled,
		onChange: (value) => onMusicVolumeChange?.(value)
	});
</script>

<aside
	class="flex flex-col items-end gap-[20px]"
	aria-label={$t('settings.title')}
	data-block-world-input
>
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
	<ChoreItem text={musicVolumeLabel} value={musicVolumeValue} isRow={false} />
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
