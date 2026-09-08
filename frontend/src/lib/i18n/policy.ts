export const policyZhCN = {
	'mark.gap': '落差',
	'mark.smoothing': '平抑',
	'mark.viewGap': '查看落差面',
	'mark.viewSmoothing': '查看平抑面',
	'mark.noFormula': '无公式',
	'memorial.gap': '落差',
	'memorial.smoothing': '平抑'
} as const;

export const policyEn: Record<keyof typeof policyZhCN, string> = {
	'mark.gap': 'Gap',
	'mark.smoothing': 'Stabilization',
	'mark.viewGap': 'View gap face',
	'mark.viewSmoothing': 'View stabilization face',
	'mark.noFormula': 'No formula',
	'memorial.gap': 'Gap',
	'memorial.smoothing': 'Stabilization'
};
