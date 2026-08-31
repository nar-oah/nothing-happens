extends ConstitutionEffect
class_name DraftMetricRequirementEffect

@export var races: Array[RaceDefinition] = []
@export var metrics: Array[Metric.Id] = []


func _init() -> void:
	timing = Timing.BEFORE_DRAFT_SUBMIT


func get_description() -> String:
	return "草案的%s纯提案目标不得低于%s的年度期望" % [_format_metrics(metrics), _format_races(races)]
