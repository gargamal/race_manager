extends Node


onready var viewport1 = $Viewports/ViewportContainer1/Viewport
onready var viewport2 = $Viewports/ViewportContainer2/Viewport
onready var camera1 = $Viewports/ViewportContainer1/Viewport/Camera
onready var camera2 = $Viewports/ViewportContainer2/Viewport/Camera
onready var world = $Viewports/ViewportContainer2/Viewport/race

var car_1
var car_2

func _ready():
	viewport1.world_2d = viewport2.world_2d
	$Params/Minimap/Viewport.world_2d = viewport1.world_2d
	camera1.target = world.get_node("cars/car_1")
	car_1 = camera1.target
	init_screen($Params/car_1, car_1)
	camera2.target = world.get_node("cars/car_3")
	car_2 = camera2.target
	init_screen($Params/car_2, car_2)


func init_screen(root :Panel, car :KinematicBody2D):
	root.get_node("car_name").text = car.car_name
	root.get_node("car_speed").text = "0 km /h"
	root.get_node("last_lap").text = "last :---"
	root.get_node("best_lap").text = "best :---"


func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		var _err = get_tree().reload_current_scene()


func update_screen(root :Panel, car :KinematicBody2D):
	var speed = car.get_speed() * 3.6
	root.get_node("car_speed").text = str(int(speed + 0.5)) + " km /h"
	root.get_node("last_lap").text = "last :" + ("---" if car.last_lap < 1 else format_time(car.last_lap))
	root.get_node("best_lap").text = "best :" + ("---" if car.last_lap < 1 else format_time(car.best_lap))


func format_time(time :int) -> String:
	var millis = time % 1000
	var seconds = int(time / 1000) % 60
	var minutes = int(time / 1000 / 60) % 60

	return "%02d : %02d : %03d" % [minutes, seconds, millis]

func _on_Timer_timeout():
	update_screen($Params/car_1, car_1)
	update_screen($Params/car_2, car_2)
