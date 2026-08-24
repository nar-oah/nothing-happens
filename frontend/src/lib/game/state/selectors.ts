import type { LeftItem } from '../../components/left/types.ts';
import { policyToMemorialContent } from '../../components/memorial/presentation.ts';
import {
	MetricSymbol,
	type MemorialConstitutionData,
	type MemorialConstitutionRowContentData,
	type MemorialMetricData
} from '../../components/memorial/types.ts';
import type { TopItemData } from '../../components/top/top.ts';
import {
	METRICS,
	METRIC_DISPLAY_NAMES,
	Metric,
	getBillMetrics,
	getMetricValue,
	type Bill,
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

export type LiveConstitutionRow = MemorialConstitutionRowContentData & {
	articleRef: number;
};

export type LiveConstitutionMemorialData = Record<string, number | LiveConstitutionRow[]>;

export type DialoguePresentation = {
	hand_index: number;
	visitor_text: string;
	body: string;
	trait_label: string;
	donation_label: string;
};

export function deriveLeftItems(state: LiveGameState): LeftItem[] {
	const constitution: Constitution = {
		title: state.constitution.title,
		active_articles: state.constitution.active_articles.map((article) => ({
			display_name: article.display_name,
			content: article.content,
			policies: article.policies
		}))
	};
	return [
		{
			kind: 'constitution',
			ref: { collection: 'constitution', index: 0 },
			constitution
		},
		...state.saved_bills.map((bill, index): LeftItem => ({
			kind: 'bill',
			ref: { collection: 'bills', index },
			bill
		})),
		...state.proposal_hand.map((proposal, index): LeftItem => ({
			kind: 'proposal',
			ref: { collection: 'proposals', index },
			proposal
		})),
		...state.available_policies.map((policy, index): LeftItem => ({
			kind: 'policy',
			ref: { collection: 'policies', index },
			policy
		}))
	];
}

export function deriveRaceTopItems(races: RaceSummaryDto[]): TopItemData[] {
	return races.map((race) => ({
		key: `race-${race.race_index}`,
		item: { text: race.display_name, value: race.seat_count },
		detail: {
			leftLabel: '年度期望',
			rightLabel: '当前席位',
			leftBody: race.expectations.map(formatRaceExpectation).join('\n'),
			rightBody: String(race.seat_count)
		},
		payload: race
	}));
}

export function deriveInterestGroupTopItems(groups: InterestGroupSummaryDto[]): TopItemData[] {
	return groups.map((group) => ({
		key: `group-${group.display_name}`,
		item: { text: group.display_name, value: group.influence_count },
		detail: {
			leftLabel: '固定指标立场',
			rightLabel: '当前影响',
			leftBody: formatInterestGroupStance(group),
			rightBody: `${group.influence_count}\n${formatPercent(group.influence_rate)}`
		},
		payload: group
	}));
}

export function deriveTopItems(state: LiveGameState): {
	raceItems: TopItemData[];
	interestGroupItems: TopItemData[];
} {
	return {
		raceItems: deriveRaceTopItems(state.races),
		interestGroupItems: deriveInterestGroupTopItems(state.interest_groups)
	};
}

export function deriveGameStateDisplayProps(state: LiveGameState): GameStateDisplayProps {
	return {
		primary: { text: '政治献金', value: state.political_donation_pool, isRow: false },
		secondary: {
			text: '崩溃度',
			value: state.collapse_level,
			limit: state.max_collapse,
			isRow: false
		}
	};
}

export function deriveDraftPreviewMetrics(
	preview: DraftPreviewDto,
	draft?: Bill
): MemorialMetricData[] {
	const metrics = draft
		? getBillMetrics(draft.proposals, draft.policies)
		: METRICS.filter(
				(metric) =>
					getMetricValue(preview.current_metrics, metric) !==
					getMetricValue(preview.projected_metrics, metric)
			);
	return metrics.map((metric) => {
		const change =
			getMetricValue(preview.projected_metrics, metric) -
			getMetricValue(preview.current_metrics, metric);
		return {
			text: METRIC_DISPLAY_NAMES[metric],
			symbol: change === 0 ? undefined : change > 0 ? MetricSymbol.Increase : MetricSymbol.Decrease,
			value: Math.abs(change)
		};
	});
}

export function deriveConstitutionMemorial(
	state: LiveGameState
): LiveConstitutionMemorialData & MemorialConstitutionData {
	const sections: LiveConstitutionMemorialData = {};
	for (const article of state.constitution.articles) {
		const rows = sections[article.race_display_name];
		const row = articleToMemorialRow(article);
		sections[article.race_display_name] = Array.isArray(rows) ? [...rows, row] : [row];
	}
	return sections;
}

export function deriveDialoguePresentation(
	pending: PendingDialogueDto | null
): DialoguePresentation | null {
	if (!pending) return null;
	const groupName = pending.proposal.source_group.display_name;
	const traitParts = METRICS.flatMap((metric) => {
		const value = getMetricValue(pending.proposal.positive_effect, metric);
		return value === 0
			? []
			: [`${METRIC_DISPLAY_NAMES[metric]}${value > 0 ? '+' : ''}${formatNumber(value)}`];
	});
	return {
		hand_index: pending.hand_index,
		visitor_text: `${groupName}代表来访。`,
		body: `${groupName}愿意给出一个优惠的提案，\n您可以选择给我手上的这张提案添加一个优惠条款，或收下我们的一点心意`,
		trait_label: traitParts.join('、') || '正面词条',
		donation_label: `政治献金+${formatNumber(pending.proposal.donation_offer)}`
	};
}

function articleToMemorialRow(article: ConstitutionArticleStateDto): LiveConstitutionRow {
	return {
		articleRef: article.article_index,
		text: article.display_name,
		number: '',
		selected: article.selected,
		selectable: article.eligible,
		contents: [{ body: article.content }],
		policies: article.policies.map(policyToMemorialContent)
	};
}

function formatRaceExpectation(expectation: RaceSummaryDto['expectations'][number]): string {
	const direction = expectation.direction < 0 ? '↓' : expectation.direction > 0 ? '↑' : '';
	return `${METRIC_DISPLAY_NAMES[expectation.metric]}${direction}${formatNumber(expectation.target)}`;
}

function formatInterestGroupStance(group: InterestGroupDefinition): string {
	const decreases: Array<[Metric, boolean]> = [
		[Metric.TAX, group.decrease_tax],
		[Metric.PRICE, group.decrease_price],
		[Metric.WAGE, group.decrease_wage],
		[Metric.EMPLOYMENT, group.decrease_employment],
		[Metric.TRADE, group.decrease_trade]
	];
	return decreases
		.filter(([, enabled]) => enabled)
		.map(([metric]) => `${METRIC_DISPLAY_NAMES[metric]}↓`)
		.join('\n');
}

function formatPercent(value: number): string {
	return `${formatNumber(value * 100)}%`;
}

function formatNumber(value: number): string {
	return Number.isInteger(value) ? String(value) : String(Math.round(value * 100) / 100);
}
