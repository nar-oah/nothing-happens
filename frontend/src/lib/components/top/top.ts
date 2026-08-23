export type TopItemData = {
	key: string;
	item: {
		text: string;
		value?: string | number;
		limit?: number;
	};
	detail: {
		leftLabel: string;
		rightLabel: string;
		leftBody: string;
		rightBody: string;
		actionLabel?: string;
	};
	payload?: unknown;
	onSelect?: (payload: unknown) => void;
	onAction?: (payload: unknown, isRight: boolean) => void;
};
