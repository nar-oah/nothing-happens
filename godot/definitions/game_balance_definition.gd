extends Resource
class_name GameBalanceDefinition

@export_group("政治信任")
@export_range(0.0, 100.0, 0.5) var initial_political_trust: float = 50.0

@export_group("南柯")
@export_range(0.0, 1.0, 0.01) var nanke_normal_absence_probability: float = 0.15
@export_range(0.0, 1.0, 0.01) var nanke_protected_absence_probability: float = 0.03
