<script lang="ts">
	import { t } from '$lib/i18n';
	import ChoreSwitch from '$lib/components/chore/ChoreSwitch.svelte';
	import Dialog from '$lib/components/dialog/Dialog.svelte';
	import TopDialog from '$lib/components/dialog/TopDialog.svelte';
	import {
		createEventIntelDialogueContent,
		createInterestGroupDialogueContent
	} from '$lib/components/dialog/content';
	import NewspaperEntry from '$lib/components/newspaper/NewspaperEntry.svelte';
	import SimpleDialogueView from './SimpleDialogueView.svelte';
	import type { DialoguePresentation, ViewFrameProps } from './types';

	type Props = Pick<ViewFrameProps, 'term' | 'year' | 'month' | 'onNewspaperOpen'> & {
		dialogue: DialoguePresentation;
		onResolveVisit?: (acceptTrait?: boolean) => void;
	};

	let { term, year, month, onNewspaperOpen, dialogue, onResolveVisit }: Props = $props();
	let donationChoice = $state(false);
	const content = $derived(
		dialogue.kind === 'interest_group'
			? createInterestGroupDialogueContent(
					dialogue.groupName,
					dialogue.positiveEffect,
					dialogue.donationOffer,
					$t
				)
			: dialogue.kind === 'event_intel'
				? createEventIntelDialogueContent({
						raceName: dialogue.raceName,
						metricName: dialogue.metricName,
						requirement: dialogue.requirement,
						strength: dialogue.strength
					}, $t)
				: null
	);

	function advanceDialogue() {
		if (dialogue.kind === 'simple') {
			onResolveVisit?.();
			return;
		}
		onResolveVisit?.(dialogue.kind === 'interest_group' ? !donationChoice : undefined);
	}
</script>

{#if dialogue.kind === 'simple'}
	<SimpleDialogueView
		{term}
		{year}
		{month}
		{onNewspaperOpen}
		{dialogue}
		onResolve={advanceDialogue}
	/>
{:else}
	<main class="game-view" aria-label={$t('view.dialogue')}>
		<NewspaperEntry {term} {year} {month} onOpen={onNewspaperOpen} />

		<div class="top-dialog">
			<TopDialog text={content?.visitor ?? ''} />
		</div>

		<div class="dialog-area">
			{#if dialogue.kind === 'interest_group'}
				<div class="choice-switch">
					<ChoreSwitch
						left={dialogue.positiveEffect}
						right={dialogue.donationOffer}
						bind:isSwitch={donationChoice}
					/>
				</div>
			{/if}
			<Dialog text={content?.body ?? ''} onclick={advanceDialogue} />
		</div>
	</main>
{/if}

<style>
	.game-view {
		position: relative;
		height: 100vh;
		overflow: hidden;
	}

	.top-dialog {
		position: absolute;
		top: 20px;
		left: 53.125%;
		width: 44.01%;
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
