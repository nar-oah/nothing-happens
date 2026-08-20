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
@export_range(0.0, 100.0, 0.05) var proposal_digestion_speed_min: float = 0.8
@export_range(0.0, 100.0, 0.05) var proposal_digestion_speed_max: float = 1.2
@export_range(0.0, 1.0, 0.01) var proposal_magnitude_growth_per_year: float = 0.10
@export_range(0.0, 100.0, 0.5) var proposal_support: float = 1.0
@export var proposal_collapse_impact: float = 0.0
@export_range(0.0, 100.0, 0.05) var proposal_draw_base_weight: float = 1.0
@export_range(0.0, 100.0, 0.05) var proposal_draw_reverse_factor: float = 3.0
@export_range(0.0, 100.0, 0.05) var proposal_draw_min_weight: float = 0.5
@export_range(0.0, 100.0, 0.05) var proposal_draw_max_weight: float = 2.0
@export_range(0.0, 100.0, 0.05) var merge_conversion_ratio: float = 0.5
@export_range(0.0, 100.0, 0.05) var merge_upgrade_exponent: float = 1.0
@export_range(0.0, 100.0, 0.05) var donation_per_positive_point: float = 1.0

@export_group("市场")
@export_range(0.0, 1.0, 0.01) var digestion_progress_min: float = 0.08
@export_range(0.0, 1.0, 0.01) var digestion_progress_max: float = 0.16
@export_range(0.0, 100.0, 0.01) var market_response_ratio: float = 0.35
@export_range(0.0, 100.0, 0.01) var noise_ratio: float = 1.10

@export_group("投票与政治献金")
@export_range(0.0, 100.0, 0.5) var race_expectation_score: float = 6.0
@export_range(0.0, 100.0, 0.5) var group_stance_score: float = 4.0
@export_range(0.0, 100.0, 0.5) var support_threshold: float = 1.0
@export_range(0.0, 1.0, 0.01) var donation_detection_probability: float = 0.25
@export_range(0.0, 100.0, 0.5) var donation_detection_collapse: float = 5.0

@export_group("南柯")
@export_range(0.0, 1.0, 0.01) var normal_absence_probability: float = 0.15

@export_group("事件")
@export_range(0, 999, 1) var event_spawn_count_min: int = 1
@export_range(0, 999, 1) var event_spawn_count_max: int = 3
@export_range(1, 999, 1) var event_lifetime_months: int = 12
@export_range(0, 999, 1) var event_public_remaining_months: int = 3
@export_range(0.0, 1.0, 0.01) var event_early_reveal_probability_per_seat: float = 0.05
@export_range(0.0, 100.0, 0.5) var event_failure_collapse: float = 1.0
@export_range(0.0, 1.0, 0.01) var event_pause_satisfaction_threshold: float = 0.8
@export_range(0.0, 1.0, 0.01) var event_relief_satisfaction_threshold: float = 1.0
@export_range(0.0, 1.0, 0.01) var event_relief_progress_per_month: float = 0.05

@export_group("年度议会")
@export_range(0.0, 100.0, 0.1) var race_seat_base_weight: float = 1.0
@export_range(0.0, 100.0, 0.1) var race_resolved_event_weight: float = 1.0
@export_range(0.0, 1.0, 0.01) var annual_group_coloring_rate: float = 0.65

@export_group("崩溃")
@export_range(1.0, 999999.0, 1.0) var max_collapse: float = 100.0
@export_range(0.0, 1.0, 0.01) var pressure_decay_per_month: float = 0.75
@export_range(0.0, 100.0, 0.01) var pressure_to_collapse: float = 0.12
@export_range(0.0, 100.0, 0.1) var negative_metric_monthly_pressure: float = 1.0
@export_range(0.0, 999999.0, 0.5) var silent_recovery_per_month: float = 8.0

@export_group("干预")
@export_range(0.0, 100.0, 0.5) var constitution_revision_pressure: float = 3.0
@export_range(0.0, 100.0, 0.5) var petition_intervention_pressure: float = 2.0
@export_range(0.0, 100.0, 0.5) var bill_submission_pressure_per_slot: float = 1.0
