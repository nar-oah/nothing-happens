import type {
	Bill,
	ConstitutionArticle,
	InterestGroupDefinition,
	Metric,
	MetricValues,
	PolicyDefinition,
	Proposal
} from '../types.ts';

export type UiMode = 'office' | 'dialogue' | 'parliament' | 'constitution';
export type WorldScene = 'office' | 'parliament';
export type MetricDirection = -1 | 0 | 1;

export type ConstitutionArticleDto = ConstitutionArticle & {
	article_index: number;
};

export type ConstitutionArticleStateDto = ConstitutionArticleDto & {
	race_display_name: string;
	active: boolean;
	selected: boolean;
	clicked: boolean;
	eligible: boolean;
};

export type ConstitutionDto = {
	title: string;
	revision_available: boolean;
	active_articles: ConstitutionArticleDto[];
	articles: ConstitutionArticleStateDto[];
};

export type RaceExpectationDto = {
	metric: Metric;
	target: number;
	direction: MetricDirection;
};

export type RaceSummaryDto = {
	race_index: number;
	display_name: string;
	seat_count: number;
	expectations: RaceExpectationDto[];
	resolved_events_this_year: number;
	last_year_resolved_events: number;
};

export type InterestGroupSummaryDto = InterestGroupDefinition & {
	influence_count: number;
	influence_rate: number;
};

export type SeatSummaryDto = {
	seat_index: number;
	display_name: string;
	race_display_name: string;
	interest_group_display_name: string;
	personal_relation: number;
};

export type ParliamentCountDto = {
	display_name: string;
	seat_count: number;
};

export type ParliamentInfluenceDto = {
	display_name: string;
	influence_count: number;
	influence_rate: number;
};

export type ParliamentSummaryDto = {
	total_seats: number;
	race_seat_counts: ParliamentCountDto[];
	interest_group_influence: ParliamentInfluenceDto[];
};

export type SeatVoteDto = {
	seat_index: number;
	seat_display_name: string;
	race_display_name: string;
	interest_group_display_name: string;
	position: 0 | 1 | 2 | 3;
	score: number;
	breakdown: Record<string, number>;
};

export type VoteResultDto = {
	passed: boolean;
	submitted: boolean;
	support_count: number;
	oppose_count: number;
	abstain_count: number;
	absent_count: number;
	present_count: number;
	seat_votes: SeatVoteDto[];
};

export type DraftPreviewDto = {
	current_metrics: MetricValues;
	pure_proposal_target: MetricValues;
	immediate_policy_result: MetricValues;
	vote: VoteResultDto;
};

export type PendingDialogueDto = {
	hand_index: number;
	proposal: Proposal;
};

export type ActiveProposalDto = {
	proposal: Proposal;
	digested_months: number;
	digestion_progress: number;
	fully_digested: boolean;
};

export type ActivePolicyDto = {
	definition: PolicyDefinition;
	triggered: boolean;
};

export type ActiveBillDto = {
	title: string;
	start_values: MetricValues;
	pure_target: MetricValues;
	proposals: ActiveProposalDto[];
	policies: ActivePolicyDto[];
};

export type GameStatusDto = {
	year: number;
	month: number;
	metrics: MetricValues;
	political_donation_pool: number;
	collapse_level: number;
	max_collapse: number;
	run_failed?: boolean;
	ending_id?: string;
};

export type LiveGameState = GameStatusDto & {
	state_version: number;
	ui_mode: UiMode;
	world_scene: WorldScene;
	term: number;
	proposal_hand: Proposal[];
	saved_bills: Bill[];
	draft_bill: Bill;
	editing_saved_bill_index: number | null;
	available_policies: PolicyDefinition[];
	constitution: ConstitutionDto;
	races: RaceSummaryDto[];
	interest_groups: InterestGroupSummaryDto[];
	seats: SeatSummaryDto[];
	parliament: ParliamentSummaryDto;
	active_bill: ActiveBillDto | null;
	draft_preview: DraftPreviewDto;
	pending_dialogue: PendingDialogueDto | null;
};

export type DraftSyncDto = {
	state_version: number;
	proposal_hand: Proposal[];
	draft_bill: Bill;
	editing_saved_bill_index: number | null;
	draft_preview: DraftPreviewDto;
	saved_bills?: Bill[];
};

export type ProposalSyncDto = {
	state_version: number;
	proposal_hand: Proposal[];
	result:
		| { kind: 'merge'; proposal: Proposal }
		| { kind: 'bonus_choice'; hand_index: number; accept_trait: boolean; proposal: Proposal };
	political_donation_pool: number;
	pending_dialogue: PendingDialogueDto | null;
	ui_mode: UiMode;
	world_scene: WorldScene;
};

export type BillResultDto = {
	state_version: number;
	submitted: boolean;
	passed: boolean;
	vote: VoteResultDto;
	saved_bills: Bill[];
	proposal_hand: Proposal[];
	draft_bill: Bill;
	editing_saved_bill_index: number | null;
	active_bill: ActiveBillDto | null;
	status: GameStatusDto;
	draft_preview: DraftPreviewDto;
	pending_dialogue: PendingDialogueDto | null;
	ui_mode: UiMode;
	world_scene: WorldScene;
};
