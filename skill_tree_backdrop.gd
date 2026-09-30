extends Control

var game: Node
var branch_x := [110.0, 330.0, 550.0, 770.0, 990.0]
var node_y := [400.0, 295.0, 190.0]
var colors := [Color("35e68a"), Color("35bce6"), Color("f4c430"), Color("e865ce"), Color("ff5b5b")]

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# A clean shared trunk keeps all branch connections away from text.
	var root := Vector2(550, 500)
	draw_circle(root, 25, Color("16242e"))
	draw_arc(root, 25, 0, TAU, 40, Color("dbc77d"), 4, true)
	draw_line(root, Vector2(550, 455), Color("dbc77d"), 6, true)
	draw_line(Vector2(branch_x[0], 455), Vector2(branch_x[4], 455), Color("42505d"), 5, true)
	for branch in 5:
		var level: int = game.get_skill_level(branch) if game != null else 0
		var first := Vector2(branch_x[branch], node_y[0])
		draw_line(Vector2(branch_x[branch], 455), first, colors[branch] if level > 0 else Color("42505d"), 7 if level > 0 else 4, true)
		for tier in 2:
			var from := Vector2(branch_x[branch], node_y[tier])
			var to := Vector2(branch_x[branch], node_y[tier + 1])
			draw_line(from, to, colors[branch] if level > tier + 1 else Color("42505d"), 7 if level > tier + 1 else 4, true)
	# Small center emblem.
	draw_line(Vector2(540, 500), Vector2(548, 508), Color("dbc77d"), 4, true)
	draw_line(Vector2(548, 508), Vector2(562, 489), Color("dbc77d"), 4, true)
