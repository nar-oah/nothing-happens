import {
	Metric,
	MetricConditionOperator,
	PolicyEffectFormula,
	type Bill,
	type InterestGroupDefinition,
	type MetricValues,
	type PolicyDefinition,
	type Proposal
} from '../game/types.ts';
import type {
	ActiveBillDto,
	BillResultDto,
	ConstitutionArticleDto,
	ConstitutionArticleStateDto,
	ConstitutionColumnDto,
	ConstitutionRowDto,
	DraftPreviewDto,
	DraftSyncDto,
	GameStatusDto,
	InterestGroupSummaryDto,
	LiveGameState,
	ParliamentLayoutDto,
	ParliamentSeatAnchorDto,
	ParliamentSummaryDto,
	PendingDialogueDto,
	ProposalSyncDto,
	RaceSummaryDto,
	SeatSummaryDto,
	VoteResultDto
} from '../game/state/types.ts';
import type {
	CommandErrorDto,
	DecodeResult,
	InboundMessage,
	InboundType,
	OutboundMessage,
	OutboundType
} from './protocol.ts';

const inboundTypes = new Set<InboundType>([
	'state.full',
	'draft.sync',
	'parliament.layout',
	'proposal.sync',
	'bill.result',
	'command.error'
]);

const outboundTypes = new Set<OutboundType>([
	'ui.ready',
	'ui.input_regions',
	'ui.mode.set',
	'ui.newspaper.close',
	'draft.proposal.add',
	'draft.proposal.remove',
	'draft.policy.add',
	'draft.policy.remove',
	'draft.title.set',
	'bill.new',
	'bill.edit',
	'bill.submit',
	'vote.donation.add',
	'proposal.merge',
	'office.visit.resolve',
	'constitution.revise',
	'constitution.column.unlock',
	'month.advance',
	'term.next'
]);

export function encodeOutboundMessage(message: OutboundMessage): string {
	return JSON.stringify(message);
}

export function decodeInboundMessage(raw: string): DecodeResult<InboundMessage> {
	let decoded: unknown;
	try {
		decoded = JSON.parse(raw);
	} catch {
		return { ok: false, error: 'Malformed JSON' };
	}
	if (!isRecord(decoded) || !isInboundType(decoded.type)) {
		return { ok: false, error: 'Unknown or missing message type' };
	}
	if (!isOptionalString(decoded.request_id)) {
		return { ok: false, error: 'Invalid request_id' };
	}
	if (!isInboundPayload(decoded.type, decoded.payload)) {
		return { ok: false, error: `Invalid payload for ${decoded.type}` };
	}
	return { ok: true, value: decoded as InboundMessage };
}

export function isOutboundType(value: unknown): value is OutboundType {
	return typeof value === 'string' && outboundTypes.has(value as OutboundType);
}

export function isLiveGameState(value: unknown): value is LiveGameState {
	if (!isRecord(value) || !isGameStatus(value)) return false;
	const state = value as Record<string, unknown>;
	return (
		isVersion(state.state_version) &&
		isUiMode(state.ui_mode) &&
		isWorldScene(state.world_scene) &&
		isArrayOf(state.parliament_seat_anchors, isParliamentSeatAnchor) &&
		isNonnegativeInteger(state.term) &&
		isArrayOf(state.proposal_hand, isProposal) &&
		isArrayOf(state.saved_bills, isBill) &&
		isBill(state.draft_bill) &&
		isNullableIndex(state.editing_saved_bill_index) &&
		isArrayOf(state.available_policies, isPolicy) &&
		isConstitution(state.constitution) &&
		isArrayOf(state.races, isRaceSummary) &&
		isArrayOf(state.interest_groups, isInterestGroupSummary) &&
		isArrayOf(state.seats, isSeatSummary) &&
		isParliamentSummary(state.parliament) &&
		(state.active_bill === null || isActiveBill(state.active_bill)) &&
		isDraftPreview(state.draft_preview) &&
		(state.pending_dialogue === null || isPendingDialogue(state.pending_dialogue)) &&
		(state.term_report === undefined ||
			state.term_report === null ||
			isTermReport(state.term_report))
	);
}

