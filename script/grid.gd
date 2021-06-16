tool
extends Node2D

export(Vector2) var final_line_coord = Vector2(16, 256)
export(bool)var with_redraw := false setget with_redraw_editor 

var grid_position := []

func _ready():
	$final_line/col.shape.extents = Vector2(final_line_coord.x, final_line_coord.y + final_line_coord.y / 4)
	
	$final_line/bg.width = final_line_coord.x
	$final_line/bg.points = [ Vector2(-5568, -final_line_coord.y), Vector2(-5568, final_line_coord.y) ]
	
	for place in range(1, 23):
		grid_position.append(get_node("position_" + str(place)).global_position)


func get_grid_position() -> Array:
	return grid_position


func with_redraw_editor(new_value) -> void:
	with_redraw = new_value
	if Engine.editor_hint and with_redraw:
		$refresh.start()
	else:
		$refresh.stop()


func _on_refresh_timeout():
	if with_redraw:
		_ready()
		with_redraw_editor(false)
