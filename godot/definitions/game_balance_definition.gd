extends Resource
class_name GameBalanceDefinition

@export_group("时代数值")
@export_range(1, 999999, 1) var initial_metric_value: int = 100
@export_range(0.0, 1.0, 0.01) var era_growth_per_year: float = 0.10

@export_group("议会")
@export_range(5, 999, 1) var variable_seat_count: int = 20
@export_range(0, 999, 1) var default_race_minimum_seats: int = 1
@export_range(0, 999, 1) var zhushui_fixed_seat_count: int = 1

@export_group("政治信任")
@export_range(0.0, 100.0, 0.5) var initial_political_trust: float = 50.0

@export_group("事件")
@export_range(0.0, 1.0, 0.01) var event_monthly_spawn_chance: float = 0.03
@export_range(0.0, 1.0, 0.01) var event_worsening_per_month: float = 0.10
@export_range(0.0, 1.0, 0.01) var event_relief_per_month: float = 0.05
@export_range(0.0, 1.0, 0.01) var event_relief_streak_bonus: float = 0.01
@export_range(0.0, 1.0, 0.01) var event_overfulfillment_bonus: float = 0.03
@export_range(1, 12, 1) var event_crisis_months: int = 3
@export var event_trust_on_resolve: float = 8.0
@export var event_trust_on_erupt: float = -12.0
@export var event_collapse_on_resolve: float = -4.0
@export var event_collapse_on_erupt: float = 12.0

@export_group("南柯")
@export_range(0.0, 1.0, 0.01) var nanke_normal_absence_probability: float = 0.15
@export_range(0.0, 1.0, 0.01) var nanke_protected_absence_probability: float = 0.03

@export_group("阴阳月")
@export_range(0, 999999, 1) var yin_yang_adjustment: int = 10

@export_group("阴项")
@export var yin_tax: bool = true
@export var yin_price: bool = true
@export var yin_wage: bool = false
@export var yin_employment: bool = false
@export var yin_trade: bool = false

@export_group("阳项")
@export var yang_tax: bool = false
@export var yang_price: bool = false
@export var yang_wage: bool = true
@export var yang_employment: bool = false
@export var yang_trade: bool = true


func is_yin_metric(metric: Metric.Id) -> bool:
	match metric:
		Metric.Id.TAX:
			return yin_tax
		Metric.Id.PRICE:
			return yin_price
		Metric.Id.WAGE:
			return yin_wage
		Metric.Id.EMPLOYMENT:
			return yin_employment
		Metric.Id.TRADE:
			return yin_trade
	return false


func is_yang_metric(metric: Metric.Id) -> bool:
	match metric:
		Metric.Id.TAX:
			return yang_tax
		Metric.Id.PRICE:
			return yang_price
		Metric.Id.WAGE:
			return yang_wage
		Metric.Id.EMPLOYMENT:
			return yang_employment
		Metric.Id.TRADE:
			return yang_trade
	return false


func get_yin_yang_month_sign(metric: Metric.Id, month: int) -> int:
	var is_yin := is_yin_metric(metric)
	var is_yang := is_yang_metric(metric)
	if is_yin == is_yang:
		return 0
	var yin_month := month % 2 == 1
	if (yin_month and is_yin) or (not yin_month and is_yang):
		return 1
	return -1


func is_biyi_vote_metric_active(metric: Metric.Id, month: int) -> bool:
	return is_yin_metric(metric) if month % 2 == 1 else is_yang_metric(metric)
