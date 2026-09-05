extends Node2D
class_name ParliamentWorld

signal layout_changed(parliament_seat_anchors: Array[Dictionary])

@export var seat_scene: PackedScene
@export var camera_move_speed: float = 1600.0
@export var camera_left_boundary: float = 2400.0
@export var camera_right_boundary: float = 7600.0
@onready var camera: Camera2D = $Camera2D
@onready var seats_root: Node2D = $Seats

var seat_races: Array[RaceDefinition] = []
var seats: Array[ParliamentSeat] = []


func _ready() -> void:
	_collect_seats(seats_root)
	seats.sort_custom(
		func(first: ParliamentSeat, second: ParliamentSeat) -> bool:
			return first.seat_index < second.seat_index
	)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	if not seat_races.is_empty():
		_refresh_seats()


func _process(delta: float) -> void:
	var direction := Input.get_axis("parliament_left", "parliament_right")
	if is_zero_approx(direction):
		return
	var next_x := clampf(
		camera.position.x + direction * camera_move_speed * delta,
		camera_left_boundary,
		camera_right_boundary
	)
	if is_equal_approx(next_x, camera.position.x):
		return
	camera.position.x = next_x
	_emit_layout_changed()


func set_seat_races(value: Array[RaceDefinition]) -> void:
	seat_races = value
	if is_node_ready():
		_refresh_seats()


func get_seat_anchors() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for seat in seats:
		var anchor := seat.get_normalized_ui_anchor()
		result.append({"seat_index": seat.seat_index, "x": anchor.x, "y": anchor.y})
	return result


func _refresh_seats() -> void:
	while seats.size() > seat_races.size():
		var removed: ParliamentSeat = seats.pop_back()
		removed.get_parent().remove_child(removed)
		removed.queue_free()
	while seats.size() < seat_races.size():
		var seat := seat_scene.instantiate() as ParliamentSeat
		seats_root.add_child(seat)
		seats.append(seat)
	for index in range(seat_races.size()):
		seats[index].seat_index = index
		seats[index].set_race(seat_races[index])
	_emit_layout_changed()


func _collect_seats(parent: Node) -> void:
	for child in parent.get_children():
		if child is ParliamentSeat:
			seats.append(child)
		_collect_seats(child)


func _on_viewport_size_changed() -> void:
	_emit_layout_changed()


func _emit_layout_changed() -> void:
	camera.force_update_scroll()
	layout_changed.emit(get_seat_anchors())
