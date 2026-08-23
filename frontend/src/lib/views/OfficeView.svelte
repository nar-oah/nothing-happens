<script lang="ts">
	import ContextDetail from '$lib/components/detail/ContextDetail.svelte';
	import Left from '$lib/components/left/Left.svelte';
	import Newspaper from '$lib/components/newspaper/Newspaper.svelte';
	import GameStateDisplay from '$lib/components/state/GameStateDisplay.svelte';
	import Top from '$lib/components/top/Top.svelte';
	import {
		mockBaseline,
		mockLeftItems,
		mockObjectDetail,
		mockState,
		mockTopItems
	} from '$lib/demo/mock';

	let notice = $state('点击世界物品后，详情在右侧显示。');
	let topItems = $derived(
		mockTopItems.map((item) => ({
			...item,
			onSelect: () => (notice = `已展开：${item.item.text}`),
			onAction: () => (notice = `已触发 ${item.item.text} 的 mock action`)
		}))
	);
</script>

<main class="game-view" aria-label="办公室界面">
	<div class="left-slot">
		<Left
			items={mockLeftItems}
			baseline={mockBaseline}
			onItemSelect={(item) => (notice = `已选择 ${item.kind} #${item.ref.index}`)}
			onSynthesisConfirm={(result) =>
				(notice = `合成 callback：${result.refs.map((ref) => ref.index).join('、')}`)}
		/>
	</div>
	<Newspaper term={2} year={3} month={7} onOpen={() => (notice = '邸报 callback 已触发')} />
	<div class="top-slot"><Top items={topItems} /></div>
	<div class="detail-slot">
		<ContextDetail
			{...mockObjectDetail}
			onAction={(isRight) => (notice = `世界物品 mock action：${isRight ? '行动' : '概况'}`)}
		/>
	</div>
	<div class="state-slot"><GameStateDisplay {...mockState} /></div>
	<p class="notice" aria-live="polite">{notice}</p>
</main>

<style>
	.game-view { position: relative; height: 100vh; overflow: hidden; background: transparent; }
	.left-slot { position: absolute; inset: 150px auto 20px 24px; }
	.top-slot { position: absolute; top: 24px; right: 28px; }
	.detail-slot { position: absolute; top: 230px; right: 32px; }
	.state-slot { position: absolute; right: 32px; bottom: 30px; }
	.notice { position: absolute; left: 50%; bottom: 18px; margin: 0; transform: translateX(-50%); background: #1e2e3b; padding: 5px 12px; color: #efb836; font: 300 16px "RealTypeWriter"; }
</style>
