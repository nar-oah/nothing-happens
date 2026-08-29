import type { TermReportDto } from '$lib/game/state/types.ts';
import type { NewspaperFrontData, NewspaperMetricData } from './types.ts';

const TERM_REPORT_FRONTS: Record<TermReportDto['outcome'], NewspaperFrontData> = {
	COLLAPSE: {
		title: '风声鹤唳',
		content:
			'关于崩溃的预言已经不再需要证据。\n议会无人愿意承担下一项决定，各族拒绝继续等待，联合政府在相互指责与恐慌中停止运作。\n至于那场被反复预告的灾难是否真的到来——已经没有人留下来确认了。'
	},
	NOTHING_HAPPENS: {
		title: '无事发生',
		content:
			'期限到了。\n没有挤兑，没有断粮，没有停工，也没有那场所有人都确信即将到来的全面崩溃。\n新的一天照常开始。\n除此之外，无事发生。'
	}
};

export function deriveTermReportFront(report: TermReportDto): NewspaperFrontData {
	return TERM_REPORT_FRONTS[report.outcome];
}

export function deriveTermReportMetrics(report: TermReportDto): NewspaperMetricData[] {
	const previousYears = Math.floor(report.previous_governing_months / 12);
	const currentYears = Math.floor(report.current_governing_months / 12);
	const previousMonths = report.previous_governing_months % 12;
	const currentMonths = report.current_governing_months % 12;
	return [
		{ metric: '執政年數', value: previousYears, change: currentYears - previousYears },
		{ metric: '執政月數', value: previousMonths, change: currentMonths - previousMonths }
	];
}
