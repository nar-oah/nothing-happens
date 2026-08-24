import type { LeftItem } from '../components/left/types';
import type { StateItem } from '../components/state/GameStateDisplay.svelte';
import type { TopItemData } from '../components/top/top';
import type { MetricValues } from '../game';

export type ViewFrameProps = {
	items: LeftItem[];
	baseline: MetricValues;
	raceItems: TopItemData[];
	interestGroupItems: TopItemData[];
	gameState: { primary: StateItem; secondary: StateItem };
	term: number;
	year: number;
	month: number;
	onNewspaperOpen?: () => void;
};

export type DialoguePresentation = {
	handIndex: number;
	groupName: string;
	positiveEffect: string;
	donationOffer: string;
};
