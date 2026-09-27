extends Node3D

const PEARL_COUNT := 1
const MAX_FOAM_COUNT := 100000
const FOAM_RADIUS := 0.042
const FOAM_DIAMETER := FOAM_RADIUS * 2.0
const FOAM_BASE_Y := 0.09
const FOAM_CELL_SIZE := 0.55
const WALK_SPEED := 4.4
const LOOK_SPEED := 0.0025

var player: CharacterBody3D
var view: Camera3D
var player_collider: CollisionShape3D
var player_capsule: CapsuleShape3D
var foam_root: Node3D
var stage_root: Node3D
var pearls: Array[PhysicsBody3D] = []
var foam_materials: Array[StandardMaterial3D] = []
var foam_positions: Array[Vector3] = []
var foam_rest_heights: Array[float] = []
var foam_velocities: Array[Vector3] = []
var foam_alive: Array[bool] = []
var foam_moving: Array[bool] = []
var foam_chain_last_hit: Array[float] = []
var moving_indices: Array[int] = []
var foam_groups: Array[int] = []
var foam_slots: Array[int] = []
var foam_meshes: Array[MultiMesh] = []
var foam_cells: Dictionary = {}
var foam_cell_keys: Array[Vector2i] = []
var foam_stack_columns: Dictionary = {}
var foam_stack_keys: Array[Vector2i] = []
var pearl_material: StandardMaterial3D
var pearl_glow_material: StandardMaterial3D
var uv_flashlight: SpotLight3D
var room_light: OmniLight3D
var light_switch: StaticBody3D
var switch_lever: MeshInstance3D
var hud: Label
var hud_panel: PanelContainer
var hint: Label
var hint_panel: PanelContainer
var result: Label
var result_panel: PanelContainer
var crosshair: Label
var menu: VBoxContainer
var menu_panel: PanelContainer
var shop_panel: PanelContainer
var shop_title: Label
var shop_money: Label
var sell_button: Button
var buy_uv_button: Button
var buy_blower_button: Button
var upgrade_uv_button: Button
var upgrade_blower_button: Button
var next_level_button: Button
var tools_bar: HBoxContainer
var tool_buttons: Array[Button] = []
var skill_panel: PanelContainer
var skill_points_label: Label
var skill_buttons: Array[Button] = []
var skill_from_shop := false
var skill_from_pause := false
var pause_panel: PanelContainer
var level_select_panel: PanelContainer
var cheat_panel: PanelContainer
var cheat_status: Label
var game_paused := false
var selected_tool := 0
var uv_marker: Label
var mode := ""
var playing := false
var found := 0
var removed_foam := 0
var uv_on := false
var uv_found := false
var secret_vision := false
var blower_on := false
var room_light_on := true
var message := ""
var mouse_captured := false
var blow_cooldown := 0.0
var push_cooldown := 0.0
var chain_time := 0.0
var last_foam_assist_timer := 0.0
var coins := 0
var current_level := 1
var pearl_sold := false
var owns_uv := false
var owns_blower := false
var uv_level := 0
var blower_level := 0
var level_foam_counts := [10, 50, 200, 600, 1500, 4000, 10000, 25000, 50000, 100000]
var level_values := [25, 45, 75, 110, 160, 230, 320, 450, 650, 1000]
var level_names := ["TINY BOX", "BIG BOX", "BEDROOM", "PLAYROOM", "SMALL HOUSE", "TWO ROOMS", "FOAM HOUSE", "STORAGE", "FACTORY", "MEGA WAREHOUSE"]
var current_foam_count := 10
var skill_points := 2
var hand_skill := 0
var blower_skill := 0
var mop_skill := 0
var organize_skill := 0
var mobility_skill := 0
var crouching := false
var cleanup_phase := 0
var dirt_spots: Array[StaticBody3D] = []
var misplaced_items: Array[StaticBody3D] = []
var cleaned_surfaces := 0
var organized_items := 0
var room_dirt_counts := [2, 3, 4, 5, 7]
var room_item_counts := [2, 3, 4, 5, 7]
var cleanup_room_names := ["GRAND FOYER", "GUEST ROOM", "DINING HALL", "LIBRARY", "BALLROOM"]
var cleanup_foam_counts := [40, 120, 300, 700, 1500]
var phase_names := ["CLEAR FOAM", "CLEAN SURFACES", "ORGANIZE ROOM"]
var skill_coin_costs := [0, 40, 90]
var room_asset_paths := [
	["res://assets/kenney_building/column-wide.glb", "res://assets/kenney_furniture/pottedPlant.glb", "res://assets/kaykit_furniture/armchair.gltf", "res://assets/kenney_furniture/loungeSofa.glb"],
	["res://assets/kenney_furniture/bedDouble.glb", "res://assets/kenney_furniture/desk.glb", "res://assets/kaykit_furniture/lamp_table.gltf", "res://assets/kenney_furniture/rugRectangle.glb"],
	["res://assets/kenney_furniture/tableCloth.glb", "res://assets/kenney_furniture/chairCushion.glb", "res://assets/kenney_food/cake-birthday.glb", "res://assets/kenney_food/cup-tea.glb"],
	["res://assets/kenney_furniture/bookcaseOpen.glb", "res://assets/kenney_furniture/books.glb", "res://assets/kaykit_furniture/book_set.gltf", "res://assets/kenney_furniture/desk.glb"],
	["res://assets/kenney_building/column.glb", "res://assets/kenney_furniture/tableRound.glb", "res://assets/kenney_furniture/loungeSofa.glb", "res://assets/kenney_food/wine-red.glb"]
]
var fallen_asset_paths := [
	"res://assets/kenney_food/apple.glb", "res://assets/kenney_food/bread.glb",
	"res://assets/kenney_food/plate-dinner.glb", "res://assets/kenney_furniture/books.glb",
	"res://assets/kenney_furniture/cardboardBoxOpen.glb"
]
var current_walkable_rects: Array[Rect2] = []
var blocked_spawn_rects: Array[Rect2] = []
var movement_keys := {KEY_W: false, KEY_A: false, KEY_S: false, KEY_D: false}


func _ready() -> void:
	make_materials()
	make_house()
	make_player()
	make_ui()
	show_modes()


func make_material(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func ui_panel_style(background: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func make_materials() -> void:
	for color in [Color("f8f2dd"), Color("d9edf2"), Color("f4dce5"), Color("e4e2f5"), Color("e2f0d8")]:
		foam_materials.append(make_material(color))
	pearl_material = make_material(Color("fff0c9"), 0.18)
	pearl_material.metallic = 0.35
	pearl_glow_material = make_material(Color("f5caff"), 0.12)
	pearl_glow_material.emission_enabled = true
	pearl_glow_material.emission = Color("d66cff")
	pearl_glow_material.emission_energy_multiplier = 2.5


func box(name: String, position: Vector3, size: Vector3, material: Material, solid: bool = true) -> void:
	var body := StaticBody3D.new()
	body.name = name
	body.position = position
	body.collision_layer = 1
	var mesh := BoxMesh.new()
	mesh.size = size
	var visible_mesh := MeshInstance3D.new()
	visible_mesh.mesh = mesh
	visible_mesh.material_override = material
	body.add_child(visible_mesh)
	if solid:
		var shape := BoxShape3D.new()
		shape.size = size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
	add_child(body)


func make_house() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("8ac6d9")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e6f1f0")
	env.ambient_light_energy = 0.28
	env.glow_enabled = true
	env_node.environment = env
	add_child(env_node)
	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sunlight.light_energy = 1.2
	sunlight.shadow_enabled = true
	add_child(sunlight)
	room_light = OmniLight3D.new()
	room_light.position = Vector3(0.0, 3.3, -1.0)
	room_light.light_energy = 4.0
	room_light.omni_range = 19.0
	add_child(room_light)
	var grass := make_material(Color("6aa987"))
	box("Yard", Vector3(0.0, -0.22, 7.0), Vector3(38.0, 0.4, 32.0), grass)
	box("Welcome path", Vector3(0.0, 0.005, 10.0), Vector3(2.5, 0.03, 6.0), make_material(Color("f1c5a0")), false)
	make_light_switch()
	foam_root = Node3D.new()
	foam_root.name = "FoamAndPearls"
	add_child(foam_root)
	stage_root = Node3D.new()
	stage_root.name = "LevelLayout"
	add_child(stage_root)


func make_light_switch() -> void:
	light_switch = StaticBody3D.new()
	light_switch.name = "RoomLightSwitch"
	light_switch.position = Vector3(1.65, 1.35, 6.76)
	light_switch.collision_layer = 4
	light_switch.collision_mask = 0
	var plate := BoxMesh.new()
	plate.size = Vector3(0.34, 0.48, 0.10)
	var plate_visual := MeshInstance3D.new()
	plate_visual.mesh = plate
	plate_visual.material_override = make_material(Color("304d5c"))
	light_switch.add_child(plate_visual)
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.40, 0.54, 0.18)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	light_switch.add_child(collider)
	var lever_mesh := BoxMesh.new()
	lever_mesh.size = Vector3(0.12, 0.19, 0.09)
	switch_lever = MeshInstance3D.new()
	switch_lever.mesh = lever_mesh
	switch_lever.position.z = -0.10
	light_switch.add_child(switch_lever)
	add_child(light_switch)
	update_light_switch()


func update_light_switch() -> void:
	if switch_lever == null:
		return
	switch_lever.position.y = 0.07 if room_light_on else -0.07
	switch_lever.rotation.x = -0.25 if room_light_on else 0.25
	switch_lever.material_override = make_material(Color("f0d371") if room_light_on else Color("697480"))


func make_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0.0, 0.1, 11.0)
	player.collision_layer = 1
	player.collision_mask = 3
	player_capsule = CapsuleShape3D.new()
	player_capsule.radius = 0.35
	player_capsule.height = 1.7
	player_collider = CollisionShape3D.new()
	player_collider.shape = player_capsule
	player_collider.position.y = 0.85
	player.add_child(player_collider)
	view = Camera3D.new()
	view.position.y = 1.55
	view.current = true
	view.fov = 75.0
	player.add_child(view)
	uv_flashlight = SpotLight3D.new()
	uv_flashlight.light_color = Color("a650ff")
	uv_flashlight.light_energy = 3.0
	uv_flashlight.spot_range = 1.9
	uv_flashlight.spot_angle = 9.0
	uv_flashlight.shadow_enabled = false
	uv_flashlight.visible = false
	view.add_child(uv_flashlight)
	add_child(player)


