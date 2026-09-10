import assert from 'node:assert/strict';
import test from 'node:test';
import type { SeatVoteDto } from '../game/state/types.ts';
import { parliamentEn, parliamentZhCN } from '../i18n/parliament.ts';
import {
	ABSENT_POSITION,
	canSubmitDraft,
	deriveLocalVote,
	donationTotal,
	peachVotesNeeded,
	seatActionText,
	seatScoreText,
	submittedDonationSeats,
	toggleBribedSeat,
	votesNeededForMajority
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

const format = (template: string, params: Record<string, string | number>): string =>
	template.replace(/\{(\w+)\}/g, (placeholder, name: string) =>
		params[name] === undefined ? placeholder : String(params[name])
	);

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
	assert.equal(seatActionText(absent, '支持', '政治献金', '缺席', ''), '缺席');
});

test('draft submission requires a passable vote and at least one proposal', () => {
	assert.equal(canSubmitDraft(true, 1), true);
	assert.equal(canSubmitDraft(true, 0), false);
	assert.equal(canSubmitDraft(false, 1), false);
});

test('submission uses the backend minimum plan only when local selections do not pass', () => {
	const automaticPlan = { seat_indices: [4, 1] };
	assert.deepEqual(submittedDonationSeats(false, [3], automaticPlan), [4, 1]);
	assert.deepEqual(submittedDonationSeats(true, [3], automaticPlan), [3]);
	assert.equal(submittedDonationSeats(false, [3], null), null);
});

test('strict-majority shortfall uses the same calculation for weighted and ordinary votes', () => {
	assert.equal(votesNeededForMajority(2, 4), 1);
	assert.equal(votesNeededForMajority(3, 4), 0);
	assert.equal(votesNeededForMajority(1, 3), 1);
	assert.equal(votesNeededForMajority(2, 3), 0);
});

test('Peach seats show localized weights and shortfall while local bribery updates the shared majority', () => {
	const votes = [
		vote({
			position: 3,
			score: 1,
			bribe_allowed: false,
			vote_weight: 2,
			race_display_name: '桃花妖',
			race_support_weight: 2,
			race_present_weight: 4
		}),
		vote({
			seat_index: 1,
			score: -1,
			bribe_cost: 2,
			vote_weight: 2,
			race_display_name: '桃花妖',
			race_support_weight: 2,
			race_present_weight: 4
		}),
		vote({
			seat_index: 2,
			position: ABSENT_POSITION,
			bribe_allowed: false,
			vote_weight: 1,
			race_display_name: '桃花妖',
			race_support_weight: 2,
			race_present_weight: 4
		})
	];
	const before = deriveLocalVote(votes, []);
	const target = before.seatVotes[1];
	const zhWeight = format(parliamentZhCN['view.voteWeight'], { weight: target.vote_weight });
	const zhShort = format(parliamentZhCN['view.votesShort'], { count: peachVotesNeeded(target) });
	const enWeight = format(parliamentEn['view.voteWeight'], { weight: target.vote_weight });
	const enShort = format(parliamentEn['view.votesShort'], { count: peachVotesNeeded(target) });
	assert.equal(peachVotesNeeded(target), 1);
	assert.equal(seatScoreText(target, zhWeight), '-1(权重2)');
	assert.equal(seatActionText(target, '支持', '政治献金', '缺席', zhShort), '政治献金(差1票)');
	assert.equal(seatScoreText(target, enWeight), '-1(Weight 2)');
	assert.equal(seatActionText(target, 'Support', 'Bribe', 'Absent', enShort), 'Bribe(1 votes short)');
	const local = deriveLocalVote(votes, [1]);
	assert.equal(local.seatVotes[0].race_support_weight, 4);
	assert.equal(local.seatVotes[1].race_present_weight, 4);
	assert.equal(peachVotesNeeded(local.seatVotes[1]), 0);
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
	assert.equal(peachVotesNeeded(tied.seatVotes[0]), 1);
	assert.equal(tied.supportCount, 0);
	assert.equal(tied.abstainCount, 2);
	assert.equal(tied.presentCount, 2);
	assert.equal(tied.passed, false);
	const secured = deriveLocalVote(votes, [0]);
	assert.equal(peachVotesNeeded(secured.seatVotes[0]), 0);
	assert.equal(secured.supportCount, 2);
	assert.equal(secured.abstainCount, 0);
	assert.equal(secured.presentCount, 2);
	assert.equal(secured.passed, true);
});
