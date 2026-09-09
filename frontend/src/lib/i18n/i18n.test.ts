import assert from 'node:assert/strict';
import test, { afterEach } from 'node:test';
import { getNewspaperComments } from '../content/newspaper-comments.ts';
import { dictionaries, language, t, translate, type Translate } from './index.ts';

const en: Translate = (key, params) => translate(key, params, 'en');

afterEach(() => language.set('zh_CN'));

test('Chinese and English dictionaries keep the same keys and interpolation parameters', () => {
	const keys = Object.keys(dictionaries.zh_CN).sort();
	assert.deepEqual(Object.keys(dictionaries.en).sort(), keys);
	const parameters = (value: string) =>
		[...value.matchAll(/\{(\w+)\}/g)].map((match) => match[1]).sort();
	for (const key of keys) {
		assert.deepEqual(parameters(dictionaries.zh_CN[key]), parameters(dictionaries.en[key]), key);
		assert.doesNotMatch(dictionaries.en[key], /\p{Script=Han}/u, key);
	}
});

test('changing language updates the active translator', () => {
	const received: Translate[] = [];
	const unsubscribe = t.subscribe((translator) => received.push(translator));
	assert.equal(received[0]('newspaper.nextAria'), '进入次月');
	language.set('en');
	assert.equal(received[1]('newspaper.nextAria'), 'Advance to the next month');
	assert.equal(translate('newspaper.nextAria'), 'Advance to the next month');
	unsubscribe();
});

test('newspaper comments prioritize the current view and translate without changing identity', () => {
	const expectedFirst = {
		office: 0,
		dialogue: 1,
		parliament: 4,
		constitution: 15
	} as const;
	for (const [context, firstId] of Object.entries(expectedFirst)) {
		const comments = getNewspaperComments(context as keyof typeof expectedFirst, en);
		assert.equal(comments[0]?.id, firstId);
		assert.equal(comments[0]?.title, en(`newspaper.comment.${firstId}.title`));
		assert.equal(comments[0]?.comment, en(`newspaper.comment.${firstId}.body`));
	}
});