func make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	hud_panel = PanelContainer.new()
	hud_panel.position = Vector2(16.0, 16.0)
	hud_panel.add_theme_stylebox_override("panel", ui_panel_style(Color(0.06, 0.10, 0.14, 0.82), Color(0.37, 0.52, 0.58, 0.45)))
	hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud_panel)
	hud = Label.new()
	hud.add_theme_font_size_override("font_size", 18)
	hud.add_theme_color_override("font_color", Color("f1f5ec"))
	hud_panel.add_child(hud)
	hint_panel = PanelContainer.new()
	hint_panel.anchor_top = 1.0
	hint_panel.anchor_bottom = 1.0
	hint_panel.offset_left = 16.0
	hint_panel.offset_right = 380.0
	hint_panel.offset_top = -126.0
	hint_panel.offset_bottom = -24.0
	hint_panel.add_theme_stylebox_override("panel", ui_panel_style(Color(0.06, 0.10, 0.14, 0.78)))
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hint_panel)
	hint = Label.new()
	hint.custom_minimum_size = Vector2(330.0, 44.0)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color("e4eee9"))
	hint_panel.add_child(hint)
	result_panel = PanelContainer.new()
	result_panel.anchor_left = 0.5
	result_panel.anchor_right = 0.5
	result_panel.anchor_top = 0.5
	result_panel.anchor_bottom = 0.5
	result_panel.offset_left = -245.0
	result_panel.offset_right = 245.0
	result_panel.offset_top = -95.0
	result_panel.offset_bottom = 95.0
	result_panel.add_theme_stylebox_override("panel", ui_panel_style(Color(0.04, 0.09, 0.13, 0.93), Color("80c4bd")))
	root.add_child(result_panel)
	result = Label.new()
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", 27)
	result.add_theme_color_override("font_color", Color("fff3cc"))
	result_panel.add_child(result)
	crosshair = Label.new()
	crosshair.text = "·"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position -= Vector2(4.0, 15.0)
	crosshair.add_theme_font_size_override("font_size", 32)
	crosshair.add_theme_color_override("font_color", Color("fff1c9"))
	root.add_child(crosshair)
	uv_marker = Label.new()
	uv_marker.text = "◉"
	uv_marker.add_theme_font_size_override("font_size", 38)
	uv_marker.add_theme_color_override("font_color", Color("d874ff"))
	root.add_child(uv_marker)
	menu_panel = PanelContainer.new()
	menu_panel.anchor_left = 0.5
	menu_panel.anchor_right = 0.5
	menu_panel.anchor_top = 0.5
	menu_panel.anchor_bottom = 0.5
	menu_panel.offset_left = -275.0
	menu_panel.offset_right = 275.0
	menu_panel.offset_top = -175.0
	menu_panel.offset_bottom = 175.0
	menu_panel.add_theme_stylebox_override("panel", ui_panel_style(Color(0.04, 0.09, 0.13, 0.94), Color("71acae")))
	root.add_child(menu_panel)
	menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation", 12)
	menu.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_panel.add_child(menu)
	var title := Label.new()
	title.text = "MANSION CLEANUP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("fff3cc"))
	menu.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Restore five rooms in a huge low-poly mansion."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color("a8c9c7"))
	menu.add_child(subtitle)
	var controls := Label.new()
	controls.text = "1. Clear every foam bead   2. Mop floors and wipe walls\n3. Put fallen objects back in place\nWASD move · Click/E interact · K skill tree · F10 cheats"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 16)
	controls.add_theme_color_override("font_color", Color("c7d8d7"))
	menu.add_child(controls)
	var normal_button := Button.new()
	normal_button.text = "NORMAL     UV light + blower"
	normal_button.custom_minimum_size.y = 50.0
	normal_button.add_theme_stylebox_override("normal", ui_panel_style(Color("24636b")))
	normal_button.add_theme_stylebox_override("hover", ui_panel_style(Color("347c84")))
	normal_button.pressed.connect(func(): start_round("normal"))
	menu.add_child(normal_button)
	normal_button.visible = false
	var hard_button := Button.new()
	hard_button.text = "START CLEANING     Enter the mansion"
	hard_button.custom_minimum_size.y = 50.0
	hard_button.add_theme_stylebox_override("normal", ui_panel_style(Color("253d4b")))
	hard_button.add_theme_stylebox_override("hover", ui_panel_style(Color("365465")))
	hard_button.pressed.connect(start_new_career)
	menu.add_child(hard_button)
	var level_button := Button.new()
	level_button.text = "SELECT ROOM     Choose any map"
	level_button.custom_minimum_size.y = 46.0
	level_button.pressed.connect(open_level_select)
	menu.add_child(level_button)
	make_shop_ui(root)
	make_skill_tree_ui(root)
	make_pause_ui(root)
	make_level_select_ui(root)
	make_cheat_ui(root)
	tools_bar = HBoxContainer.new()
	tools_bar.anchor_left = 0.5
	tools_bar.anchor_right = 0.5
	tools_bar.anchor_top = 1.0
	tools_bar.anchor_bottom = 1.0
	tools_bar.offset_left = -116.0
	tools_bar.offset_right = 116.0
	tools_bar.offset_top = -94.0
	tools_bar.offset_bottom = -16.0
	tools_bar.add_theme_constant_override("separation", 8)
	tools_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(tools_bar)
	var icons := ["res://icon_hand.svg", "res://icon_uv.svg", "res://icon_blower.svg"]
	var descriptions := ["1  Hand: remove one foam bead", "2  UV flashlight: reveal pearl when aimed", "3  Blower: push foam aside"]
	for i in 3:
		var button := Button.new()
		button.custom_minimum_size = Vector2(72.0, 72.0)
		button.icon = load(icons[i])
		button.expand_icon = true
		button.tooltip_text = descriptions[i]
		button.pressed.connect(select_tool.bind(i))
		tools_bar.add_child(button)
		tool_buttons.append(button)
	update_ui()


func make_shop_ui(root: Control) -> void:
	shop_panel = PanelContainer.new()
	shop_panel.anchor_left = 0.5
	shop_panel.anchor_right = 0.5
	shop_panel.anchor_top = 0.5
	shop_panel.anchor_bottom = 0.5
	shop_panel.offset_left = -270.0
	shop_panel.offset_right = 270.0
	shop_panel.offset_top = -230.0
	shop_panel.offset_bottom = 230.0
	shop_panel.add_theme_stylebox_override("panel", ui_panel_style(Color(0.04, 0.09, 0.13, 0.96), Color("d6b86c")))
	shop_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(shop_panel)
	var shop := VBoxContainer.new()
	shop.add_theme_constant_override("separation", 9)
	shop_panel.add_child(shop)
	shop_title = Label.new()
	shop_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_title.add_theme_font_size_override("font_size", 29)
	shop_title.add_theme_color_override("font_color", Color("fff1bf"))
	shop.add_child(shop_title)
	shop_money = Label.new()
	shop_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_money.add_theme_font_size_override("font_size", 20)
	shop.add_child(shop_money)
	sell_button = shop_button(shop, "SELL PEARL", sell_pearl)
	buy_uv_button = shop_button(shop, "BUY UV FLASHLIGHT — 50", buy_uv)
	buy_blower_button = shop_button(shop, "BUY FOAM BLOWER — 120", buy_blower)
	upgrade_uv_button = shop_button(shop, "UPGRADE UV RANGE — 100", upgrade_uv)
	upgrade_blower_button = shop_button(shop, "UPGRADE BLOWER — 150", upgrade_blower)
	shop_button(shop, "OPEN SKILL TREE", func(): open_skill_tree(true))
	next_level_button = shop_button(shop, "NEXT LEVEL", next_level)
	shop_panel.visible = false


func make_skill_tree_ui(root: Control) -> void:
	skill_panel = PanelContainer.new()
	skill_panel.anchor_left = 0.5
	skill_panel.anchor_right = 0.5
	skill_panel.anchor_top = 0.5
	skill_panel.anchor_bottom = 0.5
	skill_panel.offset_left = -360.0
	skill_panel.offset_right = 360.0
	skill_panel.offset_top = -280.0
	skill_panel.offset_bottom = 280.0
	skill_panel.add_theme_stylebox_override("panel", ui_panel_style(Color(0.035, 0.075, 0.11, 0.98), Color("8a6fd1")))
	skill_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(skill_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	skill_panel.add_child(column)
	var title := Label.new()
	title.text = "CLEANER SKILL TREE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("eadcff"))
	column.add_child(title)
	skill_points_label = Label.new()
	skill_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_points_label.add_theme_font_size_override("font_size", 20)
	column.add_child(skill_points_label)
	var intro := Label.new()
	intro.text = "Spend points earned from restored rooms. Each branch has 3 levels."
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_color_override("font_color", Color("b9cbd2"))
	column.add_child(intro)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)
	var labels := ["QUICK HANDS", "FOAM BLOWER", "DEEP CLEAN", "ORGANIZER MAGNET", "LIGHT FEET"]
	for i in labels.size():
		var button := Button.new()
		button.custom_minimum_size = Vector2(325.0, 68.0)
		button.pressed.connect(upgrade_skill.bind(i))
		grid.add_child(button)
		skill_buttons.append(button)
	var close := Button.new()
	close.text = "CLOSE SKILL TREE    [K]"
	close.custom_minimum_size.y = 44.0
	close.pressed.connect(close_skill_tree)
	column.add_child(close)
	skill_panel.visible = false
	update_skill_tree()


