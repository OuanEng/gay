extends Node3D

const FOAM_COUNT := 420
const PEARL_COUNT := 5
const ROUND_SECONDS := 120.0

var camera: Camera3D
var pile: Node3D
var hud: Label
var hint: Label
var overlay: Label
var menu: VBoxContainer
var tool_bar: HBoxContainer
var uv_button: Button
var blower_button: Button
var uv_markers: Array[Label] = []
var foam_materials: Array[StandardMaterial3D] = []
var pearl_material: StandardMaterial3D
var found := 0
var time_left := ROUND_SECONDS
var playing := false
var mode := "normal"
var uv_on := false
var blower_on := false
var dragging := false
var drag_distance := 0.0
var orbit_yaw := 0.65
var orbit_pitch := 0.65
var orbit_distance := 13.0
var hover_text := ""


func _ready() -> void:
	build_materials()
	build_world()
	build_ui()
	show_menu()


func build_materials() -> void:
	for color in [Color("f7f5ed"), Color("dfeef0"), Color("f2e8db"), Color("e5e3ee")]:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.88
		foam_materials.append(material)
	pearl_material = StandardMaterial3D.new()
	pearl_material.albedo_color = Color("fff2d0")
	pearl_material.metallic = 0.35
	pearl_material.roughness = 0.16


func build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("153345")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d6ecf2")
	env.ambient_light_energy = 0.65
	environment.environment = env
	add_child(environment)
	camera = Camera3D.new()
	camera.fov = 48.0
	camera.current = true
	add_child(camera)
	update_camera()
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	light.light_energy = 1.5
	add_child(light)
	var tray_material := StandardMaterial3D.new()
	tray_material.albedo_color = Color("326b73")
	tray_material.roughness = 0.65
	make_box(Vector3(0.0, -0.35, 0.0), Vector3(8.4, 0.5, 8.4), tray_material)
	for side in [-1.0, 1.0]:
		make_box(Vector3(side * 4.2, 0.05, 0.0), Vector3(0.24, 0.6, 8.65), tray_material)
		make_box(Vector3(0.0, 0.05, side * 4.2), Vector3(8.65, 0.6, 0.24), tray_material)
	pile = Node3D.new()
	pile.name = "SearchPile"
	add_child(pile)


