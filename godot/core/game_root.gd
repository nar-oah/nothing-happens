extends Node

const CefTextureInputScript = preload("res://core/ui/cef_texture_input.gd")

@onready var run_session: RunSession = $RunSession
@onready var scene_manager: SceneManager = $SceneManager
@onready var ui_bridge: UiBridge = $UiBridge
@onready var world_input_router: WorldInputRouter = $WorldInputRouter
@onready var ui_layer: CanvasLayer = $UiLayer


func _ready() -> void:
	print("GameRoot started.")
	run_session.start_new_run()
	scene_manager.show_office()
	var cef_texture := _create_cef_texture()
	ui_bridge.setup(run_session, scene_manager, cef_texture)
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
	if has_cef:
		cef_texture.set("url", "res://web/index.html")
		cef_texture.set("enable_accelerated_osr", true)
		cef_texture.set("background_color", Color(0.0, 0.0, 0.0, 0.0))
	return cef_texture
