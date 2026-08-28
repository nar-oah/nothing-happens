import {
	Metric,
	MetricConditionOperator,
	PolicyEffectFormula,
	type InterestGroupDefinition,
	type MetricValues,
	type PolicyDefinition,
	type Proposal
} from '../types.ts';
import type { DraftSyncDto, LiveGameState } from './types.ts';

export const zeroMetrics = (): MetricValues => ({
	tax: 0,
	price: 0,
	wage: 0,
	employment: 0,
	trade: 0
});

export const testGroup: InterestGroupDefinition = {
	display_name: '造身公所',
	base_column_weight: 5,
	decrease_tax: false,
	decrease_price: true,
	decrease_wage: false,
	decrease_employment: true,
	decrease_trade: false
};

export const testProposal: Proposal = {
	source_group: testGroup,
	base_effect: { ...zeroMetrics(), price: 8 },
	positive_effect: { ...zeroMetrics(), trade: 8 },
	lag_months: 6,
	donation_offer: 5,
	bonus_choice_resolved: false,
	positive_trait_accepted: false
};

export const testPolicy: PolicyDefinition = {
	display_name: '勘合互市',
	condition: {
		left_metric: Metric.TRADE,
		operator: MetricConditionOperator.GREATER_THAN,
		right_metric: Metric.TAX,
		right_multiplier: 1
	},
	effects: [
		{
			target_metric: Metric.TRADE,
			formula: PolicyEffectFormula.METRIC_GAP,
			source_a: Metric.TRADE,
			source_b: Metric.TAX,
			multiplier: -0.3
		}
	]
};

export function makeLiveState(stateVersion = 1): LiveGameState {
	const current = { tax: 100, price: 100, wage: 100, employment: 100, trade: 100 };
	const vote = {
		passed: true,
		submitted: false,
		support_count: 1,
		oppose_count: 0,
		abstain_count: 0,
		absent_count: 0,
		present_count: 1,
		seat_votes: [
			{
				seat_index: 0,
				seat_display_name: '问津',
				race_display_name: '人类',
				interest_group_display_name: testGroup.display_name,
				position: 3 as const,
				score: 2,
				breakdown: { proposal: 2 }
			}
		]
	};
	return {
		state_version: stateVersion,
		ui_mode: 'office',
		world_scene: 'office',
		term: 1,
		year: 3,
		month: 7,
		governing_months: 30,
		run_phase: 'RUNNING',
		term_outcome: 'NONE',
		metrics: current,
		proposal_hand: [testProposal],
		saved_bills: [{ title: '旧法案', proposals: [testProposal], policies: [testPolicy] }],
		draft_bill: { title: '草案', proposals: [testProposal], policies: [testPolicy] },
		editing_saved_bill_index: null,
		available_policies: [testPolicy],
		constitution: {
			title: '蓬莱约法',
			revision_available: true,
			center_column_index: 0,
			available_governing_months: 24,
			lifetime_governing_months: 48,
			terminal_article_index: -1,
			columns: [
				{
					column_index: 0,
					id: 'normal',
					display_name: '常制',
					unlock_cost_months: 0,
					unlocked: true,
					can_unlock: false
				}
			],
			rows: [
				{
					row_index: 0,
					id: 'diplomacy',
					display_name: '外交',
					race_display_name: '人类',
					free_navigation: false,
					ignores_column_unlocks: false,
					active_article_index: 0
				}
			],
			active_articles: [
				{ article_index: 0, display_name: '外藩', content: '', policies: [testPolicy] }
			],
			articles: [
				{
					article_index: 0,
					row_index: 0,
					column_index: 0,
					row_display_name: '外交',
					race_display_name: '人类',
					display_name: '外藩',
					content: '',
					policies: [testPolicy],
					active: true,
					selected: true,
					eligible: false,
					is_terminal: false
				}
			]
		},
		races: [
			{
				race_index: 0,
				display_name: '人类',
				seat_count: 1,
				expectations: [{ metric: Metric.TRADE, target: 110, direction: 1 }],
				resolved_events_this_year: 2,
				last_year_resolved_events: 1
			}
		],
		interest_groups: [{ ...testGroup, influence_count: 1, influence_rate: 1 }],
		seats: [
			{
				seat_index: 0,
				display_name: '问津',
				race_display_name: '人类',
				interest_group_display_name: testGroup.display_name,
				personal_relation: 2
			}
		],
		parliament: {
			total_seats: 1,
			race_seat_counts: [{ display_name: '人类', seat_count: 1 }],
			interest_group_influence: [
				{ display_name: testGroup.display_name, influence_count: 1, influence_rate: 1 }
			]
		},
		political_donation_pool: 8,
		collapse_level: 4,
		max_collapse: 24,
		active_bill: null,
		draft_preview: {
			current_metrics: current,
			pure_proposal_target: { ...current, price: 108 },
			immediate_policy_result: { ...current, price: 108, trade: 96 },
			projected_metrics: { ...current, price: 116, trade: 96 },
			vote
		},
		pending_dialogue: { hand_index: 0, proposal: testProposal }
	};
}

export function makeDraftSync(stateVersion = 2): DraftSyncDto {
	const state = makeLiveState(stateVersion);
	return {
		state_version: stateVersion,
		proposal_hand: [],
		draft_bill: state.draft_bill,
		editing_saved_bill_index: 0,
		draft_preview: state.draft_preview
	};
}