function isTermReport(value: unknown): boolean {
	return (
		isRecord(value) &&
		(value.outcome === 'COLLAPSE' || value.outcome === 'NOTHING_HAPPENS') &&
		isNonnegativeInteger(value.previous_governing_months) &&
		isNonnegativeInteger(value.current_governing_months) &&
		value.current_governing_months >= value.previous_governing_months
	);
}

function isInboundType(value: unknown): value is InboundType {
	return typeof value === 'string' && inboundTypes.has(value as InboundType);
}

function isInboundPayload(type: InboundType, payload: unknown): boolean {
	switch (type) {
		case 'state.full':
			return isLiveGameState(payload);
		case 'draft.sync':
			return isDraftSync(payload);
		case 'parliament.layout':
			return isParliamentLayout(payload);
		case 'proposal.sync':
			return isProposalSync(payload);
		case 'bill.result':
			return isBillResult(payload);
		case 'command.error':
			return isCommandError(payload);
	}
}

function isParliamentLayout(value: unknown): value is ParliamentLayoutDto {
	return isRecord(value) && isArrayOf(value.parliament_seat_anchors, isParliamentSeatAnchor);
}

function isDraftSync(value: unknown): value is DraftSyncDto {
	return (
		isRecord(value) &&
		isVersion(value.state_version) &&
		isArrayOf(value.proposal_hand, isProposal) &&
		isBill(value.draft_bill) &&
		isNullableIndex(value.editing_saved_bill_index) &&
		isDraftPreview(value.draft_preview) &&
		(value.saved_bills === undefined || isArrayOf(value.saved_bills, isBill))
	);
}

function isProposalSync(value: unknown): value is ProposalSyncDto {
	return (
		isRecord(value) &&
		isVersion(value.state_version) &&
		isArrayOf(value.proposal_hand, isProposal) &&
		isProposalResult(value.result) &&
		isNumber(value.political_donation_pool) &&
		(value.pending_dialogue === null || isPendingDialogue(value.pending_dialogue)) &&
		isUiMode(value.ui_mode) &&
		isWorldScene(value.world_scene)
	);
}

function isBillResult(value: unknown): value is BillResultDto {
	return (
		isRecord(value) &&
		isVersion(value.state_version) &&
		typeof value.submitted === 'boolean' &&
		typeof value.passed === 'boolean' &&
		isVoteResult(value.vote) &&
		isArrayOf(value.saved_bills, isBill) &&
		isArrayOf(value.proposal_hand, isProposal) &&
		isBill(value.draft_bill) &&
		isNullableIndex(value.editing_saved_bill_index) &&
		(value.active_bill === null || isActiveBill(value.active_bill)) &&
		isGameStatus(value.status) &&
		isDraftPreview(value.draft_preview) &&
		(value.pending_dialogue === null || isPendingDialogue(value.pending_dialogue)) &&
		isUiMode(value.ui_mode) &&
		isWorldScene(value.world_scene)
	);
}

function isCommandError(value: unknown): value is CommandErrorDto {
	return (
		isRecord(value) &&
		typeof value.code === 'string' &&
		typeof value.message === 'string' &&
		(value.state_version === undefined || isVersion(value.state_version)) &&
		(value.recover_full_state === undefined || typeof value.recover_full_state === 'boolean')
	);
}

function isGameStatus(value: unknown): value is GameStatusDto {
	return (
		isRecord(value) &&
		isNonnegativeInteger(value.term) &&
		isNonnegativeInteger(value.year) &&
		isNonnegativeInteger(value.month) &&
		isNonnegativeInteger(value.governing_months) &&
		(value.run_phase === 'RUNNING' || value.run_phase === 'TERM_ENDED') &&
		(value.term_outcome === 'NONE' ||
			value.term_outcome === 'COLLAPSE' ||
			value.term_outcome === 'NOTHING_HAPPENS') &&
		isMetricValues(value.metrics) &&
		isNumber(value.political_donation_pool) &&
		isNonnegativeInteger(value.collapse_level) &&
		isNonnegativeInteger(value.max_collapse)
	);
}

