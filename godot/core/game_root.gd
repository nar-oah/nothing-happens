extends Node

const CefTextureInputScript = preload("res://core/ui/cef_texture_input.gd")

@onready var run_session: RunSession = $RunSession
@onready var settings_manager: SettingsManager = $SettingsManager
@onready var scene_manager: SceneManager = $SceneManager
@onready var ui_bridge: UiBridge = $UiBridge
@onready var world_input_router: WorldInputRouter = $WorldInputRouter
@onready var ui_layer: CanvasLayer = $UiLayer


func _ready() -> void:
	print("GameRoot started.")
	run_session.start_new_run()
	ui_bridge.outgoing_message.connect(_on_ui_message)
	scene_manager.show_office()
	var cef_texture := _create_cef_texture()
	ui_bridge.setup(run_session, scene_manager, cef_texture, settings_manager)
	ui_layer.add_child(cef_texture)
	cef_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_input_router.setup(scene_manager)
	world_input_router.world_interaction.connect(ui_bridge.handle_world_interaction)


func _create_cef_texture() -> Control:
	var cef_texture: Control
	var has_cef: bool = ClassDB.class_exists("CefTexture") and ClassDB.can_instantiate("CefTexture")
	if has_cef:
		var instance: Object = ClassDB.instantiate("CefTexture")
		if instance is Control:
			cef_texture = instance
	has_cef = cef_texture != null
	if cef_texture == null:
		cef_texture = TextureRect.new()
	cef_texture.name = "CefTexture"
	cef_texture.set_script(CefTextureInputScript)
	cef_texture.mouse_filter = Control.MOUSE_FILTER_STOP
	cef_texture.focus_mode = Control.FOCUS_ALL
	if cef_texture is TextureRect:
		cef_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if has_cef:
		cef_texture.set("url", "res://web/index.html")
		cef_texture.set("enable_accelerated_osr", true)
		cef_texture.set("background_color", Color(0.0, 0.0, 0.0, 0.0))
	return cef_texture


func _on_world_changed(scene_name: String, world: Node) -> void:
	if scene_name == "office":
		world.parliament_requested.connect(_on_parliament_requested)
		world.visitor_requested.connect(_on_visitor_requested)
		world.simple_dialogue_requested.connect(_on_simple_dialogue_requested)
		_sync_office_visitors(world)
	elif scene_name == "parliament":
		_sync_parliament_seats(world)


func _on_parliament_requested() -> void:
	ui_bridge.set_ui_mode("parliament")


func _on_visitor_requested() -> void:
	ui_bridge.open_current_office_visit()


func _on_simple_dialogue_requested(
	initial_text: String,
	left_option: String,
	right_option: String,
	left_content: String,
	right_content: String
) -> void:
	ui_bridge.open_simple_dialogue(
		initial_text,
		left_option,
		right_option,
		left_content,
		right_content
	)


func _on_ui_message(message: Dictionary) -> void:
	if message.get("type") != "state.full":
		return
	if scene_manager.current_scene_name == "office":
		_sync_office_visitors(scene_manager.current_world)
	elif scene_manager.current_scene_name == "parliament":
		_sync_parliament_seats(scene_manager.current_world)


func _sync_office_visitors(world: Node) -> void:
	if world == null or not world.has_method("set_visitor_races"):
		return
	if world.has_method("set_month"):
		world.call("set_month", run_session.state.month)
	var visitor_races: Array[RaceDefinition] = []
	for visit in run_session.state.office_visits:
		if visit == null or visit.race == null:
			continue
		var active := run_session.constitution_system.get_active_race_definition(
			run_session.context, visit.race
		)
		if active != null:
			visitor_races.append(active)
	world.call("set_visitor_races", visitor_races)


func _sync_parliament_seats(world: Node) -> void:
	if world == null or not world.has_method("set_seat_races"):
		return
	if world.has_method("set_month"):
		world.call("set_month", run_session.state.month)
	var seat_races: Array[RaceDefinition] = []
	for seat in run_session.state.seats:
		var active: RaceDefinition
		if seat != null and seat.race != null:
			active = run_session.constitution_system.get_active_race_definition(
				run_session.context, seat.race
			)
		seat_races.append(active)
	world.call("set_seat_races", seat_races)
