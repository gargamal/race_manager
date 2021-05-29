extends Node2D


func _on_Timer_timeout():
	$can/lb_car_1.text = $car_1.car_name + ": " + str(int($car_1.get_speed() * 3.6 * 10.0) / 10.0)  + " km/h"
	$can/lb_car_2.text = $car_2.car_name + ": " + str(int($car_2.get_speed() * 3.6 * 10.0) / 10.0)  + " km/h"


func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		var _err = get_tree().reload_current_scene()
