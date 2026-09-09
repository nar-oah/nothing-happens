import assert from 'node:assert/strict';
import test from 'node:test';
import type { SeatVoteDto } from '../game/state/types.ts';
import {
	ABSENT_POSITION,
	deriveLocalVote,
	donationTotal,
	seatActionText,
	seatScoreText,
	toggleBribedSeat
} from './parliament.ts';

const vote = (overrides: Partial<SeatVoteDto> = {}): SeatVoteDto => ({
	seat_index: 0,
	seat_display_name: '席位',
	race_display_name: '普通种族',
	interest_group_display_name: '集团',
	position: 2,
	score: 0,
	bribe_allowed: true,
	bribe_cost: 1,
	vote_weight: 1,
	breakdown: {},
	...overrides
});

test('local donations toggle, charge, refund, and affect only final submission state', () => {
	const votes = [vote()];
	const selected = toggleBribedSeat([], votes[0], votes, 1);
	assert.deepEqual(selected, [0]);
	assert.equal(donationTotal(votes, selected), 1);
	assert.equal(deriveLocalVote(votes, selected).seatVotes[0].position, 3);
	const cancelled = toggleBribedSeat(selected, votes[0], votes, 1);
	assert.deepEqual(cancelled, []);
	assert.equal(donationTotal(votes, cancelled), 0);
});

test('absent and authoritative non-bribable seats reject local donations', () => {
	const absent = vote({ position: ABSENT_POSITION, score: 10, bribe_allowed: false });
	const yanou = vote({ seat_index: 1, race_display_name: '偃偶', bribe_allowed: false });
	assert.deepEqual(toggleBribedSeat([], absent, [absent, yanou], 10), []);
	assert.deepEqual(toggleBribedSeat([], yanou, [absent, yanou], 10), []);
	assert.equal(seatActionText(absent, '支持', '政治献金', '缺席'), '缺席');
});

test('Peach seats show weights and local bribery updates the shared majority', () => {
	const votes = [
		vote({
			position: 3,
			score: 1,
			bribe_allowed: false,
			vote_weight: 4,
			race_display_name: '桃花妖',
			race_support_weight: 4,
			race_present_weight: 7
		}),
		vote({
			seat_index: 1,
			score: -1,
			bribe_cost: 2,
			vote_weight: 2,
			race_display_name: '桃花妖',
			race_support_weight: 4,
			race_present_weight: 7
		}),
		vote({
			seat_index: 2,
			position: ABSENT_POSITION,
			bribe_allowed: false,
			vote_weight: 1,
			race_display_name: '桃花妖',
			race_support_weight: 4,
			race_present_weight: 7
		})
	];
	assert.equal(seatScoreText(votes[1]), '-1（4/7）');
	assert.equal(seatActionText(votes[1], '支持', '政治献金', '缺席'), '政治献金（2）');
	const local = deriveLocalVote(votes, [1]);
	assert.equal(local.seatVotes[0].race_support_weight, 6);
	assert.equal(local.seatVotes[1].race_present_weight, 6);
	assert.equal(local.supportCount, 2);
	assert.equal(local.absentCount, 1);
	assert.equal(local.presentCount, 2);
	assert.equal(local.passed, true);
});

test('Peach consensus applies to every present seat instead of one race vote', () => {
	const votes = [
		vote({
			position: 2,
			vote_weight: 2,
			race_display_name: '桃花妖',
			race_support_weight: 1,
			race_present_weight: 3
		}),
		vote({
			seat_index: 1,
			position: 3,
			bribe_allowed: false,
			vote_weight: 1,
			race_display_name: '桃花妖',
			race_support_weight: 1,
			race_present_weight: 3
		})
	];
	const tied = deriveLocalVote(votes, []);
	assert.equal(tied.supportCount, 0);
	assert.equal(tied.abstainCount, 2);
	assert.equal(tied.presentCount, 2);
	assert.equal(tied.passed, false);
	const secured = deriveLocalVote(votes, [0]);
	assert.equal(secured.supportCount, 2);
	assert.equal(secured.abstainCount, 0);
	assert.equal(secured.presentCount, 2);
	assert.equal(secured.passed, true);
});
