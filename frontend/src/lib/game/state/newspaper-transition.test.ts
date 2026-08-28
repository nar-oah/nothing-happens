import assert from 'node:assert/strict';
import test from 'node:test';
import {
	coverNewspaperTransition,
	createNewspaperTransitionState,
	finishNewspaperTransition,
	leaveNewspaperTransition,
	openNewspaperTransition,
	type DisplayedNewspaperData
} from './newspaper-transition.ts';

const monthly: DisplayedNewspaperData = {
	mode: 'MONTHLY',
	term: 1,
	year: 2,
	month: 7,
	metrics: [],
	events: [],
	comment: { title: 'old', comment: 'monthly' }
};
const termEnd: DisplayedNewspaperData = {
	mode: 'TERM_END',
	term: 1,
	year: 2,
	month: 7,
	governingMonths: 19,
	termOutcome: 'NOTHING_HAPPENS',
	metrics: [],
	events: [],
	comment: { title: '', comment: '' }
};

test('terminal snapshot waits for the old newspaper leaving animation', () => {
	let state = openNewspaperTransition(createNewspaperTransitionState(), monthly);
	state = coverNewspaperTransition(state);
	const leaving = leaveNewspaperTransition(state, termEnd);

	assert.equal(leaving.displayedNewspaperData, monthly);
	assert.equal(leaving.pendingNewspaperData, termEnd);
	assert.equal(leaving.backgroundCovered, true);
	assert.equal(leaving.leaving, true);
});

test('leaving completion swaps terminal data and starts the same view entering again', () => {
	let state = openNewspaperTransition(createNewspaperTransitionState(), monthly);
	state = coverNewspaperTransition(state);
	state = leaveNewspaperTransition(state, termEnd);
	const previousCycle = state.entryCycle;
	state = finishNewspaperTransition(state);

	assert.equal(state.displayedNewspaperData, termEnd);
	assert.equal(state.pendingNewspaperData, null);
	assert.equal(state.leaving, false);
	assert.equal(state.open, true);
	assert.equal(state.backgroundCovered, true);
	assert.equal(state.entryCycle, previousCycle + 1);
});

test('ordinary newspaper leaving removes the background and closes normally', () => {
	let state = openNewspaperTransition(createNewspaperTransitionState(), monthly);
	state = coverNewspaperTransition(state);
	state = leaveNewspaperTransition(state);

	assert.equal(state.backgroundCovered, false);
	assert.equal(state.pendingNewspaperData, null);
	state = finishNewspaperTransition(state);
	assert.equal(state.open, false);
	assert.equal(state.backgroundCovered, false);
});
