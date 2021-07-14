extends Node2D


var minimal_car = preload("res://scene/minimal_car.tscn")
var minimal_cars = []
var cars = []


func _process(_delta):
	for idx in range(cars.size()):
		minimal_cars[idx].position = cars[idx].position


func start(world):
	add_child(world.get_node("environnement").duplicate())
	add_child(world.get_node("path_road").duplicate())
	var circuit_node = Node2D.new()
	circuit_node.name = "circuit"
	add_child(circuit_node)
	circuit_node.add_child(world.get_node("circuit/road_line").duplicate())
	add_child(world.get_node("pitlane").duplicate())
	add_child(world.get_node("grid").duplicate())
	add_child(world.get_node("brake_trace").duplicate())
	add_child(world.get_node("circuit/buzers").duplicate())


	var minimal_cars_node = Node2D.new()
	minimal_cars_node.name = "cars"
	add_child(minimal_cars_node)
	var cars_node = world.get_node("cars").get_children()

	for car_node in cars_node:
		cars.append(car_node)
		var inst_car = minimal_car.instance()
		inst_car.name = car_node.name
		inst_car.get_node("car").modulate = car_node.team_color
		inst_car.get_node("number").modulate = car_node.text_color
		inst_car.get_node("number").text = car_node.number_car
		if not car_node.human_player:
			inst_car.get_node("car").modulate.a = 0.35
			inst_car.get_node("number").modulate.a = 0.35
		minimal_cars_node.add_child(inst_car)
		minimal_cars.append(inst_car)
