<script lang="ts">
	import ChoreSwitch from '$lib/components/chore/ChoreSwitch.svelte';
	import Dialog from '$lib/components/dialog/Dialog.svelte';
	import TopDialog from '$lib/components/dialog/TopDialog.svelte';
	import NewspaperEntry from '$lib/components/newspaper/NewspaperEntry.svelte';
	import type { DialoguePresentation, ViewFrameProps } from './types';

	type Props = Pick<ViewFrameProps, 'term' | 'year' | 'month' | 'onNewspaperOpen'> & {
		dialogue: DialoguePresentation;
		onResolveBonus?: (handIndex: number, acceptTrait: boolean) => void;
	};

	let { term, year, month, onNewspaperOpen, dialogue, onResolveBonus }: Props = $props();
	let donationChoice = $state(false);
	let dialogueText = $derived(
		`${dialogue.groupName}愿意给出一个优惠的提案，\n您可以选择给我手上的这张提案添加一个优惠条款，或收下我们的一点心意`
	);

	function advanceDialogue() {
		onResolveBonus?.(dialogue.handIndex, !donationChoice);
	}

	$effect(() => {
		if (dialogue.handIndex >= 0) donationChoice = false;
	});
</script>

<main class="game-view" aria-label="对话界面">
	<NewspaperEntry {term} {year} {month} onOpen={onNewspaperOpen} />

	<div class="top-dialog">
		<TopDialog text={`${dialogue.groupName}代表来访。`} />
	</div>

	<div class="dialog-area">
		<div class="choice-switch">
			<ChoreSwitch left={dialogue.positiveEffect} right={dialogue.donationOffer} bind:isSwitch={donationChoice} />
		</div>
		<Dialog text={dialogueText} onclick={advanceDialogue} />
	</div>
</main>

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