func make_pause_ui(root: Control) -> void:
	pause_panel = PanelContainer.new()
	pause_panel.anchor_left = 0.5
	pause_panel.anchor_right = 0.5
	pause_panel.anchor_top = 0.5
	pause_panel.anchor_bottom = 0.5
	pause_panel.offset_left = -245.0
	pause_panel.offset_right = 245.0
	pause_panel.offset_top = -230.0
	pause_panel.offset_bottom = 230.0
	pause_panel.add_theme_stylebox_override("panel", ui_panel_style(Color(0.035, 0.07, 0.10, 0.97), Color("7bb8c2")))
	pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(pause_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	pause_panel.add_child(column)
	var title := Label.new()
	title.text = "GAME PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("fff0c7"))
	column.add_child(title)
	var room_label := Label.new()
	room_label.text = "Take a break. Your room progress is safe."
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_label.add_theme_color_override("font_color", Color("b8cbd0"))
	column.add_child(room_label)
	shop_button(column, "RESUME GAME     [ESC]", resume_game)
	shop_button(column, "OPEN SKILL TREE     [K]", func(): open_skill_tree(false, true))
	shop_button(column, "RESTART CURRENT ROOM", restart_from_pause)
	shop_button(column, "CONTROLS", show_pause_controls)
	shop_button(column, "RETURN TO MAIN MENU", return_to_menu_from_pause)
	var controls := Label.new()
	controls.name = "PauseControls"
	controls.text = "WASD Move  ·  Mouse Look  ·  Click/E Interact\nCtrl/C Crouch  ·  K Skill Tree  ·  F10 Cheats  ·  1–3 Tools"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_color_override("font_color", Color("9fc1c5"))
	controls.visible = false
	column.add_child(controls)
	pause_panel.visible = false


func make_level_select_ui(root: Control) -> void:
	level_select_panel = PanelContainer.new()
	level_select_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	level_select_panel.offset_left = -300.0
	level_select_panel.offset_right = 300.0
	level_select_panel.offset_top = -255.0
	level_select_panel.offset_bottom = 255.0
	level_select_panel.add_theme_stylebox_override("panel", ui_panel_style(Color(0.04, 0.08, 0.12, 0.98), Color("d6b86c")))
	level_select_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(level_select_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	level_select_panel.add_child(column)
	var title := Label.new()
	title.text = "SELECT A MANSION ROOM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color("fff0bd"))
	column.add_child(title)
	for i in cleanup_room_names.size():
		var description: String = ["Compact entrance hall", "L-shaped bedroom suite", "Long banquet room", "Split-level reading hall", "Huge ballroom with stage"][i]
		shop_button(column, "%d  %s\n%s" % [i + 1, cleanup_room_names[i], description], start_selected_level.bind(i + 1))
	shop_button(column, "BACK", close_level_select)
	level_select_panel.visible = false


func make_cheat_ui(root: Control) -> void:
	cheat_panel = PanelContainer.new()
	cheat_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cheat_panel.offset_left = -330.0
	cheat_panel.offset_right = 330.0
	cheat_panel.offset_top = -275.0
	cheat_panel.offset_bottom = 275.0
	cheat_panel.add_theme_stylebox_override("panel", ui_panel_style(Color(0.06, 0.035, 0.09, 0.98), Color("d36cff")))
	cheat_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(cheat_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	cheat_panel.add_child(column)
	var title := Label.new()
	title.text = "F10  DEVELOPER CHEATS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color("f2d5ff"))
	column.add_child(title)
	cheat_status = Label.new()
	cheat_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(cheat_status)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	column.add_child(grid)
	shop_button(grid, "+1,000 COINS", cheat_add_money)
	shop_button(grid, "+10 SKILL POINTS", cheat_add_skill_points)
	shop_button(grid, "UNLOCK TOOLS", cheat_unlock_tools)
	shop_button(grid, "MAX ALL SKILLS", cheat_max_skills)
	shop_button(grid, "CLEAR FOAM PHASE", cheat_clear_foam)
	shop_button(grid, "TOGGLE PEARL XRAY", cheat_toggle_vision)
	var rooms := HBoxContainer.new()
	rooms.add_theme_constant_override("separation", 5)
	column.add_child(rooms)
	for i in 5:
		var room_button := shop_button(rooms, "ROOM %d" % (i + 1), cheat_go_to_level.bind(i + 1))
		room_button.custom_minimum_size = Vector2(116.0, 42.0)
	shop_button(column, "CLOSE CHEATS     [F10]", close_cheat_menu)
	cheat_panel.visible = false


func shop_button(parent: Control, text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 44.0
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func open_skill_tree(from_shop: bool = false, from_pause: bool = false) -> void:
	skill_from_shop = from_shop
	skill_from_pause = from_pause
	skill_panel.visible = true
	if shop_panel != null:
		shop_panel.visible = false
	if pause_panel != null:
		pause_panel.visible = false
	mouse_captured = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	update_skill_tree()


func close_skill_tree() -> void:
	skill_panel.visible = false
	if skill_from_shop:
		shop_panel.visible = true
	elif skill_from_pause:
		pause_panel.visible = true
	elif playing:
		capture_mouse()
	skill_from_shop = false
	skill_from_pause = false


func pause_game() -> void:
	if not playing:
		return
	game_paused = true
	mouse_captured = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	pause_panel.visible = true
	tools_bar.visible = false
	crosshair.visible = false
	hint_panel.visible = false


func resume_game() -> void:
	game_paused = false
	pause_panel.visible = false
	tools_bar.visible = true
	crosshair.visible = true
	capture_mouse()
	update_ui()


func restart_from_pause() -> void:
	game_paused = false
	pause_panel.visible = false
	start_round(mode)


func return_to_menu_from_pause() -> void:
	game_paused = false
	pause_panel.visible = false
	show_modes()


func show_pause_controls() -> void:
	var controls := pause_panel.find_child("PauseControls", true, false) as Label
	if controls != null:
		controls.visible = not controls.visible


func open_level_select() -> void:
	menu_panel.visible = false
	level_select_panel.visible = true


func close_level_select() -> void:
	level_select_panel.visible = false
	menu_panel.visible = true


func start_selected_level(level: int) -> void:
	reset_career_progress(level)
	start_round("career")


func open_cheat_menu() -> void:
	if not playing:
		return
	game_paused = true
	mouse_captured = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	cheat_panel.visible = true
	tools_bar.visible = false
	crosshair.visible = false
	update_cheat_status()


func close_cheat_menu() -> void:
	cheat_panel.visible = false
	game_paused = false
	tools_bar.visible = true
	crosshair.visible = true
	capture_mouse()
	update_ui()


func update_cheat_status() -> void:
	if cheat_status != null:
		cheat_status.text = "ROOM %d/5     COINS %d     SP %d     XRAY %s" % [current_level, coins, skill_points, "ON" if secret_vision else "OFF"]


func cheat_add_money() -> void:
	coins += 1000
	update_cheat_status()
	update_ui()


func cheat_add_skill_points() -> void:
	skill_points += 10
	update_cheat_status()
	update_skill_tree()


func cheat_unlock_tools() -> void:
	owns_uv = true
	owns_blower = true
	uv_level = 2
	blower_level = 2
	tool_buttons[1].visible = true
	tool_buttons[2].visible = true
	update_cheat_status()


func cheat_max_skills() -> void:
	hand_skill = 3
	blower_skill = 3
	mop_skill = 3
	organize_skill = 3
	mobility_skill = 3
	cheat_unlock_tools()
	update_skill_tree()


func cheat_clear_foam() -> void:
	if cleanup_phase != 0:
		message = "Foam phase is already complete."
		return
	for i in foam_alive.size():
		if foam_alive[i]:
			foam_alive[i] = false
			update_foam_transform(i)
	removed_foam = current_foam_count
	foam_stack_columns.clear()
	advance_cleanup_phase()
	update_cheat_status()


func cheat_toggle_vision() -> void:
	secret_vision = not secret_vision
	update_uv_hint()
	update_cheat_status()


func cheat_go_to_level(level: int) -> void:
	current_level = clampi(level, 1, 5)
	cheat_panel.visible = false
	game_paused = false
	start_round("career")


func upgrade_skill(branch: int) -> void:
	if skill_points <= 0:
		message = "No skill points. Restore another room to earn more."
		update_skill_tree()
		return
	var level := get_skill_level(branch)
	if level >= 3:
		return
	var coin_cost: int = skill_coin_costs[level]
	if coins < coin_cost:
		message = "Need %d coins for this upgrade." % coin_cost
		update_skill_tree()
		return
	skill_points -= 1
	coins -= coin_cost
	set_skill_level(branch, level + 1)
	if branch == 1:
		owns_blower = true
		blower_level = blower_skill
		if tool_buttons.size() >= 3:
			tool_buttons[2].visible = true
	update_skill_tree()
	update_ui()


func get_skill_level(branch: int) -> int:
	return [hand_skill, blower_skill, mop_skill, organize_skill, mobility_skill][branch]


func set_skill_level(branch: int, value: int) -> void:
	match branch:
		0: hand_skill = value
		1: blower_skill = value
		2: mop_skill = value
		3: organize_skill = value
		4: mobility_skill = value


func update_skill_tree() -> void:
	if skill_points_label == null:
		return
	skill_points_label.text = "SKILL POINTS   %d     COINS   %d" % [skill_points, coins]
	var names := ["QUICK HANDS", "FOAM BLOWER", "DEEP CLEAN", "ORGANIZER MAGNET", "LIGHT FEET"]
	var details := [
		"Pick up more nearby foam per click",
		"Unlock blower, then improve power and radius",
		"Remove several nearby floor or wall stains",
		"Longer reach and faster object placement",
		"Move faster and crouch without slowing as much"
	]
	for i in skill_buttons.size():
		var level := get_skill_level(i)
		var cost_text := "MAX" if level >= 3 else ("FREE" if skill_coin_costs[level] == 0 else "%d COINS" % skill_coin_costs[level])
		skill_buttons[i].text = "%s   %d/3   •   %s\n%s" % [names[i], level, cost_text, details[i]]
		skill_buttons[i].disabled = level >= 3 or skill_points <= 0 or (level < 3 and coins < skill_coin_costs[level])


func show_modes() -> void:
	playing = false
	game_paused = false
	mode = ""
	menu_panel.visible = true
	hud_panel.visible = false
	tools_bar.visible = false
	hint_panel.visible = false
	crosshair.visible = false
	uv_marker.visible = false
	uv_flashlight.visible = false
	result.text = ""
	result_panel.visible = false
	shop_panel.visible = false
	skill_panel.visible = false
	pause_panel.visible = false
	level_select_panel.visible = false
	cheat_panel.visible = false
	message = ""
	mouse_captured = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	update_ui()


func start_new_career() -> void:
	reset_career_progress(1)
	start_round("career")


func reset_career_progress(start_level: int) -> void:
	coins = 0
	for i in range(start_level - 1):
		coins += level_values[i]
	current_level = clampi(start_level, 1, 5)
	skill_points = 2
	skill_points += (current_level - 1) * 2
	hand_skill = 0
	blower_skill = 0
	mop_skill = 0
	organize_skill = 0
	mobility_skill = 0
	crouching = false
	pearl_sold = false
	owns_uv = false
	owns_blower = false
	uv_level = 0
	blower_level = 0


func start_round(chosen_mode: String) -> void:
	for child in foam_root.get_children():
		foam_root.remove_child(child)
		child.free()
	pearls.clear()
	for dirt in dirt_spots:
		if is_instance_valid(dirt): dirt.queue_free()
	for item in misplaced_items:
		if is_instance_valid(item): item.queue_free()
	dirt_spots.clear()
	misplaced_items.clear()
	foam_positions.clear()
	foam_rest_heights.clear()
	foam_velocities.clear()
	foam_alive.clear()
	foam_moving.clear()
	foam_chain_last_hit.clear()
	moving_indices.clear()
	foam_groups.clear()
	foam_slots.clear()
	foam_meshes.clear()
	foam_cells.clear()
	foam_cell_keys.clear()
	foam_stack_columns.clear()
	foam_stack_keys.clear()
	mode = chosen_mode
	game_paused = false
	pause_panel.visible = false
	cheat_panel.visible = false
	pearl_sold = false
	current_foam_count = cleanup_foam_counts[current_level - 1]
	found = 0
	removed_foam = 0
	cleanup_phase = 0
	cleaned_surfaces = 0
	organized_items = 0
	selected_tool = 0
	uv_on = false
	uv_found = false
	blower_on = false
	uv_flashlight.visible = false
	blow_cooldown = 0.0
	push_cooldown = 0.0
	chain_time = 0.0
	last_foam_assist_timer = 0.0
	message = ""
	room_light_on = true
	room_light.visible = true
	update_light_switch()
	build_level_layout()
	var bounds := level_bounds()
	player.position = Vector3(0.0, 0.1, minf(6.0, bounds.w + 1.2))
	player.rotation = Vector3.ZERO
	view.rotation = Vector3.ZERO
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var group_counts := [0, 0, 0, 0, 0]
	for i in current_foam_count:
		var spot := random_room_spot(rng)
		var x := spot.x
		var z := spot.y
		var stack_key := Vector2i(floori(x / FOAM_DIAMETER), floori(z / FOAM_DIAMETER))
		if not foam_stack_columns.has(stack_key):
			foam_stack_columns[stack_key] = []
		var height := FOAM_BASE_Y + float(foam_stack_columns[stack_key].size()) * FOAM_DIAMETER
		x = (float(stack_key.x) + 0.5) * FOAM_DIAMETER
		z = (float(stack_key.y) + 0.5) * FOAM_DIAMETER
		foam_positions.append(Vector3(x, height, z))
		foam_rest_heights.append(height)
		foam_stack_keys.append(stack_key)
		foam_stack_columns[stack_key].append(i)
		foam_velocities.append(Vector3.ZERO)
		foam_alive.append(true)
		foam_moving.append(false)
		foam_chain_last_hit.append(-10.0)
		var color_index := rng.randi_range(0, foam_materials.size() - 1)
		foam_groups.append(color_index)
		foam_slots.append(group_counts[color_index])
		group_counts[color_index] += 1
		var cell := foam_cell_for(foam_positions[i])
		foam_cell_keys.append(cell)
		if not foam_cells.has(cell):
			foam_cells[cell] = []
		foam_cells[cell].append(i)
	build_foam_meshes(group_counts)
	build_cleanup_tasks(rng)
	playing = true
	menu_panel.visible = false
	hud_panel.visible = true
	tools_bar.visible = true
	hint_panel.visible = false
	tool_buttons[1].visible = owns_uv
	tool_buttons[2].visible = owns_blower
	var visible_tools := 1 + int(owns_uv) + int(owns_blower)
	tools_bar.offset_left = -40.0 * visible_tools
	tools_bar.offset_right = 40.0 * visible_tools
	crosshair.visible = true
	result.text = ""
	result_panel.visible = false
	shop_panel.visible = false
	apply_level_theme()
	message = "PHASE 1: Remove every foam bead to reveal the room."
	capture_mouse()
	update_ui()


func apply_level_theme() -> void:
	var palettes := [
		[Color("f8f2dd"), Color("d9edf2"), Color("f4dce5"), Color("e4e2f5"), Color("e2f0d8")],
		[Color("cfe8e8"), Color("a9d6d2"), Color("f0d0a8"), Color("d8c7ef"), Color("bdd7c1")],
		[Color("8b91a7"), Color("69788f"), Color("98768b"), Color("667a78"), Color("b08b68")]
	]
	var theme_index := (current_level - 1) % palettes.size()
	for i in foam_materials.size():
		foam_materials[i].albedo_color = palettes[theme_index][i]
	room_light.light_color = [Color("fff1cf"), Color("c9f4ef"), Color("d6c4ff")][theme_index]
	room_light.light_energy = maxf(1.8, 4.2 - float(current_level - 1) * 0.25)


func random_room_spot(rng: RandomNumberGenerator) -> Vector2:
	var bounds := level_bounds()
	for attempt in 80:
		var x := rng.randf_range(bounds.x, bounds.y)
		var z := rng.randf_range(bounds.z, bounds.w)
		for rect in current_walkable_rects:
			if rect.has_point(Vector2(x, z)) and not point_is_spawn_blocked(Vector2(x, z)):
				return Vector2(x, z)
		if current_walkable_rects.is_empty():
			return Vector2(x, z)
	return Vector2.ZERO


func point_is_spawn_blocked(point: Vector2) -> bool:
	for rect in blocked_spawn_rects:
		if rect.has_point(point):
			return true
	return false


func reserve_spawn_area(center: Vector2, size: Vector2) -> void:
	blocked_spawn_rects.append(Rect2(center - size * 0.5, size))


func level_bounds() -> Vector4:
	var bounds := [
		Vector4(-2.8, 2.8, -3.0, 2.5), Vector4(-4.3, 4.3, -4.0, 3.5),
		Vector4(-5.8, 5.8, -5.0, 4.8), Vector4(-7.0, 7.0, -6.0, 5.8),
		Vector4(-8.5, 8.5, -7.0, 6.4)
	]
	return bounds[current_level - 1]


func build_level_layout() -> void:
	for child in stage_root.get_children():
		child.queue_free()
	current_walkable_rects.clear()
	blocked_spawn_rects.clear()
	match current_level:
		1: build_foyer_map()
		2: build_guest_suite_map()
		3: build_dining_map()
		4: build_library_map()
		_: build_ballroom_map()
	var bounds := level_bounds()
	light_switch.position = Vector3(bounds.y - 0.14, 1.35, bounds.w - 0.8)
	light_switch.rotation.y = -PI * 0.5


func add_floor_section(rect: Rect2, color: Color) -> void:
	current_walkable_rects.append(rect.grow(-0.28))
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(rect.size.x, 0.018, rect.size.y)
	var floor_visual := MeshInstance3D.new()
	floor_visual.mesh = floor_mesh
	floor_visual.position = Vector3(rect.position.x + rect.size.x * 0.5, 0.039, rect.position.y + rect.size.y * 0.5)
	floor_visual.material_override = make_material(color)
	stage_root.add_child(floor_visual)
	var floor_body := StaticBody3D.new()
	floor_body.position = Vector3(rect.position.x + rect.size.x * 0.5, -0.035, rect.position.y + rect.size.y * 0.5)
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(rect.size.x, 0.12, rect.size.y)
	var floor_collider := CollisionShape3D.new()
	floor_collider.shape = floor_shape
	floor_body.add_child(floor_collider)
	stage_root.add_child(floor_body)


func build_room_shell(bounds: Vector4, color: Color, back_opening: float = 0.0) -> void:
	var width := bounds.y - bounds.x
	var depth := bounds.w - bounds.z
	add_stage_wall(Vector3(bounds.x, 1.7, (bounds.z + bounds.w) * 0.5), Vector3(0.18, 3.4, depth), color, true)
	add_stage_wall(Vector3(bounds.y, 1.7, (bounds.z + bounds.w) * 0.5), Vector3(0.18, 3.4, depth), color, true)
	if back_opening <= 0.0:
		add_stage_wall(Vector3(0.0, 1.7, bounds.z), Vector3(width, 3.4, 0.18), color, true)
	else:
		var side_width := (width - back_opening) * 0.5
		add_stage_wall(Vector3(bounds.x + side_width * 0.5, 1.7, bounds.z), Vector3(side_width, 3.4, 0.18), color, true)
		add_stage_wall(Vector3(bounds.y - side_width * 0.5, 1.7, bounds.z), Vector3(side_width, 3.4, 0.18), color, true)


func build_foyer_map() -> void:
	var b := level_bounds()
	add_floor_section(Rect2(-2.8, -3.0, 5.6, 5.5), Color("8a5e3b"))
	build_room_shell(b, Color("d5a85c"), 1.8)
	add_stage_wall(Vector3(-1.65, 0.42, -1.7), Vector3(0.5, 0.84, 0.5), Color("e4c77b"), true)
	add_stage_wall(Vector3(1.65, 0.42, -1.7), Vector3(0.5, 0.84, 0.5), Color("e4c77b"), true)
	place_room_asset(room_asset_paths[0][1], Vector3(-2.0, 0.055, 1.25), PI * 0.5, 0.85)
	place_room_asset(room_asset_paths[0][2], Vector3(1.65, 0.055, 0.75), -PI * 0.7, 0.9)
	place_room_asset("res://assets/kenney_building/door-rotate-round-a.glb", Vector3(0, 0.05, -2.9), 0, 1.1)
	reserve_spawn_area(Vector2(-2.0, 1.25), Vector2(1.2, 1.2))
	reserve_spawn_area(Vector2(1.65, 0.75), Vector2(1.4, 1.4))
	reserve_spawn_area(Vector2(0, -2.4), Vector2(2.0, 1.0))


func build_guest_suite_map() -> void:
	var b := level_bounds()
	add_floor_section(Rect2(-4.3, -4.0, 8.6, 5.3), Color("497f88"))
	add_floor_section(Rect2(-1.8, 1.3, 6.1, 2.2), Color("5f9298"))
	build_room_shell(b, Color("72b0b7"), 1.5)
	add_stage_wall(Vector3(-1.8, 0.7, 2.35), Vector3(0.18, 1.4, 2.3), Color("72b0b7"), true)
	place_room_asset(room_asset_paths[1][0], Vector3(-2.35, 0.055, -2.25), PI * 0.5, 1.05)
	place_room_asset(room_asset_paths[1][1], Vector3(2.65, 0.055, -1.8), -PI * 0.5, 0.95)
	place_room_asset(room_asset_paths[1][2], Vector3(1.6, 0.055, 2.55), PI, 0.9)
	place_room_asset(room_asset_paths[1][3], Vector3(0.0, 0.05, -0.3), 0, 1.4)
	reserve_spawn_area(Vector2(-2.35, -2.25), Vector2(2.5, 2.2))
	reserve_spawn_area(Vector2(2.65, -1.8), Vector2(1.8, 1.4))
	reserve_spawn_area(Vector2(0, -0.3), Vector2(2.4, 1.8))


func build_dining_map() -> void:
	var b := level_bounds()
	add_floor_section(Rect2(-5.8, -5.0, 11.6, 9.8), Color("78464f"))
	build_room_shell(b, Color("b06a72"), 2.4)
	for x in [-4.7, 4.7]:
		place_room_asset("res://assets/kenney_building/column-wide.glb", Vector3(x, 0.05, -3.7), 0, 1.1)
	for z in [-2.5, 0.0, 2.5]:
		place_room_asset(room_asset_paths[2][0], Vector3(0.0, 0.055, z), 0, 1.0)
		place_room_asset(room_asset_paths[2][1], Vector3(-2.0, 0.055, z), PI * 0.5, 0.9)
		place_room_asset(room_asset_paths[2][1], Vector3(2.0, 0.055, z), -PI * 0.5, 0.9)
	place_room_asset(room_asset_paths[2][2], Vector3(0, 0.83, 0), 0, 0.75)
	reserve_spawn_area(Vector2(0, 0), Vector2(5.0, 7.8))


func build_library_map() -> void:
	var b := level_bounds()
	add_floor_section(Rect2(-7.0, -6.0, 14.0, 8.0), Color("3e674f"))
	add_floor_section(Rect2(-4.8, 2.0, 9.6, 3.8), Color("52795f"))
	build_room_shell(b, Color("73946d"), 1.8)
	add_stage_wall(Vector3(0, 0.7, 2.0), Vector3(4.0, 1.4, 0.16), Color("73946d"), true)
	for x in [-5.9, -3.0, 3.0, 5.9]:
		place_room_asset(room_asset_paths[3][0], Vector3(x, 0.055, -5.35), 0, 1.0)
	place_room_asset(room_asset_paths[3][3], Vector3(0, 0.055, 3.8), PI, 1.05)
	place_room_asset(room_asset_paths[3][2], Vector3(-2.4, 0.75, 3.55), 0, 0.85)
	reserve_spawn_area(Vector2(0, -5.25), Vector2(13.0, 1.3))
	reserve_spawn_area(Vector2(0, 3.8), Vector2(3.4, 1.8))


func build_ballroom_map() -> void:
	var b := level_bounds()
	add_floor_section(Rect2(-8.5, -5.2, 17.0, 10.0), Color("665080"))
	add_floor_section(Rect2(-6.7, -7.0, 13.4, 1.8), Color("4e3c67"))
	add_floor_section(Rect2(-6.7, 4.8, 13.4, 1.6), Color("806394"))
	build_room_shell(b, Color("a17bb0"), 3.0)
	for x in [-7.2, -4.8, 4.8, 7.2]:
		place_room_asset(room_asset_paths[4][0], Vector3(x, 0.055, -4.3), 0, 1.2)
	for x in [-5.7, 0.0, 5.7]:
		place_room_asset(room_asset_paths[4][1], Vector3(x, 0.055, 1.8), 0, 1.0)
	place_room_asset("res://assets/kenney_building/stairs-center-short.glb", Vector3(0, 0.05, -5.8), 0, 1.65)
	place_room_asset(room_asset_paths[4][2], Vector3(-6.6, 0.055, 4.0), PI * 0.5, 1.05)
	place_room_asset(room_asset_paths[4][2], Vector3(6.6, 0.055, 4.0), -PI * 0.5, 1.05)
	reserve_spawn_area(Vector2(0, -5.6), Vector2(14.0, 2.2))
	reserve_spawn_area(Vector2(-6.6, 4.0), Vector2(2.0, 1.6))
	reserve_spawn_area(Vector2(6.6, 4.0), Vector2(2.0, 1.6))
	for x in [-5.7, 0.0, 5.7]:
		reserve_spawn_area(Vector2(x, 1.8), Vector2(1.8, 1.8))


func place_room_asset(path: String, position: Vector3, yaw: float = 0.0, uniform_scale: float = 1.0, parent: Node3D = stage_root) -> Node3D:
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var model := packed.instantiate() as Node3D
	if model == null:
		return null
	model.position = position
	model.rotation.y = yaw
	model.scale = Vector3.ONE * uniform_scale
	parent.add_child(model)
	return model


func add_stage_wall(position: Vector3, size: Vector3, color: Color, with_collision: bool = false) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = position
	visual.material_override = make_material(color)
	stage_root.add_child(visual)
	if with_collision:
		var body := StaticBody3D.new()
		body.position = position
		var shape := BoxShape3D.new()
		shape.size = size
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)
		stage_root.add_child(body)


func build_cleanup_tasks(rng: RandomNumberGenerator) -> void:
	var bounds := level_bounds()
	for i in room_dirt_counts[current_level - 1]:
		var on_wall: bool = i % 2 == 1
		var floor_spot := random_room_spot(rng)
		var pos := Vector3(floor_spot.x, 0.065, floor_spot.y)
		var size := Vector3(0.72, 0.025, 0.72)
		if on_wall:
			var wall_x := bounds.x + 0.11 if i % 4 == 1 else bounds.y - 0.11
			pos = Vector3(wall_x, rng.randf_range(0.7, 2.2), rng.randf_range(bounds.z + 0.8, bounds.w - 0.8))
			size = Vector3(0.04, 0.62, 0.72)
		var dirt := make_cleanup_body("Wall grime" if on_wall else "Floor dirt", pos, size, Color("665044"), 8)
		dirt_spots.append(dirt)
	for i in room_item_counts[current_level - 1]:
		var item_spot := random_room_spot(rng)
		var pos2 := Vector3(item_spot.x, 0.20, item_spot.y)
		var item := make_asset_cleanup_body(pos2, fallen_asset_paths[i % fallen_asset_paths.size()])
		var target_spot := random_room_spot(rng)
		var target := Vector3(target_spot.x, 0.20, target_spot.y)
		item.set_meta("target", target)
		misplaced_items.append(item)
		var marker_mesh := BoxMesh.new()
		marker_mesh.size = Vector3(0.42, 0.025, 0.42)
		var marker := MeshInstance3D.new()
		marker.mesh = marker_mesh
		marker.position = Vector3(target.x, 0.06, target.z)
		marker.material_override = make_material(Color(0.35, 0.85, 0.55, 0.45))
		marker.visible = false
		marker.set_meta("organize_marker", true)
		stage_root.add_child(marker)
	set_cleanup_tasks_visible(false, false)


func make_asset_cleanup_body(position: Vector3, asset_path: String) -> StaticBody3D:
	var body := make_cleanup_body("Fallen object", position, Vector3(0.38, 0.34, 0.38), Color(0, 0, 0, 0), 16)
	var block_visual := body.get_child(0) as MeshInstance3D
	if block_visual != null:
		block_visual.visible = false
	place_room_asset(asset_path, Vector3.ZERO, randf_range(-PI, PI), 0.72, body)
	return body


func make_cleanup_body(body_name: String, position: Vector3, size: Vector3, color: Color, layer: int) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = body_name
	body.position = position
	body.collision_layer = layer
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = make_material(color)
	body.add_child(visual)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	stage_root.add_child(body)
	return body


func set_cleanup_tasks_visible(show_dirt: bool, show_items: bool) -> void:
	for dirt in dirt_spots:
		if is_instance_valid(dirt):
			dirt.visible = show_dirt
			dirt.collision_layer = 8 if show_dirt else 0
	for item in misplaced_items:
		if is_instance_valid(item):
			item.visible = show_items
			item.collision_layer = 16 if show_items else 0
	for child in stage_root.get_children():
		if child.has_meta("organize_marker"):
			child.visible = show_items


func advance_cleanup_phase() -> void:
	if cleanup_phase == 0:
		cleanup_phase = 1
		set_cleanup_tasks_visible(true, false)
		message = "PHASE 2: Mop floor stains and wipe grime from the walls."
	elif cleanup_phase == 1:
		cleanup_phase = 2
		set_cleanup_tasks_visible(false, true)
		message = "PHASE 3: Click fallen objects to return them to the green markers."
	else:
		complete_cleanup_room()
	update_ui()


func interact_cleanup_task(origin: Vector3, direction: Vector3) -> bool:
	var mask := 8 if cleanup_phase == 1 else 16
	var reach := 4.2 + float(organize_skill) * 0.8 if cleanup_phase == 2 else 4.2
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * reach)
	query.collision_mask = mask
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		message = "Aim at a dirty patch." if cleanup_phase == 1 else "Aim at a fallen object."
		update_ui()
		return true
	var body: StaticBody3D = hit["collider"]
	if cleanup_phase == 1:
		var cleaned_now := 0
		var max_clean := 1 + mop_skill
		var center := body.global_position
		var candidates := dirt_spots.duplicate()
		for dirt in candidates:
			if cleaned_now >= max_clean:
				break
			if is_instance_valid(dirt) and (dirt == body or dirt.global_position.distance_to(center) <= 0.65 + float(mop_skill) * 0.55):
				dirt_spots.erase(dirt)
				dirt.queue_free()
				cleaned_now += 1
		cleaned_surfaces += cleaned_now
		message = "Surface cleaned. %d / %d" % [cleaned_surfaces, room_dirt_counts[current_level - 1]]
		if cleaned_surfaces >= room_dirt_counts[current_level - 1]: advance_cleanup_phase()
	else:
		organized_items += 1
		misplaced_items.erase(body)
		body.collision_layer = 0
		var tween := create_tween()
		var organize_time := maxf(0.12, 0.42 - float(organize_skill) * 0.09)
		tween.tween_property(body, "position", body.get_meta("target"), organize_time).set_trans(Tween.TRANS_BACK)
		message = "Object returned. %d / %d" % [organized_items, room_item_counts[current_level - 1]]
		if organized_items >= room_item_counts[current_level - 1]:
			await tween.finished
			advance_cleanup_phase()
	update_ui()
	return true


func complete_cleanup_room() -> void:
	playing = false
	mouse_captured = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	coins += level_values[current_level - 1]
	skill_points += 2
	pearl_sold = true
	tools_bar.visible = false
	crosshair.visible = false
	hint_panel.visible = false
	shop_panel.visible = true
	update_shop()


func add_pearl(position: Vector3, rng: RandomNumberGenerator) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = position
	body.collision_layer = 2
	body.collision_mask = 0
	var radius := FOAM_RADIUS
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = pearl_material
	body.add_child(visual)
	var shape := SphereShape3D.new()
	shape.radius = radius
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	foam_root.add_child(body)
	return body


func build_foam_meshes(group_counts: Array) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = FOAM_RADIUS
	sphere.height = FOAM_RADIUS * 2.0
	sphere.radial_segments = 6
	sphere.rings = 3
	for group_index in foam_materials.size():
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = sphere
		multi.instance_count = group_counts[group_index]
		var visual := MultiMeshInstance3D.new()
		visual.multimesh = multi
		visual.material_override = foam_materials[group_index]
		foam_root.add_child(visual)
		foam_meshes.append(multi)
	for i in foam_positions.size():
		update_foam_transform(i)


func update_foam_transform(index: int) -> void:
	var position := foam_positions[index] if foam_alive[index] else Vector3(0.0, -1000.0, 0.0)
	foam_meshes[foam_groups[index]].set_instance_transform(foam_slots[index], Transform3D(Basis(), position))


func foam_cell_for(position: Vector3) -> Vector2i:
	return Vector2i(floori(position.x / FOAM_CELL_SIZE), floori(position.z / FOAM_CELL_SIZE))


func foam_stack_cell_for(position: Vector3) -> Vector2i:
	return Vector2i(floori(position.x / FOAM_DIAMETER), floori(position.z / FOAM_DIAMETER))


func rebuild_stack_column(key: Vector2i) -> void:
	if not foam_stack_columns.has(key):
		return
	var layer := 0
	for index in foam_stack_columns[key]:
		if not foam_alive[index]:
			continue
		foam_rest_heights[index] = FOAM_BASE_Y + float(layer) * FOAM_DIAMETER
		if absf(foam_positions[index].y - foam_rest_heights[index]) > 0.005 and not foam_moving[index]:
			foam_moving[index] = true
			moving_indices.append(index)
		layer += 1


func remove_foam(index: int) -> void:
	foam_alive[index] = false
	var key := foam_stack_keys[index]
	foam_stack_columns[key].erase(index)
	rebuild_stack_column(key)
	update_foam_transform(index)


func remove_foam_cluster(center_index: int) -> int:
	var removed := 0
	var limit := 1 + hand_skill * 2
	var candidates: Array[int] = [center_index]
	if hand_skill > 0:
		for nearby in foam_near(foam_positions[center_index], FOAM_DIAMETER * (2.0 + float(hand_skill))):
			if nearby != center_index:
				candidates.append(nearby)
	for index in candidates:
		if removed >= limit:
			break
		if index >= 0 and index < foam_alive.size() and foam_alive[index]:
			remove_foam(index)
			removed += 1
	return removed


func transfer_foam_stack(index: int, new_key: Vector2i) -> void:
	var old_key := foam_stack_keys[index]
	if new_key == old_key:
		return
	foam_stack_columns[old_key].erase(index)
	rebuild_stack_column(old_key)
	if not foam_stack_columns.has(new_key):
		foam_stack_columns[new_key] = []
	foam_stack_columns[new_key].append(index)
	foam_stack_keys[index] = new_key
	foam_rest_heights[index] = FOAM_BASE_Y + float(foam_stack_columns[new_key].size() - 1) * FOAM_DIAMETER


func foam_near(position: Vector3, radius: float) -> Array[int]:
	var found_indices: Array[int] = []
	var min_cell := foam_cell_for(position - Vector3(radius, 0.0, radius))
	var max_cell := foam_cell_for(position + Vector3(radius, 0.0, radius))
	for x in range(min_cell.x, max_cell.x + 1):
		for z in range(min_cell.y, max_cell.y + 1):
			var cell := Vector2i(x, z)
			if foam_cells.has(cell):
				for index in foam_cells[cell]:
					if foam_alive[index] and foam_positions[index].distance_to(position) < radius:
						found_indices.append(index)
	return found_indices


func _physics_process(delta: float) -> void:
	if not playing or game_paused:
		return
	blow_cooldown = maxf(0.0, blow_cooldown - delta)
	push_cooldown = maxf(0.0, push_cooldown - delta)
	last_foam_assist_timer += delta
	if blower_on and mouse_captured and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and blow_cooldown <= 0.0:
		blow_forward()
		blow_cooldown = 0.22
	var axis := Vector2.ZERO
	if movement_keys[KEY_A]: axis.x -= 1.0
	if movement_keys[KEY_D]: axis.x += 1.0
	if movement_keys[KEY_W]: axis.y -= 1.0
	if movement_keys[KEY_S]: axis.y += 1.0
	var wants_crouch := Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_C)
	if wants_crouch != crouching:
		set_crouching(wants_crouch)
	var move_dir := (player.global_basis.x * axis.x + player.global_basis.z * axis.y).normalized()
	var move_speed := WALK_SPEED * (1.0 + float(mobility_skill) * 0.12)
	if crouching:
		move_speed *= 0.68 + float(mobility_skill) * 0.07
	player.velocity.x = move_dir.x * move_speed
	player.velocity.z = move_dir.z * move_speed
	player.velocity.y -= 18.0 * delta
	player.move_and_slide()
	if push_cooldown <= 0.0:
		push_foam_around_player()
		push_cooldown = 0.09
	move_foam(delta)
	update_uv_hint()
	update_switch_prompt()


func set_crouching(enabled: bool) -> void:
	crouching = enabled
	view.position.y = 0.82 if crouching else 1.55
	player_capsule.height = 1.0 if crouching else 1.7
	player_collider.position.y = 0.50 if crouching else 0.85


func update_switch_prompt() -> void:
	var origin := view.global_position
	var direction := -view.global_basis.z
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 3.2)
	query.collision_mask = 4
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	hint.text = "E / CLICK: FLIP LIGHT SWITCH" if not hit.is_empty() and hit["collider"] == light_switch else message
	hint_panel.visible = not hint.text.is_empty()


