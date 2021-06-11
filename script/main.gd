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
	camera2.target = world.get_node("cars/car_19")
	car_2 = camera2.target
	$Params/car_1/car_name.text = car_1.car_name
	$Params/car_1/car_speed.text = "0 km /h"
	$Params/car_2/car_name.text = car_2.car_name
	$Params/car_2/car_speed.text = "0 km /h"


func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		var _err = get_tree().reload_current_scene()


func _on_Timer_timeout():
	var speed = car_1.get_speed() * 3.6
	$Params/car_1/car_speed.text = str(int(speed + 0.5)) + " km /h"
	speed = car_2.get_speed() * 3.6
	$Params/car_2/car_speed.text = str(int(speed + 0.5)) + " km /h"
