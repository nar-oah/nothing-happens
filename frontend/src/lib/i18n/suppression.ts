export const suppressionZhCN = {
	'newspaper.suppressionCount': '{count}次',
	'newspaper.suppress': '镇压',
	'newspaper.suppressionAction': '镇压（{count}次）',
	'newspaper.unsuppress': '不镇压',
	'newspaper.suppressionDescription':
		'朝廷乐意替听话守规矩的属国收拾麻烦。只要肯服从约法、按规矩办事，出了乱子，自会有人替你压下去。'
} as const;

export const suppressionEn: Record<keyof typeof suppressionZhCN, string> = {
	'newspaper.suppressionCount': '{count} uses',
	'newspaper.suppress': 'Suppress',
	'newspaper.suppressionAction': 'Suppress ({count} left)',
	'newspaper.unsuppress': 'Do not suppress',
	'newspaper.suppressionDescription':
		'The Court is happy to clean up trouble for obedient dependencies. Follow the constitution and the rules, and when disorder breaks out, someone will be sent to put it down for you.'
};
