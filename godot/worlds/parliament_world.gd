extends Node2D
class_name ParliamentWorld

@export var seat_scene: PackedScene
@onready var seats_root: Node2D = $Seats

var seat_races: Array[RaceDefinition] = []
var seats: Array[ParliamentSeat] = []


func _ready() -> void:
	for child in seats_root.get_children():
		if child is ParliamentSeat:
			seats.append(child)
	_refresh_seats()


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
		var removed := seats.pop_back()
		seats_root.remove_child(removed)
		removed.queue_free()
	while seats.size() < seat_races.size():
		var seat := seat_scene.instantiate() as ParliamentSeat
		seats_root.add_child(seat)
		seats.append(seat)
	for index in range(seat_races.size()):
		seats[index].seat_index = index
		seats[index].set_race(seat_races[index])
