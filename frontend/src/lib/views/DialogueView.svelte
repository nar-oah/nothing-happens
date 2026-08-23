<script lang="ts">
	import ChoreSwitch from '$lib/components/chore/ChoreSwitch.svelte';
	import Dialog from '$lib/components/dialog/Dialog.svelte';
	import TopDialog from '$lib/components/dialog/TopDialog.svelte';
	import Left from '$lib/components/left/Left.svelte';
	import Newspaper from '$lib/components/newspaper/Newspaper.svelte';
	import { mockBaseline, mockLeftItems } from '$lib/demo/mock';

	let choiceVisible = $state(true);
	let donationChoice = $state(false);
	const dialogueText =
		'造身公所愿意给出一个优惠的提案，\n您可以选择给我手上的这张提案添加一个优惠条款，或收下我们的一点心意';

	function advanceDialogue() {
		if (choiceVisible) {
			console.info('Dialogue choice', donationChoice ? '政治献金+5' : '商貿+8');
			choiceVisible = false;
			return;
		}
		console.info('Advance dialogue');
	}
</script>

<main class="game-view" aria-label="对话界面">
	<Left
		scene="dialogue"
		items={mockLeftItems}
		baseline={mockBaseline}
		onItemSelect={(item) => console.info('Dialogue archive item', item)}
	/>
	<Newspaper term={2} year={3} month={7} onOpen={() => console.info('Open newspaper')} />

	<div class="top-dialog">
		<TopDialog text="造身公所派来的代表，负责行身制造与维修网络。" />
	</div>

	<div class="dialog-area">
		{#if choiceVisible}
			<div class="choice-switch">
				<ChoreSwitch left="商貿+8" right="政治献金+5" bind:isSwitch={donationChoice} />
			</div>
		{/if}
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
