extends Node2D


enum WEATHER { SUN, SUN_CLOUD, CLOUD, LIGHT_RAIN, RAIN }
enum ROAD_CONDITION { DRY, SLIGHTLY_WET, WET, VERY_WET, TOTALY_WET }


var proba_sun = 0
var proba_sun_cloud = 0
var proba_cloud = 0
var proba_light_rain = 0
var proba_heavy_rain = 0
var weather = WEATHER.RAIN
var previous_weather = weather
var road_condition = ROAD_CONDITION.WET
var cars = []


func _ready():
	randomize()
	var total_weather_proba = $circuit.weather_proba_sun + $circuit.weather_proba_sun_cloud + $circuit.weather_proba_cloud + $circuit.weather_proba_light_rain + $circuit.weather_proba_heavy_rain
	proba_sun = int(float($circuit.weather_proba_sun) / float(total_weather_proba) * 100.0 + 0.5)
	proba_sun_cloud = int(float($circuit.weather_proba_sun_cloud) / float(total_weather_proba) * 100.0 + 0.5)
	proba_cloud = int(float($circuit.weather_proba_cloud) / float(total_weather_proba) * 100.0 + 0.5)
	proba_light_rain = int(float($circuit.weather_proba_light_rain) / float(total_weather_proba) * 100.0 + 0.5)
	proba_heavy_rain = int(float($circuit.weather_proba_heavy_rain) / float(total_weather_proba) * 100.0 + 0.5)
	
	_on_weather_timeout()
	previous_weather = weather
	$circuit.with_redraw_editor(false)
	$path_road.visible = false
	cars = []
	for place in range(1, 21):
		cars.append(get_node("cars/car_" + str(place)))
	spawn_cars()


func spawn_cars():
	var position_spawn = $grid.get_grid_position()
	for idx in range(cars.size()):
		cars[idx].global_position = position_spawn[idx]


func change_colorate_sky(new_modulate):
	if modulate != new_modulate:
		$tw_weather.interpolate_property(self, "modulate", modulate, new_modulate, 10.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$tw_weather.start()


func colorate_sky():
	if weather == WEATHER.SUN:
		change_colorate_sky(Color(1.0, 1.0, 1.0, 1.0))
	
	elif weather == WEATHER.SUN_CLOUD: 
		change_colorate_sky(Color(0.9, 0.9, 0.9, 1.0))
	
	elif weather == WEATHER.CLOUD: 
		change_colorate_sky(Color(0.8, 0.8, 0.8, 1.0))
	
	elif weather == WEATHER.LIGHT_RAIN and previous_weather in [WEATHER.SUN, WEATHER.SUN_CLOUD, WEATHER.CLOUD]:
		change_colorate_sky(Color(0.75, 0.75, 0.75, 1.0))
	
	elif weather == WEATHER.LIGHT_RAIN and previous_weather in [WEATHER.LIGHT_RAIN, WEATHER.RAIN]:
		change_colorate_sky(Color(0.7, 0.7, 0.7, 1.0))
	
	elif weather == WEATHER.RAIN and previous_weather == WEATHER.LIGHT_RAIN:
		change_colorate_sky(Color(0.65, 0.65, 0.65, 1.0))
	
	elif weather == WEATHER.RAIN and previous_weather == WEATHER.RAIN:
		change_colorate_sky(Color(0.6, 0.6, 0.6, 1.0))


func estimate_weather():
	var proba_new_weather = randi() % 100 + 1
	var new_weather = WEATHER.SUN
	
	if proba_new_weather <= proba_sun: new_weather = WEATHER.SUN
	elif proba_new_weather <= proba_sun + proba_sun_cloud: new_weather = WEATHER.SUN_CLOUD
	elif proba_new_weather <= proba_sun + proba_sun_cloud + proba_cloud: new_weather = WEATHER.CLOUD
	elif proba_new_weather <= proba_sun + proba_sun_cloud + proba_cloud + proba_light_rain: new_weather = WEATHER.LIGHT_RAIN
	elif proba_new_weather <= proba_sun + proba_sun_cloud + proba_cloud + proba_light_rain + proba_heavy_rain: new_weather = WEATHER.RAIN
	
	previous_weather = weather
	if new_weather > weather: weather += 1
	elif new_weather < weather: weather -= 1


func estimate_road_condition():
	if previous_weather in [WEATHER.SUN, WEATHER.SUN_CLOUD, WEATHER.CLOUD] and weather in [WEATHER.SUN, WEATHER.SUN_CLOUD, WEATHER.CLOUD]:
		road_condition = ROAD_CONDITION.DRY
	elif previous_weather == WEATHER.LIGHT_RAIN and weather in [WEATHER.SUN, WEATHER.SUN_CLOUD, WEATHER.CLOUD]:
		road_condition = ROAD_CONDITION.SLIGHTLY_WET
	elif previous_weather in [WEATHER.SUN, WEATHER.SUN_CLOUD, WEATHER.CLOUD] and weather == WEATHER.LIGHT_RAIN:
		road_condition = ROAD_CONDITION.SLIGHTLY_WET
	elif previous_weather == WEATHER.LIGHT_RAIN and weather == WEATHER.LIGHT_RAIN:
		road_condition = ROAD_CONDITION.WET
	elif previous_weather == WEATHER.LIGHT_RAIN and weather == WEATHER.RAIN:
		road_condition = ROAD_CONDITION.VERY_WET
	elif previous_weather == WEATHER.RAIN and weather == WEATHER.LIGHT_RAIN:
		road_condition = ROAD_CONDITION.VERY_WET
	elif previous_weather == WEATHER.RAIN and weather == WEATHER.RAIN:
		road_condition = ROAD_CONDITION.TOTALY_WET
	else:
		road_condition = ROAD_CONDITION.DRY
		
	$pitlane/rain.emitting = road_condition != ROAD_CONDITION.DRY


func _on_weather_timeout():
	estimate_weather()
	estimate_road_condition()
	colorate_sky()
	$circuit.rain_effect_apply(weather)
	get_tree().current_scene.update_weather(weather)

