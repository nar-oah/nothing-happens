export const suppressionZhCN = {
	'newspaper.suppressionCount': '{count}次',
	'newspaper.suppress': '镇压',
	'newspaper.suppressionAction': '镇压（{count}次）',
	'newspaper.unsuppress': '不镇压',
	'newspaper.suppressionDescription':
		'朝廷素来体恤恭顺诸邦，凡能遵制听命者，偶有难处，自当代为弹压料理，免使小患滋蔓。'
} as const;

export const suppressionEn: Record<keyof typeof suppressionZhCN, string> = {
	'newspaper.suppressionCount': '{count} uses',
	'newspaper.suppress': 'Suppress',
	'newspaper.suppressionAction': 'Suppress ({count} left)',
	'newspaper.unsuppress': 'Do not suppress',
	'newspaper.suppressionDescription':
		'The Court has ever shown favor to obedient dependencies; those who observe its ordinances may have their troubles put down before small disorders are allowed to spread.'
};
