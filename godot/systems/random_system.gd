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


func weighted_index(weights: Array[float]) -> int:
	if weights.is_empty():
		return -1
	var total_weight := 0.0
	for weight in weights:
		total_weight += maxf(weight, 0.0)
	if total_weight <= 0.0:
		return -1
	var roll := rng.randf() * total_weight
	var accumulated := 0.0
	for i in range(weights.size()):
		accumulated += maxf(weights[i], 0.0)
		if roll < accumulated:
			return i
	return weights.size() - 1
