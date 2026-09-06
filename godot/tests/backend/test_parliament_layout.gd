extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


class FixedAnchorSeat:
	extends ParliamentSeat
	var fixed_anchor := Vector2.ZERO

	func get_normalized_ui_anchor() -> Vector2:
		return fixed_anchor


func run(t: BackendTestContext) -> void:
	_test_seat_anchor_keeps_offscreen_coordinates(t)
	_test_world_filters_offscreen_anchors(t)


func _test_seat_anchor_keeps_offscreen_coordinates(t: BackendTestContext) -> void:
	var seat_scene: PackedScene = load("res://worlds/parliament_seat.tscn")
	var seat: ParliamentSeat = seat_scene.instantiate()
	Engine.get_main_loop().root.add_child(seat)
	var viewport_size := seat.get_viewport_rect().size
	seat.position = Vector2(-viewport_size.x * 0.25, viewport_size.y * 0.5) - seat.ui_anchor.position
	var anchor := seat.get_normalized_ui_anchor()
	t.check_approx(anchor.x, -0.25, "ParliamentSeat preserves an offscreen normalized x coordinate")
	t.check_approx(anchor.y, 0.5, "ParliamentSeat still normalizes the visible y coordinate")
	seat.free()


func _test_world_filters_offscreen_anchors(t: BackendTestContext) -> void:
	var world := ParliamentWorld.new()
	var left := _make_fixed_seat(0, Vector2(-0.1, 0.5))
	var left_edge := _make_fixed_seat(1, Vector2(0.0, 0.5))
	var center := _make_fixed_seat(2, Vector2(0.5, 0.5))
	var right_edge := _make_fixed_seat(3, Vector2(1.0, 0.5))
	var right := _make_fixed_seat(4, Vector2(1.1, 0.5))
	var above := _make_fixed_seat(5, Vector2(0.5, -0.1))
	var below := _make_fixed_seat(6, Vector2(0.5, 1.1))
	var test_seats: Array[ParliamentSeat] = [
		left,
		left_edge,
		center,
		right_edge,
		right,
		above,
		below,
	]
	world.seats = test_seats
	var anchors := world.get_seat_anchors()
	t.check_equal(anchors.size(), 3, "ParliamentWorld omits anchors outside the viewport")
	t.check_equal(anchors[0]["seat_index"], 1, "left viewport edge remains visible")
	t.check_equal(anchors[1]["seat_index"], 2, "center viewport anchor remains visible")
	t.check_equal(anchors[2]["seat_index"], 3, "right viewport edge remains visible")
	for seat in test_seats:
		seat.free()
	world.free()


func _make_fixed_seat(index: int, anchor: Vector2) -> FixedAnchorSeat:
	var seat := FixedAnchorSeat.new()
	seat.seat_index = index
	seat.fixed_anchor = anchor
	return seat
