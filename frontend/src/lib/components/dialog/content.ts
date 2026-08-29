export type InterestGroupDialogueContent = {
	visitor: string;
	body: string;
};

export type EventIntelDialogueData = {
	raceName: string;
	metricName: string;
	requirement: number;
	strength: number;
};

export function createInterestGroupDialogueContent(
	groupName: string,
	positiveEffect: string,
	donationOffer: string
): InterestGroupDialogueContent {
	return {
		visitor: `不愿意透露姓名的说客\n代表\n${groupName}\n而来`,
		body: `${groupName}愿意在手上这份提案里让一点利。\n您可以收下“${positiveEffect}”这项优惠，也可以把同样的好意折成${donationOffer}。`
	};
}

export function createEventIntelDialogueContent(data: EventIntelDialogueData): InterestGroupDialogueContent {
	const visitor = `不愿意透露姓名的消息人士\n代表\n${data.raceName}\n而来`;
	const body = formatEventIntelBody(data);
	return { visitor, body };
}

function formatEventIntelBody(data: EventIntelDialogueData): string {
	const { raceName, metricName, requirement, strength } = data;
	const common = `目前这件事大约已经走到${strength}%的程度，${metricName}至少要到${requirement}才够。`;
	switch (raceName) {
		case '人类':
			return `此事还没有见报，也不宜先惊动旁人。朝使内部已经有人为${metricName}催得很紧。\n${common}消息已经核过，等他们公开发难时，只会更难收拾。`;
		case '桃花妖':
			return `外头还没听见风声。桃源那边已经有人觉得${metricName}少得不像样了，只是还没有把话说到报馆去。\n${common}路还开着，话先送到了；你们若还想折腾，至少该知道自己在折腾什么。`;
		case '南柯':
			return `……刚才差点忘了。我在那边听见他们已经开始谈${metricName}了。\n${common}这不是梦里听来的，是现实里真的有人在催。`;
		case '比翼':
			return `先纠正一个说法：这还不是“公开事件”，只是已经可以确认的动向。争议集中在${metricName}。\n${common}数字我核过两遍；等报馆写出来时，问题只会更明确，不会更轻。`;
		case '偃偶':
			return `信息已经核验。关于${metricName}的异议正在形成，尚未进入公开阶段。\n${common}继续等待不会使这条信息失效，只会缩短可用的处理窗口。`;
		case '驻岁':
			return `别装作没看见。连我们都开始觉得${metricName}这件事不太对了。\n${common}现在还没闹到报纸上，不过你应该比谁都清楚，等别人替我们着急通常没什么好结果。`;
		default:
			return `这件事还没有公开，但消息已经核实。\n${common}等它登上报纸时，留给政府的时间只会更少。`;
	}
}