func move_foam(delta: float) -> void:
	chain_time += delta
	var chain_checks := 0
	var chain_spread := 0
	for slot in range(moving_indices.size() - 1, -1, -1):
		var index := moving_indices[slot]
		if not foam_alive[index]:
			foam_moving[index] = false
			moving_indices.remove_at(slot)
			continue
		var velocity := foam_velocities[index]
		velocity.y += (foam_rest_heights[index] - foam_positions[index].y) * 9.0 * delta
		velocity *= 0.94
		var position := foam_positions[index] + velocity * delta
		if position.y < FOAM_BASE_Y:
			position.y = FOAM_BASE_Y
			velocity.y = absf(velocity.y) * 0.48
			velocity.x *= 0.82
			velocity.z *= 0.82
		if position.x < -8.7 or position.x > 8.7:
			position.x = clampf(position.x, -8.7, 8.7)
			velocity.x *= -0.55
		if position.z < -8.7 or position.z > 6.7:
			position.z = clampf(position.z, -8.7, 6.7)
			velocity.z *= -0.55
		foam_positions[index] = position
		foam_velocities[index] = velocity
		var new_cell := foam_cell_for(position)
		if new_cell != foam_cell_keys[index]:
			foam_cells[foam_cell_keys[index]].erase(index)
			if not foam_cells.has(new_cell):
				foam_cells[new_cell] = []
			foam_cells[new_cell].append(index)
			foam_cell_keys[index] = new_cell
		update_foam_transform(index)
		if chain_checks < 160 and chain_spread < 60 and velocity.length() > 0.65:
			chain_checks += 1
			chain_spread += spread_foam_impulse(index, position, velocity, 60 - chain_spread)
		if absf(position.y - foam_rest_heights[index]) < 0.025 and velocity.length() < 0.18:
			transfer_foam_stack(index, foam_stack_cell_for(position))
			if absf(position.y - foam_rest_heights[index]) >= 0.025:
				continue
			position.y = foam_rest_heights[index]
			position.x = (float(foam_stack_keys[index].x) + 0.5) * FOAM_DIAMETER
			position.z = (float(foam_stack_keys[index].y) + 0.5) * FOAM_DIAMETER
			foam_positions[index] = position
			foam_velocities[index] = Vector3.ZERO
			var settled_cell := foam_cell_for(position)
			if settled_cell != foam_cell_keys[index]:
				foam_cells[foam_cell_keys[index]].erase(index)
				if not foam_cells.has(settled_cell):
					foam_cells[settled_cell] = []
				foam_cells[settled_cell].append(index)
				foam_cell_keys[index] = settled_cell
			update_foam_transform(index)
			foam_moving[index] = false
			moving_indices.remove_at(slot)