function isMetricValues(value: unknown): value is MetricValues {
	return (
		isRecord(value) &&
		isNumber(value.tax) &&
		isNumber(value.consumption) &&
		isNumber(value.production) &&
		isNumber(value.employment) &&
		isNumber(value.investment)
	);
}

function isInterestGroup(value: unknown): value is InterestGroupDefinition {
	return (
		isRecord(value) &&
		typeof value.display_name === 'string' &&
		typeof value.description === 'string' &&
		isNumber(value.base_column_weight) &&
		typeof value.decrease_tax === 'boolean' &&
		typeof value.decrease_consumption === 'boolean' &&
		typeof value.decrease_production === 'boolean' &&
		typeof value.decrease_employment === 'boolean' &&
		typeof value.decrease_investment === 'boolean'
	);
}

function isProposal(value: unknown): value is Proposal {
	return (
		isRecord(value) &&
		isInterestGroup(value.source_group) &&
		isMetricValues(value.base_effect) &&
		isMetricValues(value.positive_effect) &&
		isNonnegativeInteger(value.lag_months) &&
		isNumber(value.donation_offer) &&
		typeof value.bonus_choice_resolved === 'boolean' &&
		typeof value.positive_trait_accepted === 'boolean'
	);
}

function isPolicy(value: unknown): value is PolicyDefinition {
	return (
		isRecord(value) &&
		typeof value.display_name === 'string' &&
		isRecord(value.condition) &&
		isMetric(value.condition.left_metric) &&
		isConditionOperator(value.condition.operator) &&
		isMetric(value.condition.right_metric) &&
		isNumber(value.condition.right_multiplier) &&
		isArrayOf(
			value.effects,
			(effect) =>
				isRecord(effect) &&
				isMetric(effect.target_metric) &&
				isEffectFormula(effect.formula) &&
				isMetric(effect.source_a) &&
				isMetric(effect.source_b) &&
				isNumber(effect.multiplier)
		)
	);
}

function isBill(value: unknown): value is Bill {
	return (
		isRecord(value) &&
		typeof value.title === 'string' &&
		isArrayOf(value.proposals, isProposal) &&
		isArrayOf(value.policies, isPolicy)
	);
}

function isConstitutionEffect(value: unknown): boolean {
	return (
		isRecord(value) &&
		typeof value.display_name === 'string' &&
		typeof value.description === 'string' &&
		isNonnegativeInteger(value.timing)
	);
}

function isConstitutionArticle(value: unknown): value is ConstitutionArticleDto {
	return (
		isRecord(value) &&
		isNonnegativeInteger(value.article_index) &&
		typeof value.display_name === 'string' &&
		typeof value.content === 'string' &&
		isArrayOf(value.policies, isPolicy) &&
		isArrayOf(value.effects, isConstitutionEffect)
	);
}

function isConstitutionColumn(value: unknown): value is ConstitutionColumnDto {
	return (
		isRecord(value) &&
		isNonnegativeInteger(value.column_index) &&
		typeof value.display_name === 'string' &&
		isNonnegativeInteger(value.unlock_cost_months) &&
		typeof value.unlocked === 'boolean' &&
		typeof value.can_unlock === 'boolean'
	);
}

function isConstitutionRow(value: unknown): value is ConstitutionRowDto {
	return (
		isRecord(value) &&
		isNonnegativeInteger(value.row_index) &&
		typeof value.display_name === 'string' &&
		typeof value.race_display_name === 'string' &&
		typeof value.free_navigation === 'boolean' &&
		typeof value.ignores_column_unlocks === 'boolean' &&
		isIndexOrMinusOne(value.active_article_index)
	);
}

function isConstitutionArticleState(value: unknown): value is ConstitutionArticleStateDto {
	const state = value as Record<string, unknown>;
	return (
		isConstitutionArticle(value) &&
		isIndexOrMinusOne(state.row_index) &&
		isIndexOrMinusOne(state.column_index) &&
		typeof state.row_display_name === 'string' &&
		typeof state.race_display_name === 'string' &&
		typeof state.active === 'boolean' &&
		typeof state.selected === 'boolean' &&
		typeof state.eligible === 'boolean' &&
		typeof state.is_terminal === 'boolean' &&
		(state.requirement_percent === null || isNumber(state.requirement_percent)) &&
		isArrayOf(state.contents, (content) => isRecord(content) && typeof content.title === 'string' && typeof content.body === 'string')
	);
}

