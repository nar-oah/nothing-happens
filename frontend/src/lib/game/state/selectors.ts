import type { LeftItem } from '../../components/left/types.ts';
import { translate, type Translate } from '../../i18n/index.ts';
import { policyToMemorialContent } from '../../components/memorial/presentation.ts';
import {
	type MemorialConstitutionData,
	type MemorialConstitutionRowContentData,
	type MemorialMetricData
} from '../../components/memorial/types.ts';
import type { TopItemData } from '../../components/top/top.ts';
import {
	METRICS,
	getMetricDisplayName,
	Metric,
	getMetricValue,
	type Constitution,
	type InterestGroupDefinition
} from '../index.ts';
import type {
	ConstitutionArticleStateDto,
	DraftPreviewDto,
	InterestGroupSummaryDto,
	LiveGameState,
	PendingDialogueDto,
	RaceSummaryDto
} from './types.ts';

export type GameStateDisplayProps = {
	primary: { text: string; value: number; isRow: false };
	secondary: { text: string; value: number; limit: number; isRow: false };
};
export type LiveConstitutionMemorialData = MemorialConstitutionData;
export type DialoguePresentation =
	| {
			kind: 'simple';
			initialText: string;
			leftOption?: string;
			rightOption?: string;
			leftContent?: string;
			rightContent?: string;
	  }
	| {
			kind: 'interest_group';
			raceName: string;
			groupName: string;
			positiveEffect: string;
			donationOffer: string;
	  }
	| {
			kind: 'event_intel';
			raceName: string;
			metricName: string;
			requirement: number;
			strength: number;
	  };

export function deriveLeftItems(state: LiveGameState): LeftItem[] {
	const constitution: Constitution = {
		title: state.constitution.title,
		active_articles: state.constitution.active_articles.map((article) => ({
			display_name: article.display_name,
			content: article.content,
			policies: article.policies,
			effects: article.effects
		}))
	};
	return [
		{ kind: 'constitution', ref: { collection: 'constitution', index: 0 }, constitution },
		...state.saved_bills.map((bill, index): LeftItem => ({
			kind: 'bill',
			ref: { collection: 'bills', index },
			bill
		})),
		...state.proposal_hand.flatMap((proposal, index): LeftItem[] =>
			proposal.bonus_choice_resolved && proposal.positive_trait_accepted
				? [{ kind: 'proposal', ref: { collection: 'proposals', index }, proposal }]
				: []
		),
		...state.available_policies.map((policy, index): LeftItem => ({
			kind: 'policy',
			ref: { collection: 'policies', index },
			policy
		}))
	];
}

export function deriveRaceTopItems(
	races: RaceSummaryDto[],
	translator: Translate = translate
): TopItemData[] {
	return races.map((race) => ({
		key: `race-${race.race_index}`,
		item: { text: race.display_name, value: race.seat_count },
		detail: {
			leftLabel: translator('game.annualExpectations'),
			rightLabel: translator('game.raceDescription'),
			leftBody: formatRaceExpectations(race, translator),
			rightBody: race.description
		},
		payload: race
	}));
}

export function deriveInterestGroupTopItems(
	groups: InterestGroupSummaryDto[],
	translator: Translate = translate
): TopItemData[] {
	return groups.map((group) => ({
		key: `group-${group.display_name}`,
		item: { text: group.display_name, value: group.influence_count },
		detail: {
			leftLabel: translator('game.metricStance'),
			rightLabel: translator('game.groupDescription'),
			leftBody: formatInterestGroupStance(group, translator),
			rightBody: group.description
		},
		payload: group
	}));
}

export function deriveTopItems(
	state: LiveGameState,
	translator: Translate = translate
): { raceItems: TopItemData[]; interestGroupItems: TopItemData[] } {
	return {
		raceItems: deriveRaceTopItems(state.races, translator),
		interestGroupItems: deriveInterestGroupTopItems(state.interest_groups, translator)
	};
}

export function deriveGameStateDisplayProps(
	state: LiveGameState,
	translator: Translate = translate
): GameStateDisplayProps {
	return {
		primary: {
			text: translator('game.donations'),
			value: state.political_donation_pool,
			isRow: false
		},
		secondary: {
			text: translator('game.collapse'),
			value: state.collapse_level,
			limit: state.max_collapse,
			isRow: false
		}
	};
}

export function deriveDraftPreviewMetrics(
	preview: DraftPreviewDto,
	translator: Translate = translate
): MemorialMetricData[] {
	return METRICS.map((metric) => ({
		text: getMetricDisplayName(metric, translator),
		value: getMetricValue(preview.projected_metrics, metric)
	}));
}

