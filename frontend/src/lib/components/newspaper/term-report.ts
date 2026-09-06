import type { TermReportDto } from '$lib/game/state/types';
import { translate, type Translate } from '../../i18n/index.ts';
import type { NewspaperFrontData, NewspaperMetricData } from './types.ts';

export function deriveTermReportFront(
	report: TermReportDto,
	translator: Translate = translate
): NewspaperFrontData {
	return {
		title: translator(`report.${report.outcome}.title`),
		content: translator(`report.${report.outcome}.content`)
	};
}

export function deriveTermReportMetrics(
	report: TermReportDto,
	translator: Translate = translate
): NewspaperMetricData[] {
	const previousYears = Math.floor(report.previous_governing_months / 12);
	const currentYears = Math.floor(report.current_governing_months / 12);
	const previousMonths = report.previous_governing_months % 12;
	const currentMonths = report.current_governing_months % 12;
	return [
		{ metric: translator('report.years'), value: previousYears, change: currentYears - previousYears },
		{ metric: translator('report.months'), value: previousMonths, change: currentMonths - previousMonths }
	];
}
