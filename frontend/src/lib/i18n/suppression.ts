export const suppressionZhCN = {
	'newspaper.suppressionCount': '{count}次',
	'newspaper.suppress': '镇压'
} as const;

export const suppressionEn: Record<keyof typeof suppressionZhCN, string> = {
	'newspaper.suppressionCount': '{count} uses',
	'newspaper.suppress': 'Suppress'
};
