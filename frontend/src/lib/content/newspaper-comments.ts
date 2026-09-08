import { translate, type Translate } from '../i18n/index.ts';
import type { UiMode } from '../game/state/types.ts';

export type NewspaperComment = {
	id: number;
	title: string;
	comment: string;
};

type NewspaperCommentContext = UiMode | 'common';
type NewspaperCommentDefinition = {
	id: number;
	context: NewspaperCommentContext;
};

const COMMENT_DEFINITIONS: NewspaperCommentDefinition[] = [
	{ id: 0, context: 'office' },
	{ id: 3, context: 'office' },
	{ id: 5, context: 'office' },
	{ id: 6, context: 'office' },
	{ id: 8, context: 'office' },
	{ id: 18, context: 'office' },
	{ id: 1, context: 'dialogue' },
	{ id: 7, context: 'dialogue' },
	{ id: 4, context: 'parliament' },
	{ id: 9, context: 'parliament' },
	{ id: 10, context: 'parliament' },
	{ id: 11, context: 'parliament' },
	{ id: 12, context: 'parliament' },
	{ id: 13, context: 'parliament' },
	{ id: 14, context: 'parliament' },
	{ id: 16, context: 'parliament' },
	{ id: 15, context: 'constitution' },
	{ id: 2, context: 'common' },
	{ id: 17, context: 'common' }
];

function translateComment(definition: NewspaperCommentDefinition, translator: Translate): NewspaperComment {
	return {
		id: definition.id,
		title: translator(`newspaper.comment.${definition.id}.title`),
		comment: translator(`newspaper.comment.${definition.id}.body`)
	};
}

export function getNewspaperComments(
	context: UiMode,
	translator: Translate = translate
): NewspaperComment[] {
	const contextual = COMMENT_DEFINITIONS.filter((definition) => definition.context === context);
	const common = COMMENT_DEFINITIONS.filter((definition) => definition.context === 'common');
	return [...contextual, ...common].map((definition) => translateComment(definition, translator));
}
