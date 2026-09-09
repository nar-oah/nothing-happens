extends Node2D
class_name ParliamentWorld

signal office_requested
signal layout_changed(parliament_seat_anchors: Array[Dictionary])

@export var seat_scene: PackedScene
@export var camera_move_speed: float = 1600.0
@export var camera_left_boundary: float = -2800.0
@export var camera_right_boundary: float = 7600.0
@export_range(15.0, 60.0, 1.0) var layout_update_fps: float = 30.0
@onready var camera: Camera2D = $Camera2D
@onready var seats_root: Node2D = $Seats

var seat_races: Array[RaceDefinition] = []
var seat_positions: Array[int] = []
var seats: Array[ParliamentSeat] = []
var current_month: int = 1
var _layout_emit_accumulator: float = 0.0
var _camera_was_moving: bool = false


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
		_flush_camera_layout()
		return
	var next_x := clampf(
		camera.position.x + direction * camera_move_speed * delta,
		camera_left_boundary,
		camera_right_boundary
	)
	if is_equal_approx(next_x, camera.position.x):
		_flush_camera_layout()
		return
	camera.position.x = next_x
	_camera_was_moving = true
	_layout_emit_accumulator += delta
	var update_interval := 1.0 / maxf(layout_update_fps, 1.0)
	if _layout_emit_accumulator < update_interval:
		return
	_layout_emit_accumulator = fmod(_layout_emit_accumulator, update_interval)
	_emit_layout_changed()


func _on_door_clicked(_dialogue: SimpleDialogueDefinition) -> void:
	_play_audio(&"play_door")
	office_requested.emit()


func set_seat_races(value: Array[RaceDefinition]) -> void:
	seat_races = value
	if is_node_ready():
		_refresh_seats()


func set_month(value: int) -> void:
	current_month = value
	if is_node_ready() and not seat_races.is_empty():
		_refresh_seats()


func set_seat_positions(value: Array[int]) -> void:
	seat_positions = value
	if is_node_ready():
		_refresh_seat_positions()


func get_seat_anchors() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for seat in seats:
		var anchor := seat.get_normalized_ui_anchor()
		if anchor.x < 0.0 or anchor.x > 1.0 or anchor.y < 0.0 or anchor.y > 1.0:
			continue
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
		seats[index].set_race(seat_races[index], current_month)
	_refresh_seat_positions()
	_emit_layout_changed()


func _refresh_seat_positions() -> void:
	for index in range(seats.size()):
		var position := (
			seat_positions[index]
			if index < seat_positions.size()
			else int(SeatVoteState.Position.ABSTAIN)
		)
		seats[index].set_preview_position(position)


func _collect_seats(parent: Node) -> void:
	for child in parent.get_children():
		if child is ParliamentSeat:
			seats.append(child)
		_collect_seats(child)


func _on_viewport_size_changed() -> void:
	_emit_layout_changed()


func _flush_camera_layout() -> void:
	if not _camera_was_moving:
		return
	_camera_was_moving = false
	_layout_emit_accumulator = 0.0
	_emit_layout_changed()


func _emit_layout_changed() -> void:
	camera.force_update_scroll()
	layout_changed.emit(get_seat_anchors())


func _play_audio(method: StringName) -> void:
	var director := get_node_or_null("/root/AudioDirector")
	if director != null and director.has_method(method):
		director.call(method)