export function deriveConstitutionMemorial(
	state: LiveGameState,
	translator: Translate = translate
): LiveConstitutionMemorialData {
	const result: LiveConstitutionMemorialData = {};
	result[''] = state.constitution.rows.map((row) => {
		const active = state.constitution.articles.find(
			(candidate) => candidate.article_index === row.active_article_index
		);
		return {
			text: row.display_name,
			number: active?.requirement_percent ?? '',
			selected: false,
			selectable: false,
			contents: [],
			policies: []
		};
	});
	for (const column of state.constitution.columns) {
		if (!column.unlocked) {
			result[column.display_name] = column.unlock_cost_months / 12;
			continue;
		}
		result[column.display_name] = state.constitution.rows.map((row) => {
			const article = state.constitution.articles.find(
				(candidate) =>
					candidate.row_index === row.row_index && candidate.column_index === column.column_index
			);
			return article ? articleToMemorialRow(article, translator) : emptyConstitutionCell();
		});
	}
	return result;
}

export function deriveDialoguePresentation(
	pending: PendingDialogueDto | null,
	translator: Translate = translate
): DialoguePresentation | null {
	if (!pending) return null;
	if (pending.kind === 'simple') {
		return {
			kind: pending.kind,
			initialText: pending.initial_text,
			leftOption: pending.left_option,
			rightOption: pending.right_option,
			leftContent: pending.left_content,
			rightContent: pending.right_content
		};
	}
	if (pending.kind === 'event_intel') {
		const metricName =
			pending.requirement_kind === 1 && pending.interest_group_name
				? translator('game.groupProposalCount', { group: pending.interest_group_name })
				: getMetricDisplayName(pending.metric, translator);
		return {
			kind: pending.kind,
			raceName: pending.race_name,
			metricName,
			requirement: pending.requirement,
			strength: pending.strength
		};
	}
	return {
		kind: pending.kind,
		raceName: pending.race_name,
		groupName: pending.group_name,
		positiveEffect: `${getMetricDisplayName(pending.positive_metric, translator)}${pending.positive_value > 0 ? '+' : ''}${formatNumber(pending.positive_value)}`,
		donationOffer: translator('game.donationOffer', {
			amount: formatNumber(pending.donation_offer)
		})
	};
}

function articleToMemorialRow(
	article: ConstitutionArticleStateDto,
	translator: Translate
): MemorialConstitutionRowContentData {
	return {
		articleRef: article.article_index,
		text: article.display_name,
		number: article.requirement_percent ?? '',
		selected: article.selected,
		selectable: article.eligible,
		contents: article.contents,
		policies: article.policies.map((policy) => policyToMemorialContent(policy, translator))
	};
}

function emptyConstitutionCell(): MemorialConstitutionRowContentData {
	return { text: '', number: '', selected: false, selectable: false, contents: [], policies: [] };
}

function formatRaceExpectations(race: RaceSummaryDto, translator: Translate): string {
	const lines = race.expectations.map((expectation) =>
		formatRaceExpectation(expectation, translator)
	);
	if (race.proposal_expectation) {
		lines.push(
			`${translator('game.groupProposalCount', { group: race.proposal_expectation.interest_group_name })}≥${formatNumber(race.proposal_expectation.target)}`
		);
	}
	return lines.join('\n');
}

function formatRaceExpectation(
	expectation: RaceSummaryDto['expectations'][number],
	translator: Translate
): string {
	const direction = expectation.direction < 0 ? '↓' : expectation.direction > 0 ? '↑' : '';
	return `${getMetricDisplayName(expectation.metric, translator)}${direction}${formatNumber(expectation.target)}`;
}

function formatInterestGroupStance(group: InterestGroupDefinition, translator: Translate): string {
	const decreases: Array<[Metric, boolean]> = [
		[Metric.TAX, group.decrease_tax],
		[Metric.CONSUMPTION, group.decrease_consumption],
		[Metric.PRODUCTION, group.decrease_production],
		[Metric.EMPLOYMENT, group.decrease_employment],
		[Metric.INVESTMENT, group.decrease_investment]
	];
	return decreases
		.filter(([, enabled]) => enabled)
		.map(([metric]) => `${getMetricDisplayName(metric, translator)}↓`)
		.join('\n');
}

function formatNumber(value: number): string {
	return Number.isInteger(value) ? String(value) : String(Math.round(value * 100) / 100);
}