func spread_foam_impulse(source: int, position: Vector3, velocity: Vector3, limit: int) -> int:
	if chain_time - foam_chain_last_hit[source] < 0.16:
		return 0
	var spread := 0
	for neighbor in foam_near(position, FOAM_RADIUS * 2.5):
		if neighbor == source or foam_moving[neighbor] or chain_time - foam_chain_last_hit[neighbor] < 0.35:
			continue
		var away := foam_positions[neighbor] - position
		if away.length_squared() < 0.00001:
			away = velocity.normalized()
		foam_velocities[neighbor] += velocity * 0.40 + away.normalized() * 0.62 + Vector3.UP * 0.12
		foam_chain_last_hit[neighbor] = chain_time
		if not foam_moving[neighbor]:
			foam_moving[neighbor] = true
			moving_indices.append(neighbor)
		spread += 1
		if spread >= limit:
			break
	if spread > 0:
		foam_chain_last_hit[source] = chain_time
		foam_velocities[source] *= 0.65
	return spread


func push_foam_around_player() -> void:
	var center := player.global_position + Vector3.UP * 0.75
	for index in foam_near(center, 0.72):
		var away := foam_positions[index] - center
		away.y = 0.0
		if away.length_squared() < 0.001:
			away = -view.global_basis.z
		foam_velocities[index] += away.normalized() * 1.3 + Vector3.UP * 0.7
		if not foam_moving[index]:
			foam_moving[index] = true
			moving_indices.append(index)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		var physical: int = event.physical_keycode
		var logical: int = event.keycode
		for key in movement_keys.keys():
			if physical == key or logical == key:
				movement_keys[key] = event.pressed


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K and (playing or shop_panel.visible):
			if skill_panel.visible:
				close_skill_tree()
			else:
				open_skill_tree(shop_panel.visible, game_paused)
		elif event.keycode == KEY_F10 and playing:
			if cheat_panel.visible:
				close_cheat_menu()
			else:
				open_cheat_menu()
		elif event.keycode == KEY_M:
			show_modes()
		elif event.keycode == KEY_R and mode != "":
			start_round(mode)
		elif event.keycode == KEY_ESCAPE and cheat_panel.visible:
			close_cheat_menu()
		elif event.keycode == KEY_ESCAPE and level_select_panel.visible:
			close_level_select()
		elif event.keycode == KEY_ESCAPE and skill_panel.visible:
			close_skill_tree()
		elif event.keycode == KEY_ESCAPE and game_paused:
			resume_game()
		elif event.keycode == KEY_ESCAPE and playing:
			pause_game()
		elif event.keycode == KEY_1 and playing:
			select_tool(0)
		elif event.keycode == KEY_2 and playing and owns_uv:
			select_tool(1)
		elif event.keycode == KEY_3 and playing and owns_blower:
			select_tool(2)
		elif event.keycode == KEY_E and playing:
			search_center()
	if event is InputEventMouseMotion and mouse_captured:
		player.rotate_y(-event.relative.x * LOOK_SPEED)
		view.rotation.x = clampf(view.rotation.x - event.relative.y * LOOK_SPEED, -1.45, 1.45)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and playing and not game_paused and not skill_panel.visible:
		if mouse_captured:
			search_center()
		else:
			capture_mouse()


