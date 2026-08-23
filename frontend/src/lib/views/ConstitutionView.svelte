<script lang="ts">
	import { MemorialVerticalConstitution } from '$lib/components/memorial';
	import GameStateDisplay from '$lib/components/state/GameStateDisplay.svelte';
	import Top from '$lib/components/top/Top.svelte';
	import { mockConstitution, mockTopItems } from '$lib/demo/mock';

	let notice = $state('约法编辑使用本地 mock 数据，不执行年度结算。');
	let topItems = $derived(
		mockTopItems.map((item) => ({
			...item,
			onSelect: () => (notice = `约法 Top：${item.item.text}`),
			onAction: () => (notice = `${item.item.text} 信息 callback`)
		}))
	);
</script>

<main class="game-view" aria-label="约法界面">
	<div class="top-slot"><Top items={topItems} /></div>
	<div class="state-slot">
		<GameStateDisplay
			primary={{ text: '年序', value: 3, limit: 5 }}
			secondary={{ text: '解锁', value: 2, limit: 5 }}
		/>
	</div>
	<div class="constitution">
		<MemorialVerticalConstitution title="蓬莱约法" constitution={mockConstitution} />
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
	.top-slot {
		position: absolute;
		top: 24px;
		right: 28px;
	}
	.state-slot {
		position: absolute;
		right: 32px;
		bottom: 30px;
	}
	.constitution {
		position: absolute;
		left: 50%;
		top: 52%;
		transform: translate(-50%, -50%) scale(0.95);
		transform-origin: center;
	}
	.notice {
		position: absolute;
		left: 28px;
		bottom: 24px;
		margin: 0;
		background: #1e2e3b;
		padding: 5px 12px;
		color: #efb836;
		font: 300 16px 'RealTypeWriter';
	}
</style>
