<script lang="ts">
	import ChoreItem from '$lib/components/chore/ChoreItem.svelte';
	import Dialog from '$lib/components/dialog/Dialog.svelte';
	import TopDialog from '$lib/components/dialog/TopDialog.svelte';
	import Left from '$lib/components/left/Left.svelte';
	import Newspaper from '$lib/components/newspaper/Newspaper.svelte';
	import { mockBaseline, mockLeftItems } from '$lib/demo/mock';

	let dialogue = $state('诸位都在催一个答案。可真正要紧的，是我们愿意为这个答案付出什么。');
	let speaker = $state('总督');
	let notice = $state('对话选择使用本地 mock 状态。');

	function choose(nextSpeaker: string, nextText: string) {
		speaker = nextSpeaker;
		dialogue = nextText;
		notice = `已选择 ${nextSpeaker} 的回应`;
	}
</script>

<main class="game-view" aria-label="对话界面">
	<div class="left-slot">
		<Left
			items={mockLeftItems}
			baseline={mockBaseline}
			onItemSelect={(item) => (notice = `对话中查看 ${item.kind} #${item.ref.index}`)}
		/>
	</div>
	<Newspaper term={2} year={3} month={7} onOpen={() => (notice = '对话中的邸报 callback')} />
	<div class="top-dialog"><TopDialog text={`${speaker}\n正在等待你的答复。`} /></div>
	<div class="dialog-area">
		<div class="speaker"><ChoreItem text={speaker} value="发言" isRow /></div>
		<div class="choices" aria-label="对话选项">
			<button type="button" onclick={() => choose('秘书', '先核对案牍，再向各公所说明我们的期限。')}
				>暂缓答复</button
			>
			<button type="button" onclick={() => choose('总督', '那就现在表态，并承担表态之后的一切。')}
				>立即表态</button
			>
		</div>
		<Dialog text={dialogue} />
	</div>
	<p class="notice" aria-live="polite">{notice}</p>
</main>

<style>
	.game-view {
		position: relative;
		height: 100vh;
		overflow: hidden;
		background: transparent;
	}
	.left-slot {
		position: absolute;
		inset: 150px auto 20px 24px;
	}
	.top-dialog {
		position: absolute;
		top: 30px;
		left: 50%;
		transform: translateX(-50%);
	}
	.dialog-area {
		position: absolute;
		right: 3vw;
		bottom: 28px;
		display: flex;
		flex-direction: column;
		align-items: flex-end;
		gap: 8px;
	}
	.speaker {
		position: absolute;
		left: -120px;
		bottom: 30px;
	}
	.choices {
		display: flex;
		gap: 8px;
		margin-right: 3vw;
	}
	.choices button {
		cursor: pointer;
		border: 0;
		background: #1e2e3b;
		padding: 6px 12px;
		color: #efb836;
		font: 300 18px 'RealTypeWriter';
	}
	.notice {
		position: absolute;
		top: 18px;
		right: 28px;
		margin: 0;
		background: #1e2e3b;
		padding: 5px 12px;
		color: #efb836;
		font: 300 16px 'RealTypeWriter';
	}
</style>
