extends TextureRect
class_name CefTextureInput

var _blocker_regions: Array[Rect2] = []


func set_blocker_regions(regions: Array) -> void:
	_blocker_regions.clear()
	for region in regions:
		_blocker_regions.append(
			Rect2(
				float(region["x"]),
				float(region["y"]),
				float(region["width"]),
				float(region["height"])
			)
		)


func _has_point(point: Vector2) -> bool:
	if size.x <= 0.0 or size.y <= 0.0:
		return false
	var normalized := Vector2(point.x / size.x, point.y / size.y)
	for region in _blocker_regions:
		if region.has_point(normalized):
			return true
	return false
