import { translate, type Translate } from '../../i18n/index.ts';

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
	donationOffer: string,
	translator: Translate = translate
): InterestGroupDialogueContent {
	return {
		visitor: translator('dialogue.groupVisitor', { group: groupName }),
		body: translator('dialogue.groupBody', { group: groupName, effect: positiveEffect, donation: donationOffer })
	};
}

export function createEventIntelDialogueContent(data: EventIntelDialogueData, translator: Translate = translate): InterestGroupDialogueContent {
	const visitor = translator('dialogue.intelVisitor', { race: data.raceName });
	const body = formatEventIntelBody(data, translator);
	return { visitor, body };
}

function formatEventIntelBody(data: EventIntelDialogueData, translator: Translate): string {
	const { raceName, metricName, requirement, strength } = data;
	const common = translator('dialogue.intelCommon', { strength, metric: metricName, requirement });
	switch (raceName) {
		case '人类':
			return translator('dialogue.intelHuman', { metric: metricName, common });
		case '桃花妖':
			return translator('dialogue.intelPeach', { metric: metricName, common });
		case '南柯':
			return translator('dialogue.intelNanke', { metric: metricName, common });
		case '比翼':
			return translator('dialogue.intelBiyi', { metric: metricName, common });
		case '偃偶':
			return translator('dialogue.intelYanou', { metric: metricName, common });
		case '驻岁':
			return translator('dialogue.intelZhushui', { metric: metricName, common });
		default:
			return translator('dialogue.intelDefault', { metric: metricName, common });
	}
}
