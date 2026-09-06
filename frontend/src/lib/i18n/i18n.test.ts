import assert from 'node:assert/strict';
import test, { afterEach } from 'node:test';
import { CommandError } from '../bridge/protocol.ts';
import {
	formatNewspaperNumber,
	getNewspaperEventStateLabel,
	getNewspaperMetricLabel,
	getNewspaperRaceLabel,
	NewspaperEventState,
	NewspaperRace
} from '../components/newspaper/types.ts';
import {
	deriveTermReportFront,
	deriveTermReportMetrics
} from '../components/newspaper/term-report.ts';
import { getNewspaperComments } from '../content/newspaper-comments.ts';
import { getMetricDisplayName } from '../game/rules.ts';
import { deriveSaveItems } from '../game/state/saves.ts';
import { Metric } from '../game/types.ts';
import { dictionaries, language, t, translate, type Translate } from './index.ts';
import { translateCommandError } from './live.ts';

const zh: Translate = (key, params) => translate(key, params, 'zh_CN');
const en: Translate = (key, params) => translate(key, params, 'en');

afterEach(() => language.set('zh_CN'));

test('Chinese and English dictionaries contain matching keys and interpolation parameters', () => {
	const keys = Object.keys(dictionaries.zh_CN).sort();
	assert.deepEqual(Object.keys(dictionaries.en).sort(), keys);
	const parameters = (value: string) =>
		[...value.matchAll(/\{(\w+)\}/g)].map((match) => match[1]).sort();
	for (const key of keys) {
		assert.deepEqual(parameters(dictionaries.zh_CN[key]), parameters(dictionaries.en[key]), key);
		assert.doesNotMatch(dictionaries.en[key], /\p{Script=Han}/u, key);
	}
});

test('translation interpolates values including zero and preserves unknown keys', () => {
	assert.equal(zh('newspaper.aria', { year: 2, month: 0 }), '第 2 年 0 月弦外报');
	assert.equal(en('newspaper.aria', { year: 2, month: 0 }), 'Xianwai Times, year 2, month 0');
	assert.equal(en('missing.key'), 'missing.key');
});

test('changing language immediately delivers a new translator to current subscribers', () => {
	const received: Translate[] = [];
	const unsubscribe = t.subscribe((translator) => received.push(translator));
	assert.equal(received[0]('newspaper.nextAria'), '进入次月');
	language.set('en');
	assert.equal(received.length, 2);
	assert.notEqual(received[0], received[1]);
	assert.equal(received[1]('newspaper.nextAria'), 'Advance to the next month');
	assert.equal(translate('newspaper.nextAria'), 'Advance to the next month');
	language.set('zh_CN');
	assert.equal(received[2]('newspaper.nextAria'), '进入次月');
	unsubscribe();
});

test('newspaper labels and negotiation month follow the supplied language', () => {
	assert.equal(getNewspaperMetricLabel(Metric.TAX, zh), '税課');
	assert.equal(getNewspaperMetricLabel(Metric.TAX, en), 'Tax');
	assert.equal(getNewspaperRaceLabel(NewspaperRace.HUMAN, zh), '人类');
	assert.equal(getNewspaperRaceLabel(NewspaperRace.HUMAN, en), 'Humans');
	assert.equal(getNewspaperEventStateLabel(NewspaperEventState.CALM, zh), '平息 ↓');
	assert.equal(getNewspaperEventStateLabel(NewspaperEventState.CALM, en), 'Easing ↓');
	assert.equal(formatNewspaperNumber(0, zh), '談判');
	assert.equal(formatNewspaperNumber(0, en), 'Talks');
	assert.equal(formatNewspaperNumber(3, en), '03');
	assert.equal(getMetricDisplayName(Metric.INVESTMENT, en), 'Investment');
});

test('term report and all newspaper commentary translate without changing their values or order', () => {
	const report = {
		outcome: 'NOTHING_HAPPENS' as const,
		previous_governing_months: 25,
		current_governing_months: 39
	};
	assert.equal(deriveTermReportFront(report, zh).title, '无事发生');
	assert.equal(deriveTermReportFront(report, en).title, 'Nothing Happens');
	assert.deepEqual(deriveTermReportMetrics(report, zh), [
		{ metric: '執政年數', value: 2, change: 1 },
		{ metric: '執政月數', value: 1, change: 2 }
	]);
	assert.deepEqual(deriveTermReportMetrics(report, en), [
		{ metric: 'Years in office', value: 2, change: 1 },
		{ metric: 'Months in office', value: 1, change: 2 }
	]);
	const chinese = getNewspaperComments(zh);
	const english = getNewspaperComments(en);
	assert.equal(chinese.length, 19);
	assert.equal(english.length, chinese.length);
	for (const [index, comment] of english.entries()) {
		assert.equal(comment.title, en(`newspaper.comment.${index}.title`));
		assert.equal(comment.comment, en(`newspaper.comment.${index}.body`));
		assert.notEqual(comment.title, chinese[index].title);
		assert.notEqual(comment.comment, chinese[index].comment);
	}
});

test('save labels translate while save commands retain the same slot identity', () => {
	const current = { term: 2, year: 3, month: 4 };
	const chinese = deriveSaveItems([], current, false, zh)[0];
	const english = deriveSaveItems([], current, false, en)[0];
	assert.deepEqual(chinese.item, { text: '第 2 任', value: '3 年 4 月' });
	assert.deepEqual(english.item, { text: 'Term 2', value: 'Year 3, month 4' });
	assert.deepEqual(chinese.slot, english.slot);
});

test('an existing command error updates when the current translator changes', () => {
	const error = new CommandError({ code: 'save_write_failed', message: 'Backend diagnostic' });
	const messages: string[] = [];
	const unsubscribe = t.subscribe((translator) => {
		messages.push(translateCommandError(error, translator));
	});
	assert.equal(messages[0], '无法写入存档，原存档已保留。');
	language.set('en');
	assert.equal(messages[1], 'Unable to write the save. The previous save has been kept.');
	assert.equal(translateCommandError(new Error('Internal details'), en), 'The operation failed. Please try again.');
	unsubscribe();
});