function isConstitution(value: unknown): boolean {
	return (
		isRecord(value) &&
		typeof value.title === 'string' &&
		typeof value.revision_available === 'boolean' &&
		isIndexOrMinusOne(value.center_column_index) &&
		isNonnegativeInteger(value.available_governing_months) &&
		isNonnegativeInteger(value.lifetime_governing_months) &&
		isIndexOrMinusOne(value.terminal_article_index) &&
		isArrayOf(value.columns, isConstitutionColumn) &&
		isArrayOf(value.rows, isConstitutionRow) &&
		isArrayOf(value.active_articles, isConstitutionArticle) &&
		isArrayOf(value.articles, isConstitutionArticleState)
	);
}

function isRaceSummary(value: unknown): value is RaceSummaryDto {
	return (
		isRecord(value) &&
		isNonnegativeInteger(value.race_index) &&
		typeof value.display_name === 'string' &&
		typeof value.description === 'string' &&
		isNonnegativeInteger(value.seat_count) &&
		isArrayOf(
			value.expectations,
			(expectation) =>
				isRecord(expectation) &&
				isMetric(expectation.metric) &&
				isNumber(expectation.target) &&
				(expectation.direction === -1 || expectation.direction === 0 || expectation.direction === 1)
		) &&
		isNonnegativeInteger(value.resolved_events_this_year) &&
		isNonnegativeInteger(value.last_year_resolved_events)
	);
}

function isInterestGroupSummary(value: unknown): value is InterestGroupSummaryDto {
	const summary = value as Record<string, unknown>;
	return (
		isInterestGroup(value) &&
		isNonnegativeInteger(summary.influence_count) &&
		isNumber(summary.influence_rate)
	);
}

function isSeatSummary(value: unknown): value is SeatSummaryDto {
	return (
		isRecord(value) &&
		isNonnegativeInteger(value.seat_index) &&
		typeof value.display_name === 'string' &&
		typeof value.race_display_name === 'string' &&
		typeof value.interest_group_display_name === 'string'
	);
}

function isParliamentSeatAnchor(value: unknown): value is ParliamentSeatAnchorDto {
	return (
		isRecord(value) &&
		isNonnegativeInteger(value.seat_index) &&
		isNormalizedCoordinate(value.x) &&
		isNormalizedCoordinate(value.y)
	);
}

function isParliamentSummary(value: unknown): value is ParliamentSummaryDto {
	return (
		isRecord(value) &&
		typeof value.display_name === 'string' &&
		isNonnegativeInteger(value.total_seats) &&
		isArrayOf(
			value.race_seat_counts,
			(item) =>
				isRecord(item) &&
				typeof item.display_name === 'string' &&
				isNonnegativeInteger(item.seat_count)
		) &&
		isArrayOf(
			value.interest_group_influence,
			(item) =>
				isRecord(item) &&
				typeof item.display_name === 'string' &&
				isNonnegativeInteger(item.influence_count) &&
				isNumber(item.influence_rate)
		)
	);
}

function isVoteResult(value: unknown): value is VoteResultDto {
	return (
		isRecord(value) &&
		typeof value.passed === 'boolean' &&
		typeof value.submitted === 'boolean' &&
		isNonnegativeInteger(value.support_count) &&
		isNonnegativeInteger(value.oppose_count) &&
		isNonnegativeInteger(value.abstain_count) &&
		isNonnegativeInteger(value.absent_count) &&
		isNonnegativeInteger(value.present_count) &&
		isArrayOf(
			value.seat_votes,
			(vote) =>
				isRecord(vote) &&
				isNonnegativeInteger(vote.seat_index) &&
				typeof vote.seat_display_name === 'string' &&
				typeof vote.race_display_name === 'string' &&
				typeof vote.interest_group_display_name === 'string' &&
				(vote.position === 0 ||
					vote.position === 1 ||
					vote.position === 2 ||
					vote.position === 3) &&
				isNumber(vote.score) &&
				typeof vote.can_bribe === 'boolean' &&
				isNumberRecord(vote.breakdown)
		)
	);
}

