extends Node2D


var cars = []


func _ready():
	$circuit.with_redraw_editor(false)
	$path_road.visible = false
	for place in range(1, 21):
		cars.append(get_node("cars/car_" + str(place)))
	spawn_cars()


func spawn_cars():
	var position_spawn = $grid.get_grid_position()
	for idx in range(cars.size()):
		cars[idx].global_position = position_spawn[idx]