func capture_mouse() -> void:
	mouse_captured = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func search_center() -> void:
	var origin := view.global_position
	var direction := -view.global_basis.z
	var switch_query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 3.2)
	switch_query.collision_mask = 4
	var switch_hit := get_world_3d().direct_space_state.intersect_ray(switch_query)
	if not switch_hit.is_empty() and switch_hit["collider"] == light_switch:
		toggle_room_light()
		return
	if cleanup_phase > 0:
		interact_cleanup_task(origin, direction)
		return
	if uv_on:
		message = "UV is scanning. Switch to your hand or blower to move foam."
		update_ui()
		return
	if owns_blower and blower_on:
		blow_forward()
		return
	var foam_hit := ray_pick_foam(origin, direction, 3.2)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 3.2)
	query.collision_mask = 2
	var pearl_hit := get_world_3d().direct_space_state.intersect_ray(query)
	var pearl_distance := origin.distance_to(pearl_hit["position"]) if not pearl_hit.is_empty() else INF
	if foam_hit["index"] >= 0 and foam_hit["distance"] < pearl_distance:
		var index: int = foam_hit["index"]
		var picked := remove_foam_cluster(index)
		removed_foam += picked
		last_foam_assist_timer = 0.0
		message = "%d foam bead%s removed." % [picked, "s" if picked > 1 else ""]
		if removed_foam >= current_foam_count:
			advance_cleanup_phase()
	elif not pearl_hit.is_empty():
		var bead: PhysicsBody3D = pearl_hit["collider"]
		found += 1
		pearls.erase(bead)
		message = "Pearl found! %d / %d" % [found, PEARL_COUNT]
		if found == PEARL_COUNT:
			open_shop()
		bead.queue_free()
	else:
		message = "Move closer to the foam and aim at a bead."
	update_ui()


