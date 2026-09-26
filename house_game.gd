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
	var floor_mat := make_material(Color("d6a875"))
	var wall_mat := make_material(Color("f6e9ce"))
	var trim_mat := make_material(Color("277f91"))
	box("Yard", Vector3(0.0, -0.22, 7.0), Vector3(38.0, 0.4, 32.0), grass)
	box("House floor", Vector3(0.0, -0.04, -1.0), Vector3(18.0, 0.14, 16.0), floor_mat)
	box("Back wall", Vector3(0.0, 2.1, -9.0), Vector3(18.0, 4.2, 0.22), wall_mat)
	box("Left wall", Vector3(-9.0, 2.1, -1.0), Vector3(0.22, 4.2, 16.0), wall_mat)
	box("Right wall", Vector3(9.0, 2.1, -1.0), Vector3(0.22, 4.2, 16.0), wall_mat)
	# The front wall leaves a walkable doorway in its center.
	box("Front wall left", Vector3(-5.1, 2.1, 7.0), Vector3(7.8, 4.2, 0.22), wall_mat)
	box("Front wall right", Vector3(5.1, 2.1, 7.0), Vector3(7.8, 4.2, 0.22), wall_mat)
	box("Door lintel", Vector3(0.0, 3.4, 7.0), Vector3(2.4, 1.6, 0.22), wall_mat)
	box("Door frame left", Vector3(-1.24, 1.3, 7.12), Vector3(0.15, 2.6, 0.2), trim_mat, false)
	box("Door frame right", Vector3(1.24, 1.3, 7.12), Vector3(0.15, 2.6, 0.2), trim_mat, false)
	box("Door frame top", Vector3(0.0, 2.65, 7.12), Vector3(2.6, 0.15, 0.2), trim_mat, false)
	box("Ceiling", Vector3(0.0, 4.25, -1.0), Vector3(18.0, 0.18, 16.0), wall_mat)
	box("Welcome path", Vector3(0.0, 0.005, 10.0), Vector3(2.5, 0.03, 6.0), make_material(Color("f1c5a0")), false)
	# Simple furniture gives the search room recognizable landmarks.
	box("Sofa", Vector3(-7.0, 0.55, -6.8), Vector3(2.5, 1.0, 0.9), make_material(Color("558eaa")))
	box("Table", Vector3(6.8, 0.75, -6.2), Vector3(2.0, 0.2, 1.3), trim_mat)
	box("Shelf", Vector3(8.2, 1.0, 2.0), Vector3(0.8, 2.0, 2.6), trim_mat)
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
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.7
	var collider := CollisionShape3D.new()
	collider.shape = capsule
	collider.position.y = 0.85
	player.add_child(collider)
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
	controls.text = "1. Clear every foam bead   2. Mop floors and wipe walls\n3. Put fallen objects back in place\nWASD move · Mouse look · Click/E interact"
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
	make_shop_ui(root)
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
	next_level_button = shop_button(shop, "NEXT LEVEL", next_level)
	shop_panel.visible = false


