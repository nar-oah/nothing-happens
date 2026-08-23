import type { ContextDetailData } from '../detail/detail';

export type TopItemData = {
	key: string;
	item: {
		text: string;
		value?: string | number;
		limit?: number;
	};
	detail: Omit<ContextDetailData, 'title'>;
	payload?: unknown;
	onSelect?: (payload: unknown) => void;
};
