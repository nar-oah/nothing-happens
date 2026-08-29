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

export type ConstitutionColumnDto = {
	column_index: number;
	display_name: string;
	unlock_cost_months: number;
	unlocked: boolean;
	can_unlock: boolean;
};

export type ConstitutionRowDto = {
	row_index: number;
	display_name: string;
	race_display_name: string;
	free_navigation: boolean;
	ignores_column_unlocks: boolean;
	active_article_index: number;
};

export type ConstitutionArticleStateDto = ConstitutionArticleDto & {
	row_index: number;
	column_index: number;
	row_display_name: string;
	race_display_name: string;
	active: boolean;
	selected: boolean;
	eligible: boolean;
	is_terminal: boolean;
	requirement_percent: number | null;
};

export type ConstitutionDto = {
	title: string;
	revision_available: boolean;
	center_column_index: number;
	available_governing_months: number;
	lifetime_governing_months: number;
	terminal_article_index: number;
	columns: ConstitutionColumnDto[];
	rows: ConstitutionRowDto[];
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
	description: string;
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
	projected_metrics: MetricValues;
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

export type MonthReportEventPhase = 0 | 1 | 2;

export type MonthReportEventDto = {
	race_display_name: string;
	metric: Metric;
	value: number;
	countdown: number;
	strength: number;
	phase: MonthReportEventPhase;
};

export type MonthReportDto = {
	year: number;
	month: number;
	previous_metrics: MetricValues;
	current_metrics: MetricValues;
	events: MonthReportEventDto[];
};

export type RunPhase = 'RUNNING' | 'TERM_ENDED';
export type TermOutcome = 'NONE' | 'COLLAPSE' | 'NOTHING_HAPPENS';

export type TermReportDto = {
	outcome: Exclude<TermOutcome, 'NONE'>;
	previous_governing_months: number;
	current_governing_months: number;
};

export type GameStatusDto = {
	term: number;
	year: number;
	month: number;
	governing_months: number;
	run_phase: RunPhase;
	term_outcome: TermOutcome;
	metrics: MetricValues;
	political_donation_pool: number;
	collapse_level: number;
	max_collapse: number;
};

export type LiveGameState = GameStatusDto & {
	state_version: number;
	ui_mode: UiMode;
	world_scene: WorldScene;
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
	month_report?: MonthReportDto | null;
	term_report?: TermReportDto | null;
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