func make_box(position: Vector3, dimensions: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	add_child(instance)


func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	hud = Label.new()
	hud.position = Vector2(22.0, 16.0)
	hud.add_theme_font_size_override("font_size", 25)
	hud.add_theme_color_override("font_color", Color("fff2ce"))
	root.add_child(hud)
	hint = Label.new()
	hint.position = Vector2(22.0, 55.0)
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", Color("e0f5f5"))
	root.add_child(hint)
	overlay = Label.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_theme_font_size_override("font_size", 32)
	overlay.add_theme_color_override("font_color", Color("fff2ce"))
	root.add_child(overlay)
	menu = VBoxContainer.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu.position = Vector2(-190.0, -75.0)
	menu.custom_minimum_size = Vector2(380.0, 150.0)
	menu.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(menu)
	var title := Label.new()
	title.text = "FIND THE PEARL\nSearch the foam pile"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	menu.add_child(title)
	var normal_button := Button.new()
	normal_button.text = "NORMAL — UV light and blower"
	normal_button.pressed.connect(func(): start_round("normal"))
	menu.add_child(normal_button)
	var hard_button := Button.new()
	hard_button.text = "HARD — remove each foam bead by hand"
	hard_button.pressed.connect(func(): start_round("hard"))
	menu.add_child(hard_button)
	tool_bar = HBoxContainer.new()
	tool_bar.position = Vector2(22.0, 105.0)
	tool_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(tool_bar)
	uv_button = Button.new()
	uv_button.pressed.connect(toggle_uv)
	tool_bar.add_child(uv_button)
	blower_button = Button.new()
	blower_button.pressed.connect(toggle_blower)
	tool_bar.add_child(blower_button)
	for i in PEARL_COUNT:
		var marker := Label.new()
		marker.text = "◎"
		marker.add_theme_font_size_override("font_size", 39)
		marker.add_theme_color_override("font_color", Color("d880ff"))
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(marker)
		uv_markers.append(marker)
	update_ui()


func show_menu() -> void:
	playing = false
	menu.visible = true
	tool_bar.visible = false
	overlay.text = ""
	update_ui()


func start_round(chosen_mode: String) -> void:
	for child in pile.get_children():
		pile.remove_child(child)
		child.free()
	mode = chosen_mode
	uv_on = false
	blower_on = false
	hover_text = ""
	menu.visible = false
	tool_bar.visible = mode == "normal"
	found = 0
	time_left = ROUND_SECONDS if mode == "normal" else 180.0
	playing = true
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# Pearls sit among the lower beads. Clear the foam above them to uncover them.
	for i in PEARL_COUNT:
		var angle := TAU * float(i) / float(PEARL_COUNT) + rng.randf_range(-0.25, 0.25)
		var radius := rng.randf_range(0.8, 3.25)
		add_bead(Vector3(cos(angle) * radius, rng.randf_range(0.15, 0.38), sin(angle) * radius), true, rng)
	for i in FOAM_COUNT:
		var radius := sqrt(rng.randf()) * 3.75
		var angle := rng.randf() * TAU
		var height := rng.randf_range(0.15, 0.95) + (1.0 - radius / 4.0) * rng.randf_range(0.0, 0.55)
		add_bead(Vector3(cos(angle) * radius, height, sin(angle) * radius), false, rng)
	update_ui()


func add_bead(position: Vector3, is_pearl: bool, rng: RandomNumberGenerator) -> void:
	var body := StaticBody3D.new()
	body.position = position
	body.set_meta("pearl", is_pearl)
	var radius := rng.randf_range(0.20, 0.26) if is_pearl else rng.randf_range(0.24, 0.37)
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = pearl_material if is_pearl else foam_materials[rng.randi_range(0, foam_materials.size() - 1)]
	body.add_child(visual)
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	var collider := CollisionShape3D.new()
	collider.shape = sphere
	body.add_child(collider)
	pile.add_child(body)


func _process(delta: float) -> void:
	update_uv_markers()
	if playing:
		time_left = maxf(0.0, time_left - delta)
		if time_left <= 0.0:
			playing = false
			overlay.text = "TIME UP!\nFound %d / %d pearls\nPress R to retry, M for modes" % [found, PEARL_COUNT]
		update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and not menu.visible:
			start_round(mode)
			return
		if event.keycode == KEY_M:
			show_menu()
			return
		if event.keycode == KEY_U and playing and mode == "normal":
			toggle_uv()
			return
		if event.keycode == KEY_B and playing and mode == "normal":
			toggle_blower()
			return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			orbit_distance = maxf(7.0, orbit_distance - 0.8)
			update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			orbit_distance = minf(19.0, orbit_distance + 0.8)
			update_camera()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed and playing:
			search_at(event.position)
	if event is InputEventMouseMotion and dragging:
		orbit_yaw -= event.relative.x * 0.008
		orbit_pitch = clampf(orbit_pitch + event.relative.y * 0.008, 0.3, 1.35)
		update_camera()


func update_camera() -> void:
	var target := Vector3(0.0, 0.25, 0.0)
	camera.position = target + Vector3(sin(orbit_yaw) * cos(orbit_pitch), sin(orbit_pitch), cos(orbit_yaw) * cos(orbit_pitch)) * orbit_distance
	camera.look_at(target, Vector3.UP)


func search_at(screen_position: Vector2) -> void:
	var origin := camera.project_ray_origin(screen_position)
	var end := origin + camera.project_ray_normal(screen_position) * 100.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var bead: Object = hit["collider"]
	if bead is StaticBody3D and bead.get_parent() == pile:
		if mode == "normal" and blower_on:
			blow_foam(bead.position)
			return
		if bead.get_meta("pearl"):
			found += 1
			if found >= PEARL_COUNT:
				playing = false
				overlay.text = "ALL PEARLS FOUND!\nTime left: %d seconds\nPress R to retry, M for modes" % ceili(time_left)
		else:
			hover_text = "Foam moved aside. Keep looking!"
		bead.queue_free()
		update_ui()


func blow_foam(center: Vector3) -> void:
	var removed := 0
	for bead in pile.get_children():
		if not bead.get_meta("pearl") and bead.position.distance_to(center) < 1.15:
			bead.queue_free()
			removed += 1
	hover_text = "Blower cleared %d foam beads. Pearls stay in the tray." % removed
	update_ui()


func toggle_uv() -> void:
	uv_on = not uv_on
	hover_text = "UV reveals pearl locations." if uv_on else "UV light off."
	update_ui()


func toggle_blower() -> void:
	blower_on = not blower_on
	hover_text = "Blower ready: click foam to clear an area." if blower_on else "Blower off: remove one bead per click."
	update_ui()


func update_uv_markers() -> void:
	var marker_index := 0
	for bead in pile.get_children():
		if bead.get_meta("pearl") and marker_index < uv_markers.size():
			var marker := uv_markers[marker_index]
			marker.visible = playing and mode == "normal" and uv_on and not camera.is_position_behind(bead.global_position)
			if marker.visible:
				marker.position = camera.unproject_position(bead.global_position) - Vector2(17.0, 25.0)
			marker_index += 1
	for i in range(marker_index, uv_markers.size()):
		uv_markers[i].visible = false


func update_ui() -> void:
	hud.text = "FIND THE PEARL  |  %s  |  %d / %d  |  %02d s" % [mode.to_upper(), found, PEARL_COUNT, ceili(time_left)]
	hint.text = "Click: remove foam   Right drag: rotate   Wheel: zoom   R: retry   M: modes\n%s" % hover_text
	uv_button.text = "UV LIGHT [U]: ON" if uv_on else "UV LIGHT [U]: OFF"
	blower_button.text = "BLOWER [B]: ON" if blower_on else "BLOWER [B]: OFF"
	if playing:
		overlay.text = ""
