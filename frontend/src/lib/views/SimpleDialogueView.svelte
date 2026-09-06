<script lang="ts">
	import { t } from '$lib/i18n';
	import ChoreSwitch from '$lib/components/chore/ChoreSwitch.svelte';
	import Dialog from '$lib/components/dialog/Dialog.svelte';
	import NewspaperEntry from '$lib/components/newspaper/NewspaperEntry.svelte';
	import type { DialoguePresentation, ViewFrameProps } from './types';

	type SimpleDialogue = Extract<DialoguePresentation, { kind: 'simple' }>;
	type Props = Pick<ViewFrameProps, 'term' | 'year' | 'month' | 'onNewspaperOpen'> & {
		dialogue: SimpleDialogue;
		onResolve?: () => void;
	};

	let { term, year, month, onNewspaperOpen, dialogue, onResolve }: Props = $props();
	let optionChoice = $state(false);
	let answered = $state(false);
	let hasOptions = $derived(
		Boolean(dialogue.leftOption && dialogue.rightOption) &&
			dialogue.leftContent !== undefined &&
			dialogue.rightContent !== undefined
	);
	let text = $derived(
		answered && hasOptions
			? optionChoice
				? (dialogue.rightContent ?? '')
				: (dialogue.leftContent ?? '')
			: dialogue.initialText
	);

	function advanceDialogue() {
		if (hasOptions && !answered) {
			answered = true;
			return;
		}
		onResolve?.();
	}
</script>

<main class="game-view" aria-label={$t('view.simpleDialogue')}>
	<NewspaperEntry {term} {year} {month} onOpen={onNewspaperOpen} />

	<div class="dialog-area">
		{#if hasOptions && !answered}
			<div class="choice-switch">
				<ChoreSwitch
					left={dialogue.leftOption ?? ''}
					right={dialogue.rightOption ?? ''}
					bind:isSwitch={optionChoice}
				/>
			</div>
		{/if}
		<Dialog {text} onclick={advanceDialogue} />
	</div>
</main>

<style>
	.game-view {
		position: relative;
		height: 100vh;
		overflow: hidden;
	}

	.dialog-area {
		position: absolute;
		bottom: 38px;
		left: 3.581%;
		z-index: 60;
		width: 71.615%;
	}

	.choice-switch {
		display: flex;
		justify-content: flex-end;
		margin-bottom: 8px;
	}
</style>
