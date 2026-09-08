import assert from 'node:assert/strict';
import test from 'node:test';
import { clampNumberEditorValue } from './chore.ts';

test('number editor values clamp to the configured range', () => {
	assert.equal(clampNumberEditorValue(11, 0, 10), 10);
	assert.equal(clampNumberEditorValue(-1, 0, 10), 0);
	assert.equal(clampNumberEditorValue(4, 0, 10), 4);
	assert.equal(clampNumberEditorValue(7, 10, 2), 7);
});