func ray_pick_foam(origin: Vector3, direction: Vector3, max_distance: float) -> Dictionary:
	var best_index := -1
	var best_distance := max_distance + 1.0
	var visited_cells: Dictionary = {}
	var step := 0.0
	while step <= max_distance + 0.25:
		var sample := origin + direction * step
		var base_cell := foam_cell_for(sample)
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				var cell := base_cell + Vector2i(dx, dz)
				if visited_cells.has(cell) or not foam_cells.has(cell):
					continue
				visited_cells[cell] = true
				for i in foam_cells[cell]:
					if not foam_alive[i]:
						continue
					var offset := foam_positions[i] - origin
					var along := offset.dot(direction)
					if along < 0.0 or along > max_distance or along >= best_distance:
						continue
					var side_squared := offset.length_squared() - along * along
					if side_squared <= FOAM_RADIUS * FOAM_RADIUS:
						best_index = i
						best_distance = along
		step += 0.25
	return {"index": best_index, "distance": best_distance}


func blow_forward() -> void:
	var origin := view.global_position
	var direction := -view.global_basis.z
	var hit := ray_pick_foam(origin, direction, 4.5)
	var center: Vector3 = origin + direction * (hit["distance"] if hit["index"] >= 0 else 2.8)
	blow_at(center)


