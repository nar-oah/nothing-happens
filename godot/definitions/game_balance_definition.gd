extends Resource
class_name GameBalanceDefinition

@export_group("基础")
@export_range(1, 999999, 1) var initial_metric_value: int = 100

@export_group("提案")
@export_range(0, 999, 1) var automatic_draw_count: int = 3
@export_range(0, 999999, 1) var proposal_negative_magnitude_min: int = 8
@export_range(0, 999999, 1) var proposal_negative_magnitude_max: int = 12
@export_range(0, 999999, 1) var proposal_positive_magnitude_min: int = 5
@export_range(0, 999999, 1) var proposal_positive_magnitude_max: int = 8
@export_range(1, 999, 1) var proposal_lag_months_min: int = 6
@export_range(1, 999, 1) var proposal_lag_months_max: int = 12
@export_range(0.0, 1.0, 0.01) var proposal_digestion_variance: float = 0.35
@export_range(0.0, 1.0, 0.01) var proposal_magnitude_growth_per_year: float = 0.10
@export_range(0.0, 100.0, 0.5) var proposal_support: float = 1.0
@export_range(0.0, 100.0, 0.05) var proposal_draw_base_weight: float = 1.0
@export_range(0.0, 100.0, 0.05) var proposal_draw_reverse_factor: float = 3.0
@export_range(0.0, 100.0, 0.05) var proposal_draw_min_weight: float = 0.5
@export_range(0.0, 100.0, 0.05) var proposal_draw_max_weight: float = 2.0
@export_range(0.0, 1.0, 0.01) var proposal_visit_probability: float = 0.2
@export_range(0.0, 100.0, 0.05) var merge_conversion_ratio: float = 0.5
@export_range(0.0, 100.0, 0.05) var merge_upgrade_exponent: float = 1.0
@export_range(0.0, 100.0, 0.05) var donation_per_positive_point: float = 1.0

@export_group("投票与政治献金")
@export_range(0.0, 100.0, 0.5) var race_expectation_score: float = 6.0
@export_range(0.0, 100.0, 0.5) var support_threshold: float = 1.0
@export_range(0.0, 1.0, 0.01) var donation_detection_probability: float = 0.25

@export_group("南柯")
@export_range(0.0, 1.0, 0.01) var normal_absence_probability: float = 0.15

@export_group("事件")
@export_range(1, 999, 1) var initial_interest_group_proposal_requirement: int = 5
@export_range(0, 999, 1) var event_spawn_count_min: int = 1
@export_range(0, 999, 1) var event_spawn_count_max: int = 3
@export_range(1, 999, 1) var event_lifetime_months: int = 12
@export_range(0, 999, 1) var event_public_remaining_months: int = 3
@export_range(0.0, 1.0, 0.01) var event_early_reveal_probability_per_seat: float = 0.05
@export_range(0.0, 1.0, 0.01) var event_pause_satisfaction_threshold: float = 0.8
@export_range(0.0, 1.0, 0.01) var event_relief_satisfaction_threshold: float = 1.0
@export_range(0.0, 1.0, 0.01) var event_relief_progress_per_month: float = 0.50

@export_group("年度议会")
@export_range(0.0, 1.0, 0.01) var opening_max_race_seat_rate: float = 0.60
@export_range(0.0, 100.0, 0.1) var race_seat_base_weight: float = 1.0
@export_range(0.0, 100.0, 0.1) var race_resolved_event_weight: float = 1.0
@export_range(0.0, 1.0, 0.01) var annual_group_coloring_rate: float = 0.65

@export_group("崩溃")
@export_range(1, 999999, 1) var max_collapse: int = 100
@export_range(0, 100, 1) var collapse_step: int = 1
@export_range(0, 100, 1) var annual_collapse_recovery: int = 1
