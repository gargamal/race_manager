extends Node2D

var grid_position := []

func _ready():
	for place in range(1, 23):
		grid_position.append(get_node("position_" + str(place)).global_position)


func get_grid_position() -> Array:
	return grid_position