function isDraftPreview(value: unknown): value is DraftPreviewDto {
	return (
		isRecord(value) &&
		isMetricValues(value.current_metrics) &&
		isMetricValues(value.pure_proposal_target) &&
		isMetricValues(value.immediate_policy_result) &&
		isMetricValues(value.projected_metrics) &&
		isVoteResult(value.vote)
	);
}

function isPendingDialogue(value: unknown): value is PendingDialogueDto {
	if (!isRecord(value)) return false;
	if (value.kind === 'simple') {
		return (
			typeof value.initial_text === 'string' &&
			typeof value.left_option === 'string' &&
			typeof value.right_option === 'string' &&
			typeof value.left_content === 'string' &&
			typeof value.right_content === 'string'
		);
	}
	if (typeof value.race_name !== 'string') return false;
	if (value.kind === 'interest_group') {
		return (
			typeof value.group_name === 'string' &&
			isMetric(value.positive_metric) &&
			isNumber(value.positive_value) &&
			isNumber(value.donation_offer)
		);
	}
	return (
		value.kind === 'event_intel' &&
		isMetric(value.metric) &&
		isNumber(value.requirement) &&
		isNumber(value.strength)
	);
}

function isActiveBill(value: unknown): value is ActiveBillDto {
	return (
		isRecord(value) &&
		typeof value.title === 'string' &&
		isMetricValues(value.start_values) &&
		isMetricValues(value.pure_target) &&
		isArrayOf(
			value.proposals,
			(item) =>
				isRecord(item) &&
				isProposal(item.proposal) &&
				isNonnegativeInteger(item.digested_months) &&
				isNumber(item.digestion_progress) &&
				typeof item.fully_digested === 'boolean'
		) &&
		isArrayOf(
			value.policies,
			(item) => isRecord(item) && isPolicy(item.definition) && typeof item.triggered === 'boolean'
		)
	);
}

function isProposalResult(value: unknown): boolean {
	return isRecord(value) && value.kind === 'merge' && isProposal(value.proposal);
}

function isMetric(value: unknown): boolean {
	return (
		value === Metric.TAX ||
		value === Metric.CONSUMPTION ||
		value === Metric.PRODUCTION ||
		value === Metric.EMPLOYMENT ||
		value === Metric.INVESTMENT
	);
}

function isConditionOperator(value: unknown): boolean {
	return (
		value === MetricConditionOperator.LESS_THAN ||
		value === MetricConditionOperator.LESS_THAN_OR_EQUAL ||
		value === MetricConditionOperator.GREATER_THAN ||
		value === MetricConditionOperator.GREATER_THAN_OR_EQUAL
	);
}

function isEffectFormula(value: unknown): boolean {
	return value === PolicyEffectFormula.METRIC_VALUE || value === PolicyEffectFormula.METRIC_GAP;
}

function isUiMode(value: unknown): boolean {
	return (
		value === 'office' || value === 'dialogue' || value === 'parliament' || value === 'constitution'
	);
}

function isWorldScene(value: unknown): boolean {
	return value === 'office' || value === 'parliament';
}

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function isArrayOf<T>(value: unknown, predicate: (item: unknown) => boolean): value is T[] {
	return Array.isArray(value) && value.every(predicate);
}

function isNumberRecord(value: unknown): value is Record<string, number> {
	return isRecord(value) && Object.values(value).every(isNumber);
}

function isNumber(value: unknown): value is number {
	return typeof value === 'number' && Number.isFinite(value);
}

function isNormalizedCoordinate(value: unknown): value is number {
	return isNumber(value) && value >= 0 && value <= 1;
}

function isNonnegativeInteger(value: unknown): value is number {
	return isNumber(value) && Number.isInteger(value) && value >= 0;
}

function isIndexOrMinusOne(value: unknown): value is number {
	return isNumber(value) && Number.isInteger(value) && value >= -1;
}

function isVersion(value: unknown): value is number {
	return isNonnegativeInteger(value);
}

function isNullableIndex(value: unknown): value is number | null {
	return value === null || isNonnegativeInteger(value);
}

function isOptionalString(value: unknown): value is string | undefined {
	return value === undefined || typeof value === 'string';
}
