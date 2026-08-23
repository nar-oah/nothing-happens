export const Metric = {
	TAX: 0,
	PRICE: 1,
	WAGE: 2,
	EMPLOYMENT: 3,
	TRADE: 4
} as const;

export type Metric = (typeof Metric)[keyof typeof Metric];

export const MetricConditionOperator = {
	LESS_THAN: 0,
	LESS_THAN_OR_EQUAL: 1,
	GREATER_THAN: 2,
	GREATER_THAN_OR_EQUAL: 3
} as const;

export type MetricConditionOperator =
	(typeof MetricConditionOperator)[keyof typeof MetricConditionOperator];

export const PolicyEffectFormula = {
	METRIC_VALUE: 0,
	METRIC_GAP: 1
} as const;

export type PolicyEffectFormula = (typeof PolicyEffectFormula)[keyof typeof PolicyEffectFormula];

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
};

export type Policy = PolicyDefinition;

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

// The frontend only needs the enacted policies to derive Left metrics for now.
// Annual resolution and unlock state remain authoritative Godot concerns.
export type ConstitutionArticle = {
	display_name: string;
	content: string;
	policies: PolicyDefinition[];
};

export type Constitution = {
	title: string;
	active_articles: ConstitutionArticle[];
};
