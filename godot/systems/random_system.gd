extends RefCounted
class_name RandomSystem

var rng: RandomNumberGenerator


func _init() -> void:
	rng = RandomNumberGenerator.new()


func set_seed(seed_value: int) -> void:
	rng.seed = seed_value


func random_float(min_value: float, max_value: float) -> float:
	return rng.randf_range(min_value, max_value)


func random_int(min_value: int, max_value: int) -> int:
	return rng.randi_range(min_value, max_value)
