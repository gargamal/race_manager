extends Node


onready var viewport1 = $Viewports/ViewportContainer1/Viewport
onready var viewport2 = $Viewports/ViewportContainer2/Viewport
onready var camera1 = $Viewports/ViewportContainer1/Viewport/Camera
onready var camera2 = $Viewports/ViewportContainer2/Viewport/Camera
onready var world = $Viewports/ViewportContainer2/Viewport/race

var car_1
var car_2

var ranking_tab_base := []
var ranking_line := { "car":"", "total_time":0, "lap":0, "best_lap":0, "last_lap":0 }

var lap_number = 0

func _ready():
	viewport1.world_2d = viewport2.world_2d
	$Params/Minimap/Viewport.world_2d = viewport1.world_2d
	camera1.target = world.get_node("cars/car_1")
	car_1 = camera1.target
	init_screen($Params/car_1, car_1)
	camera2.target = world.get_node("cars/car_3")
	car_2 = camera2.target
	init_screen($Params/car_2, car_2)
	init_ranking()


func init_screen(root :Panel, car :KinematicBody2D):
	root.get_node("car_name").text = car.car_name
	root.get_node("car_speed").text = "0 km /h"
	root.get_node("last_lap").text = "last :---"
	root.get_node("best_lap").text = "best :---"


func init_ranking():
	lap_number = 0
	$Viewports/panel/ranking/title.text = "Ranking (" + str(lap_number) + " / 50)"
	
	var root = $Viewports/panel/ranking
	var count = 0
	var nb_car = world.get_node("cars").get_child_count()
	
	for child in root.get_children():
		if count > 1 and count <= nb_car + 1:
			child.get_node("car_name").text = world.get_node("cars/car_" + str(count - 1)).car_name
			child.get_node("time").text = "---"
			child.get_node("gap").text = "---"
			child.get_node("best_lap").text = "---"
			child.get_node("lap").text = str(lap_number)
			var line = ranking_line.duplicate()
			line.car = world.get_node("cars/car_" + str(count - 1))
			ranking_tab_base.append(line)
			
		elif count > nb_car + 1:
			child.get_node("car_name").text = ""
			child.get_node("time").text = ""
			child.get_node("gap").text = ""
			child.get_node("best_lap").text = ""
			child.get_node("lap").text = ""
		count += 1

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


func update_ranking():
	var ranking_tab_screen = sort_ranking_tab(update_ranking_tab())
	lap_number = ranking_tab_screen[0].lap
	$Viewports/panel/ranking/title.text = "Ranking (" + str(lap_number) + " / 50)"
	
	var root = $Viewports/panel/ranking
	var count = 0
	var nb_car = world.get_node("cars").get_child_count()
	
	for child in root.get_children():
		if 1 < count and count <= nb_car + 1:
			var line = ranking_tab_screen[count - 2]
			var car = line.car
			child.get_node("car_name").text =  car.car_name
			child.get_node("time").text = format_time(line.last_lap)
			child.get_node("best_lap").text = format_time(line.best_lap)
			child.get_node("lap").text = str(line.lap)
			if 2 < count and count <= nb_car:
				var gap = ranking_tab_screen[count - 1].total_time - line.total_time
				if gap > 0:
					child.get_node("gap").text = format_time(gap)
				else:
					child.get_node("gap").text = "---"
			
		count += 1


func update_ranking_tab() -> Array:
	var ranking_tab = ranking_tab_base.duplicate()
	for line in ranking_tab:
		line.total_time = sumInt(line.car.total_time)
		line.lap = line.car.total_time.size()
		line.best_lap = line.car.best_lap
		line.last_lap = line.car.last_lap
	return ranking_tab


func sumInt(tab :Array) -> int:
	var total = 0
	for int_value in tab:
		total += int_value
	return total


func sort_ranking_tab(tab :Array) -> Array:
	var size = tab.size()
	
	for idx in range(size - 1):
		var line = tab[idx]
		var sort_idx = idx
		for jdx in range(idx + 1, size):
			if compareTo(tab[jdx], line) > 0:
				sort_idx = jdx
				line = tab[jdx]
		
		if sort_idx != idx:
			line = tab[idx]
			tab[idx] = tab[sort_idx]
			tab[sort_idx] = line
	return tab


func compareTo(line1, line2) -> int:
	return line2.total_time - line1.total_time if line1.lap == line2.lap else line1.lap - line2.lap


func _on_Timer_timeout():
	update_screen($Params/car_1, car_1)
	update_screen($Params/car_2, car_2)


func _on_refresh_ranking_timeout():
	pass
#	update_ranking()
