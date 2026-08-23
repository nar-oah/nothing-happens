export enum Metric {
	TAX = 0,
	PRICE = 1,
	WAGE = 2,
	EMPLOYMENT = 3,
	TRADE = 4
}

export enum MetricConditionOperator {
	LESS_THAN = 0,
	LESS_THAN_OR_EQUAL = 1,
	GREATER_THAN = 2,
	GREATER_THAN_OR_EQUAL = 3
}

export enum PolicyEffectFormula {
	METRIC_VALUE = 0,
	METRIC_GAP = 1
}

export type MetricValues = {
	tax: number;
	price: number;
	wage: number;
	employment: number;
	trade: number;
};

export type MetricVector = MetricValues;

export type InterestGroupDefinition = {
	display_name: string;
	base_column_weight: number;
	decrease_tax: boolean;
	decrease_price: boolean;
	decrease_wage: boolean;
	decrease_employment: boolean;
	decrease_trade: boolean;
};

export type MetricCondition = {
	left_metric: Metric;
	operator: MetricConditionOperator;
	right_metric: Metric;
	right_multiplier: number;
};

export type PolicyEffect = {
	target_metric: Metric;
	formula: PolicyEffectFormula;
	source_a: Metric;
	source_b: Metric;
	multiplier: number;
};

export type PolicyDefinition = {
	display_name: string;
	condition: MetricCondition;
	effects: PolicyEffect[];
	collapse_impact: number;
};

export type Proposal = {
	source_group: InterestGroupDefinition;
	base_effect: MetricVector;
	positive_effect: MetricVector;
	lag_months: number;
	collapse_impact: number;
	donation_offer: number;
	bonus_choice_resolved: boolean;
	positive_trait_accepted: boolean;
};

export type Bill = {
	title: string;
	proposals: Proposal[];
	policies: PolicyDefinition[];
};
