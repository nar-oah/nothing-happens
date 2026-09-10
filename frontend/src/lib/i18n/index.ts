import { derived, get, writable } from 'svelte/store';
import { componentsZhCN, componentsEn } from './components.ts';
import { gameZhCN, gameEn } from './game.ts';
import { liveZhCN, liveEn } from './live.ts';
import { parliamentZhCN, parliamentEn } from './parliament.ts';
import { policyZhCN, policyEn } from './policy.ts';
import { suppressionZhCN, suppressionEn } from './suppression.ts';

export type Language = 'zh_CN' | 'en';
export type Translate = (key: string, params?: Record<string, string | number>) => string;

export const dictionaries: Record<Language, Record<string, string>> = {
	zh_CN: {
		...componentsZhCN,
		...gameZhCN,
		...liveZhCN,
		...parliamentZhCN,
		...policyZhCN,
		...suppressionZhCN
	},
	en: {
		...componentsEn,
		...gameEn,
		...liveEn,
		...parliamentEn,
		...policyEn,
		...suppressionEn
	}
};

export const language = writable<Language>('zh_CN');

export function translate(
	key: string,
	params: Record<string, string | number> = {},
	locale: Language = get(language)
): string {
	const template = dictionaries[locale][key] ?? dictionaries.zh_CN[key] ?? key;
	return template.replace(/\{(\w+)\}/g, (placeholder, name: string) =>
		params[name] === undefined ? placeholder : String(params[name])
	);
}

export const t = derived(
	language,
	(locale): Translate =>
		(key, params) =>
			translate(key, params, locale)
);