func shop_button(parent: Control, text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 44.0
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func show_modes() -> void:
	playing = false
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
	message = ""
	mouse_captured = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	update_ui()


func start_new_career() -> void:
	coins = 0
	current_level = 1
	pearl_sold = false
	owns_uv = false
	owns_blower = false
	uv_level = 0
	blower_level = 0
	start_round("career")


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
	for attempt in 20:
		var x := rng.randf_range(bounds.x, bounds.y)
		var z := rng.randf_range(bounds.z, bounds.w)
		var inside_sofa := x < -5.5 and z < -6.15
		var inside_shelf := x > 7.6 and z > 0.45 and z < 3.55
		if not inside_sofa and not inside_shelf:
			return Vector2(x, z)
	return Vector2.ZERO


func level_bounds() -> Vector4:
	var sizes := [2.4, 3.4, 4.6, 6.0, 8.0]
	var size: float = sizes[current_level - 1]
	return Vector4(-size, size, -size, minf(size, 6.4))


func build_level_layout() -> void:
	for child in stage_root.get_children():
		child.queue_free()
	var bounds := level_bounds()
	var width := bounds.y - bounds.x
	var depth := bounds.w - bounds.z
	var accent_colors := [Color("d8a86d"), Color("78aab4"), Color("b184aa"), Color("79a778")]
	var accent: Color = accent_colors[(current_level - 1) % accent_colors.size()]
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(width + 0.35, 0.018, depth + 0.35)
	var floor_visual := MeshInstance3D.new()
	floor_visual.mesh = floor_mesh
	# Keep the decorative level floor slightly above the house floor to prevent z-fighting.
	floor_visual.position = Vector3(0.0, 0.039, (bounds.z + bounds.w) * 0.5)
	floor_visual.material_override = make_material(accent.darkened(0.28))
	stage_root.add_child(floor_visual)
	add_stage_wall(Vector3(bounds.x, 0.55, (bounds.z + bounds.w) * 0.5), Vector3(0.16, 1.1, depth), accent)
	add_stage_wall(Vector3(bounds.y, 0.55, (bounds.z + bounds.w) * 0.5), Vector3(0.16, 1.1, depth), accent)
	add_stage_wall(Vector3(0.0, 0.55, bounds.z), Vector3(width, 1.1, 0.16), accent)
	# Temporary low-poly furniture. Real assets can replace these mockup blocks later.
	var furniture := 2 + current_level * 2
	for i in furniture:
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * (width * 0.30)
		var z := lerpf(bounds.z + 0.8, bounds.w - 0.8, float(i + 1) / float(furniture + 1))
		add_stage_wall(Vector3(x, 0.32, z), Vector3(0.9 + 0.15 * (i % 3), 0.64, 0.55), accent.lightened(0.12))


func add_stage_wall(position: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = position
	visual.material_override = make_material(color)
	stage_root.add_child(visual)


func build_cleanup_tasks(rng: RandomNumberGenerator) -> void:
	var bounds := level_bounds()
	for i in room_dirt_counts[current_level - 1]:
		var on_wall: bool = i % 2 == 1
		var pos := Vector3(rng.randf_range(bounds.x + 0.7, bounds.y - 0.7), 0.065, rng.randf_range(bounds.z + 0.7, bounds.w - 0.7))
		var size := Vector3(0.72, 0.025, 0.72)
		if on_wall:
			pos = Vector3(rng.randf_range(bounds.x + 0.8, bounds.y - 0.8), rng.randf_range(0.7, 2.2), bounds.z + 0.11)
			size = Vector3(0.72, 0.62, 0.04)
		var dirt := make_cleanup_body("Wall grime" if on_wall else "Floor dirt", pos, size, Color("665044"), 8)
		dirt_spots.append(dirt)
	for i in room_item_counts[current_level - 1]:
		var pos2 := Vector3(rng.randf_range(bounds.x + 0.9, bounds.y - 0.9), 0.20, rng.randf_range(bounds.z + 0.9, bounds.w - 0.9))
		var item := make_cleanup_body("Fallen object", pos2, Vector3(0.34, 0.34, 0.34), [Color("e17d7d"), Color("76b8c4"), Color("e4bd62")][i % 3], 16)
		var target := Vector3(lerpf(bounds.x + 0.8, bounds.y - 0.8, float(i + 1) / float(room_item_counts[current_level - 1] + 1)), 0.20, bounds.z + 0.55)
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
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 4.2)
	query.collision_mask = mask
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		message = "Aim at a dirty patch." if cleanup_phase == 1 else "Aim at a fallen object."
		update_ui()
		return true
	var body: StaticBody3D = hit["collider"]
	if cleanup_phase == 1:
		cleaned_surfaces += 1
		dirt_spots.erase(body)
		body.queue_free()
		message = "Surface cleaned. %d / %d" % [cleaned_surfaces, room_dirt_counts[current_level - 1]]
		if cleaned_surfaces >= room_dirt_counts[current_level - 1]: advance_cleanup_phase()
	else:
		organized_items += 1
		misplaced_items.erase(body)
		body.collision_layer = 0
		var tween := create_tween()
		tween.tween_property(body, "position", body.get_meta("target"), 0.35).set_trans(Tween.TRANS_BACK)
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
	if not playing:
		return
	blow_cooldown = maxf(0.0, blow_cooldown - delta)
	push_cooldown = maxf(0.0, push_cooldown - delta)
	if blower_on and mouse_captured and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and blow_cooldown <= 0.0:
		blow_forward()
		blow_cooldown = 0.22
	var axis := Vector2.ZERO
	if Input.is_key_pressed(KEY_A): axis.x -= 1.0
	if Input.is_key_pressed(KEY_D): axis.x += 1.0
	if Input.is_key_pressed(KEY_W): axis.y -= 1.0
	if Input.is_key_pressed(KEY_S): axis.y += 1.0
	var move_dir := (player.global_basis.x * axis.x + player.global_basis.z * axis.y).normalized()
	player.velocity.x = move_dir.x * WALK_SPEED
	player.velocity.z = move_dir.z * WALK_SPEED
	player.velocity.y -= 18.0 * delta
	player.move_and_slide()
	if push_cooldown <= 0.0:
		push_foam_around_player()
		push_cooldown = 0.09
	move_foam(delta)
	update_uv_hint()
	update_switch_prompt()


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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F10 and playing:
			secret_vision = not secret_vision
			update_uv_hint()
		elif event.keycode == KEY_M:
			show_modes()
		elif event.keycode == KEY_R and mode != "":
			start_round(mode)
		elif event.keycode == KEY_ESCAPE and playing:
			mouse_captured = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			message = "Mouse released. Click to continue."
			update_ui()
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
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and playing:
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
		remove_foam(index)
		removed_foam += 1
		message = "One foam bead removed. Keep searching."
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
	hud.text = "ROOM %d/5 · %s    PHASE %d/3 · %s    %s" % [current_level, cleanup_room_names[current_level - 1], cleanup_phase + 1, phase_names[cleanup_phase], progress]
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
