extends Control
var game: Node3D
func _process(_delta: float) -> void:
 visible = game.playing
 if visible: queue_redraw()
func _draw() -> void:
 draw_circle(Vector2(90,90),88,Color("1c3445"))
 draw_arc(Vector2(90,90),86,0,TAU,64,Color("7798a7"),2,true)
 var bounds: Vector4 = game.level_bounds()
 var factor := 130.0 / maxf(bounds.y-bounds.x,bounds.w-bounds.z)
 var center := Vector2((bounds.x+bounds.y)/2,(bounds.z+bounds.w)/2)
 for rect in game.current_walkable_rects:
  var r := Rect2(Vector2(90,90)+(rect.position-center)*factor,rect.size*factor)
  draw_rect(r,Color("5d737b"))
  draw_rect(r,Color("d6dedb"),false,2)
 var pos := Vector2(90,90)+(Vector2(game.player.position.x,game.player.position.z)-center)*factor
 if pos.distance_to(Vector2(90,90))<80:
  draw_circle(pos,4,Color("ffe3a2"))
  var facing := Vector2(-sin(game.player.rotation.y),-cos(game.player.rotation.y))
  draw_line(pos,pos+facing*13,Color("ffe3a2"),2,true)
