import type { SeatVoteDto } from '../game/state/types.ts';

export const ABSENT_POSITION = 0;
export const OPPOSE_POSITION = 1;
export const ABSTAIN_POSITION = 2;
export const SUPPORT_POSITION = 3;

export type LocalVotePreview = {
	seatVotes: SeatVoteDto[];
	supportCount: number;
	opposeCount: number;
	abstainCount: number;
	absentCount: number;
	presentCount: number;
	passed: boolean;
};

export function isPeachVote(vote: SeatVoteDto): boolean {
	return vote.race_support_weight !== undefined && vote.race_present_weight !== undefined;
}

export function donationTotal(seatVotes: SeatVoteDto[], bribedSeats: number[]): number {
	const selected = new Set(bribedSeats);
	return seatVotes.reduce(
		(total, vote) => total + (selected.has(vote.seat_index) ? vote.bribe_cost : 0),
		0
	);
}

export function toggleBribedSeat(
	bribedSeats: number[],
	vote: SeatVoteDto,
	seatVotes: SeatVoteDto[],
	donationPool: number
): number[] {
	if (bribedSeats.includes(vote.seat_index))
		return bribedSeats.filter((seatIndex) => seatIndex !== vote.seat_index);
	if (
		!vote.bribe_allowed ||
		vote.position === ABSENT_POSITION ||
		vote.position === SUPPORT_POSITION ||
		donationTotal(seatVotes, bribedSeats) + vote.bribe_cost > donationPool
	)
		return bribedSeats;
	return [...bribedSeats, vote.seat_index];
}

export function deriveLocalVote(
	seatVotes: SeatVoteDto[],
	bribedSeats: number[]
): LocalVotePreview {
	const selected = new Set(bribedSeats);
	const localVotes: SeatVoteDto[] = seatVotes.map((vote): SeatVoteDto =>
		selected.has(vote.seat_index) && vote.bribe_allowed
			? { ...vote, score: vote.score + vote.bribe_cost, position: SUPPORT_POSITION }
			: { ...vote }
	);
	let supportCount = 0;
	let opposeCount = 0;
	let abstainCount = 0;
	let absentCount = 0;
	const peachGroups = new Map<string, SeatVoteDto[]>();
	for (const vote of localVotes) {
		if (isPeachVote(vote)) {
			const votes = peachGroups.get(vote.race_display_name) ?? [];
			votes.push(vote);
			peachGroups.set(vote.race_display_name, votes);
			continue;
		}
		if (vote.position === SUPPORT_POSITION) supportCount += 1;
		else if (vote.position === OPPOSE_POSITION) opposeCount += 1;
		else if (vote.position === ABSTAIN_POSITION) abstainCount += 1;
		else absentCount += 1;
	}
	for (const votes of peachGroups.values()) {
		const present = votes.filter((vote) => vote.position !== ABSENT_POSITION);
		const presentWeight = present.reduce((total, vote) => total + vote.vote_weight, 0);
		const supportWeight = present.reduce(
			(total, vote) => total + (vote.position === SUPPORT_POSITION ? vote.vote_weight : 0),
			0
		);
		for (const vote of votes) {
			vote.race_support_weight = supportWeight;
			vote.race_present_weight = presentWeight;
		}
		if (presentWeight === 0) absentCount += 1;
		else if (supportWeight * 2 > presentWeight) supportCount += 1;
		else abstainCount += 1;
	}
	const presentCount = supportCount + opposeCount + abstainCount;
	return {
		seatVotes: localVotes,
		supportCount,
		opposeCount,
		abstainCount,
		absentCount,
		presentCount,
		passed: presentCount > 0 && supportCount * 2 > presentCount
	};
}

export function seatScoreText(vote: SeatVoteDto): string {
	if (vote.position === ABSENT_POSITION) return '';
	const score = String(vote.score);
	return isPeachVote(vote)
		? `${score}（${vote.race_support_weight}/${vote.race_present_weight}）`
		: score;
}

export function seatActionText(
	vote: SeatVoteDto,
	supportLabel: string,
	bribeLabel: string,
	absentLabel: string
): string {
	if (vote.position === ABSENT_POSITION) return absentLabel;
	const label = vote.position === SUPPORT_POSITION ? supportLabel : bribeLabel;
	return isPeachVote(vote) ? `${label}（${vote.vote_weight}）` : label;
}
