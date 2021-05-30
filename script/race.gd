extends Node2D


func _ready():
	$circuit.with_redraw_editor(false)
	$path_road.visible = false


func _on_Timer_timeout():
	$can/lb_car_1.text = $cars/car_1.car_name + ": " + str(int($cars/car_1.get_speed() * 3.6 * 10.0) / 10.0)  + " km/h"
	$can/lb_car_2.text = $cars/car_2.car_name + ": " + str(int($cars/car_2.get_speed() * 3.6 * 10.0) / 10.0)  + " km/h"


func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		var _err = get_tree().reload_current_scene()
	if Input.is_action_just_pressed("camera_circuit"):
		$camera.current = true
		$cars/car_1/camera.current = false
		$cars/car_2/camera.current = false
	elif Input.is_action_just_pressed("camera_car_one"):
		$camera.current = false
		$cars/car_1/camera.current = true
		$cars/car_2/camera.current = false
	elif Input.is_action_just_pressed("camera_car_two"):
		$camera.current = false
		$cars/car_1/camera.current = false
		$cars/car_2/camera.current = true