func blow_at(center: Vector3) -> void:
	var affected := 0
	var forward := -view.global_basis.z
	var blow_radius := 1.15 + float(blower_level) * 0.35
	var blow_power := 1.35 + float(blower_level) * 0.4
	for i in foam_near(center, blow_radius):
		var outward: Vector3 = (foam_positions[i] - center).normalized()
		foam_velocities[i] += (forward * 0.75 + outward * 0.45 + Vector3.UP * 0.45) * blow_power
		if not foam_moving[i]:
			foam_moving[i] = true
			moving_indices.append(i)
		affected += 1
	message = "Blower pushed %d foam beads. Hold click to keep blowing." % affected
	update_ui()


func open_shop() -> void:
	playing = false
	mouse_captured = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	tools_bar.visible = false
	crosshair.visible = false
	hint_panel.visible = false
	shop_panel.visible = true
	update_shop()


func update_shop() -> void:
	shop_title.text = "ROOM %d COMPLETE\n%s RESTORED" % [current_level, cleanup_room_names[current_level - 1]]
	shop_money.text = "CLEANUP REWARD   +%d     TOTAL   %d" % [level_values[current_level - 1], coins]
	sell_button.visible = false
	buy_uv_button.visible = false
	buy_blower_button.visible = false
	upgrade_uv_button.visible = false
	upgrade_blower_button.visible = false
	next_level_button.disabled = false
	next_level_button.text = "ENTER ROOM %d" % (current_level + 1) if current_level < 5 else "REPLAY BALLROOM"
	update_skill_tree()


func sell_pearl() -> void:
	if pearl_sold:
		return
	coins += level_values[current_level - 1]
	pearl_sold = true
	update_shop()


func buy_uv() -> void:
	if coins < 50 or owns_uv:
		return
	coins -= 50
	owns_uv = true
	uv_level = 1
	update_shop()


func buy_blower() -> void:
	if coins < 120 or owns_blower:
		return
	coins -= 120
	owns_blower = true
	blower_level = 1
	update_shop()


func upgrade_uv() -> void:
	if coins < 100 or not owns_uv or uv_level >= 2:
		return
	coins -= 100
	uv_level += 1
	update_shop()


func upgrade_blower() -> void:
	if coins < 150 or not owns_blower or blower_level >= 2:
		return
	coins -= 150
	blower_level += 1
	update_shop()


func next_level() -> void:
	if not pearl_sold:
		return
	current_level = mini(5, current_level + 1)
	start_round("career")


func select_tool(index: int) -> void:
	if index == 1 and not owns_uv:
		return
	if index == 2 and not owns_blower:
		return
	selected_tool = index
	uv_on = index == 1
	blower_on = index == 2
	uv_flashlight.visible = uv_on
	match index:
		0: message = "Hand selected: click or press E to remove one foam bead."
		1: message = "UV selected: the marker points toward the pearl."
		2: message = "Blower selected: hold click to send foam flying."
	update_ui()


func toggle_room_light() -> void:
	room_light_on = not room_light_on
	room_light.visible = room_light_on
	update_light_switch()
	update_ui()


func update_uv_hint() -> void:
	uv_marker.visible = false
	if pearls.is_empty():
		update_last_foam_assist()
		return
	var nearest: PhysicsBody3D = pearls[0]
	var visual: MeshInstance3D = nearest.get_child(0)
	if not playing or (not secret_vision and not uv_on):
		visual.material_override = pearl_material
		uv_found = false
		return
	var direction := nearest.global_position - view.global_position
	var distance := direction.length()
	var uv_range := 1.9 + float(maxi(0, uv_level - 1)) * 0.8
	uv_flashlight.spot_range = uv_range
	var aimed := distance < uv_range and (-view.global_basis.z).dot(direction.normalized()) > cos(deg_to_rad(9.0))
	var uv_caught := uv_on and aimed and pearl_fully_visible(view.global_position, nearest.global_position)
	var highlighted := secret_vision or uv_caught
	visual.material_override = pearl_glow_material if highlighted else pearl_material
	if uv_caught and not uv_found and not secret_vision:
		message = "UV caught a glow! Look for the shining pearl."
		update_ui()
	uv_found = uv_caught
	if secret_vision and not view.is_position_behind(nearest.global_position):
		var point := view.unproject_position(nearest.global_position)
		var screen := get_viewport().get_visible_rect().size
		uv_marker.text = "◎  %.1fm" % distance if secret_vision else "◎"
		uv_marker.position = point.clamp(Vector2(28.0, 140.0), screen - Vector2(130.0, 40.0)) - Vector2(16.0, 25.0)
		uv_marker.visible = true
	elif secret_vision:
		uv_marker.text = "↶  PEARL BEHIND  %.1fm" % distance
		uv_marker.position = Vector2(get_viewport().get_visible_rect().size.x * 0.5 - 130.0, 155.0)
		uv_marker.visible = true


func update_last_foam_assist() -> void:
	if not playing or game_paused or cleanup_phase != 0:
		return
	var remaining := current_foam_count - removed_foam
	if remaining > 10 or remaining <= 0:
		return
	var nearest := -1
	var nearest_distance := INF
	var bounds := level_bounds()
	for i in foam_alive.size():
		if not foam_alive[i]:
			continue
		if foam_positions[i].y < FOAM_BASE_Y - 0.02 or foam_positions[i].x < bounds.x or foam_positions[i].x > bounds.y or foam_positions[i].z < bounds.z or foam_positions[i].z > bounds.w:
			relocate_hidden_foam(i)
		var distance := view.global_position.distance_to(foam_positions[i])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = i
	if nearest < 0:
		return
	if remaining <= 5 and last_foam_assist_timer >= 8.0:
		relocate_hidden_foam(nearest)
		nearest_distance = view.global_position.distance_to(foam_positions[nearest])
		last_foam_assist_timer = 0.0
		message = "Cleanup radar rescued a hidden foam bead. Look in front of you."
		update_ui()
	var target := foam_positions[nearest]
	var screen := get_viewport().get_visible_rect().size
	if not view.is_position_behind(target):
		uv_marker.text = "◆  FOAM %d LEFT  ·  %.1fm" % [remaining, nearest_distance]
		uv_marker.position = view.unproject_position(target).clamp(Vector2(30.0, 125.0), screen - Vector2(260.0, 55.0)) - Vector2(18.0, 26.0)
	else:
		uv_marker.text = "↶  LAST FOAM BEHIND  ·  %.1fm" % nearest_distance
		uv_marker.position = Vector2(screen.x * 0.5 - 150.0, 125.0)
	uv_marker.visible = true


func relocate_hidden_foam(index: int) -> void:
	if index < 0 or index >= foam_alive.size() or not foam_alive[index]:
		return
	var old_cell := foam_cell_keys[index]
	if foam_cells.has(old_cell):
		foam_cells[old_cell].erase(index)
	var front := -view.global_basis.z
	front.y = 0.0
	if front.length_squared() < 0.01:
		front = Vector3.FORWARD
	var bounds := level_bounds()
	var target := player.global_position + front.normalized() * 1.35
	target.x = clampf(target.x, bounds.x + 0.35, bounds.y - 0.35)
	target.z = clampf(target.z, bounds.z + 0.35, bounds.w - 0.35)
	target.y = FOAM_BASE_Y
	foam_positions[index] = target
	foam_velocities[index] = Vector3.ZERO
	transfer_foam_stack(index, foam_stack_cell_for(target))
	foam_positions[index].y = foam_rest_heights[index]
	var new_cell := foam_cell_for(foam_positions[index])
	if not foam_cells.has(new_cell):
		foam_cells[new_cell] = []
	foam_cells[new_cell].append(index)
	foam_cell_keys[index] = new_cell
	update_foam_transform(index)


func pearl_fully_visible(origin: Vector3, target: Vector3) -> bool:
	var right := view.global_basis.x * FOAM_RADIUS * 0.65
	var up := view.global_basis.y * FOAM_RADIUS * 0.65
	for offset in [Vector3.ZERO, right, -right, up, -up]:
		var sample: Vector3 = target + offset
		var ray := sample - origin
		var distance := ray.length() - FOAM_RADIUS * 0.5
		if distance <= 0.0 or ray_pick_foam(origin, ray.normalized(), distance)["index"] >= 0:
			return false
	return true


func update_ui() -> void:
	if hud == null:
		return
	var progress := "%d/%d FOAM" % [removed_foam, current_foam_count]
	if cleanup_phase == 1:
		progress = "%d/%d SURFACES" % [cleaned_surfaces, room_dirt_counts[current_level - 1]]
	elif cleanup_phase == 2:
		progress = "%d/%d OBJECTS" % [organized_items, room_item_counts[current_level - 1]]
	var stance := "CROUCH" if crouching else "STAND"
	hud.text = "ROOM %d/5 · %s    PHASE %d/3 · %s    %s    $%d · SP %d    %s" % [current_level, cleanup_room_names[current_level - 1], cleanup_phase + 1, phase_names[cleanup_phase], progress, coins, skill_points, stance]
	hint.text = message
	hint_panel.visible = playing and not message.is_empty()
	for i in tool_buttons.size():
		var style := StyleBoxFlat.new()
		style.bg_color = Color("314251") if i == selected_tool else Color("1d2933")
		style.border_width_left = 4 if i == selected_tool else 2
		style.border_width_top = 4 if i == selected_tool else 2
		style.border_width_right = 4 if i == selected_tool else 2
		style.border_width_bottom = 4 if i == selected_tool else 2
		style.border_color = Color("fff1c4") if i == selected_tool else Color("708b9a")
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		tool_buttons[i].add_theme_stylebox_override("normal", style)
		tool_buttons[i].add_theme_stylebox_override("hover", style)
		tool_buttons[i].add_theme_stylebox_override("pressed", style)
