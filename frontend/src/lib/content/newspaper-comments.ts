import { translate, type Translate } from '../i18n/index.ts';

export type NewspaperComment = {
	title: string;
	comment: string;
};

export function getNewspaperComments(translator: Translate = translate): NewspaperComment[] {
	return Array.from({ length: 19 }, (_, index) => ({
		title: translator(`newspaper.comment.${index}.title`),
		comment: translator(`newspaper.comment.${index}.body`)
	}));
}

export const NEWSPAPER_COMMENTS: NewspaperComment[] = getNewspaperComments(
	(key, params) => translate(key, params, 'zh_CN')
);
