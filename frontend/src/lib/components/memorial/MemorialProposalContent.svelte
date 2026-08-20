<script lang="ts">
	type Props = {
		title?: string;
		body?: string;
	};

	let {
		title = '永乐轮运局',
		body = '测试测试测试测试测试测试测试测试'
	}: Props = $props();
</script>

<div class="flex h-[345px] w-[123px] gap-5 overflow-hidden text-ink-primary">
	<div
		class="box-border flex h-full w-[36px] shrink-0 flex-col items-center gap-[20px] overflow-hidden bg-ink-primary px-[6px] py-8 text-surface-amber [word-break:break-word]"
	>
		<span class="font-archival text-24 font-normal leading-auto">◆</span>
		<p class="m-0 w-24 text-center font-document text-24 font-light leading-auto">{title}</p>
	</div>
	<div class="box-border flex min-w-0 flex-1 items-center justify-center py-8">
		<p class="typo-document-body-compact m-0 w-full text-center [word-break:break-word]">
			{body}
		</p>
	</div>
</div>
