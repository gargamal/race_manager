tool
extends Node2D


const TYPE_LAYER = { "STRAIGHT_LINE": 64, "SLOW_TURN": 128, "CAR": 8 }
enum WEATHER { SUN, SUN_CLOUD, CLOUD, LIGHT_RAIN, RAIN }
enum OUT_CIRCUIT { IN_CIRCUIT, EXTERIOR, INTERIOR }
enum IN_CIRCUIT { NONE, LINE, TURN }


export(int)var nb_lap := 100
export(int)var circuit_exterior_width := 500
export(int)var road_width := 300
export(NodePath) var node_path
export(bool)var with_redraw := false setget with_redraw_editor 
export(int)var weather_proba_sun = 1
export(int)var weather_proba_sun_cloud = 1
export(int)var weather_proba_cloud = 1
export(int)var weather_proba_light_rain = 1
export(int)var weather_proba_heavy_rain = 1


var previous_weather = WEATHER.CLOUD


func _ready():
	if node_path and get_node(node_path) is Path2D:
		var node := get_node(node_path)
		var polygon = get_polygon_adjust(node)
		if polygon.size() > 0:
			$road_line.width = road_width
			var polygon_interior =  build_interior(polygon)
			var polygon_exterior_raw = build_polygon_exterior(polygon)
			var polygon_exterior_circuit = build_exterior(polygon)
			$road_line/limit_interior/col.polygon = polygon_interior
			$road_line/limit_exterior/col.polygon = polygon_exterior_circuit
			$road_line.points = polygon
			for child in $buzers.get_children(): 
				$buzers.remove_child(child)
			for child in $slow_turns.get_children(): 
				$slow_turns.remove_child(child)
			for child in $straigth_lines.get_children(): 
				$straigth_lines.remove_child(child)
			build_buzer(polygon_interior)
			build_buzer(polygon_exterior_raw)
			build_road_type($slow_turns, polygon_interior, polygon_exterior_raw, 0.02, 2.0, TYPE_LAYER["SLOW_TURN"])
			build_road_type($straigth_lines, polygon_interior, polygon_exterior_raw, 0.0, 0.02, TYPE_LAYER["STRAIGHT_LINE"])


func build_road_type(root :Node2D, polygon_interior :Array, polygon_exterior :Array, angle_min :float, angle_max :float, collision_layer :int) -> void:
	var points_exterior = Array()
	var points_interior = Array()
	
	var size_exterior = polygon_exterior.size()
	var size_interior = polygon_interior.size()
	
	add_point(size_interior, 0, points_exterior, points_interior, polygon_exterior, polygon_interior)
	
	for idx in range(size_exterior):
		var angle_exterior = get_angle(polygon_exterior, idx, size_exterior)
		var angle_interior = get_angle(polygon_interior, idx, size_interior)
		var angle = angle_interior if angle_interior > angle_exterior else angle_exterior
		
		if angle_min <= angle and angle < angle_max:
			add_point(size_interior, idx, points_exterior, points_interior, polygon_exterior, polygon_interior)
			
		elif points_exterior.size() > 0:
			if points_interior.size() > 1: # filter too small limit 
				var points_merged = Array()
				points_merged.append_array(points_exterior)
				for idx_inter in range(points_interior.size() - 1, -1, -1):
					points_merged.append(points_interior[idx_inter])
				
				var area_road_type = Area2D.new()
				area_road_type.add_to_group("turn" if collision_layer == TYPE_LAYER["SLOW_TURN"] else "line")
				area_road_type.collision_layer = collision_layer
				area_road_type.collision_mask = TYPE_LAYER["CAR"]
				area_road_type.connect("body_entered", self, "_on_slow_turn_body_entered" if collision_layer == TYPE_LAYER["SLOW_TURN"] else "_on_line_straight_body_entered")

				var col_road_type = CollisionPolygon2D.new()
				col_road_type.polygon = points_merged
				
				area_road_type.add_child(col_road_type)
				root.add_child(area_road_type)
			
			points_exterior = Array()
			points_interior = Array()
			add_point(size_interior, idx, points_exterior, points_interior, polygon_exterior, polygon_interior)


func add_point(size_interior :int, idx :int, points_exterior :Array, points_interior :Array, polygon_exterior :Array, polygon_interior :Array) -> void:
	points_exterior.append(polygon_exterior[idx])
	if points_exterior.size() > points_interior.size():
		points_interior.append(polygon_interior[idx if idx < size_interior else 0])


func get_angle(polygon :Array, idx :int, size :int) -> float:
	var angle
	if 0 < idx and idx < size - 2:
		angle = abs((polygon[idx]  - polygon[idx - 1]).normalized().angle_to((polygon[idx + 1] - polygon[idx]).normalized()))
	elif idx == 0:
		angle = abs((polygon[0] - polygon[size - 1]).normalized().angle_to((polygon[1] - polygon[0]).normalized()))
	else:
		angle = abs((polygon[size - 1] - polygon[size - 2]).normalized().angle_to((polygon[0] - polygon[size - 1]).normalized()))
		
	return angle


func build_buzer(polygon :Array) -> void:
	var size = polygon.size()
	var polygon_buzer = Array()
	
	for idx in range(size):
		var angle = get_angle(polygon, idx, size)
		if angle > 0.02 and angle < PI / 4.0:
			polygon_buzer.append(polygon[idx])
			
		elif polygon_buzer.size() > 0:
			if polygon_buzer.size() > 1: # filter too small limit 
				var buzer_new_ref = Line2D.new()
				buzer_new_ref.width = road_width / 10.0
				buzer_new_ref.default_color = Color(1.0, 1.0, 1.0, 1.0)
				buzer_new_ref.texture = load("res://sprite/buzzer.png")
				buzer_new_ref.texture_mode = Line2D.LINE_TEXTURE_TILE
				buzer_new_ref.points = polygon_buzer
				$buzers.add_child(buzer_new_ref)
			
			polygon_buzer = Array()


func is_the_same_polygon(polygon : Array) -> bool:
	if polygon.size() != $road_line.points.size():
		return false
		
	for idx in range(polygon.size()):
		if polygon[idx] != $road_line.points[idx]:
			return false
			
	return true

func get_polygon_adjust(path_road) -> Array:
	var polygon = path_road.get_curve().get_baked_points()
	var new_polygon = []
	for pt in polygon:
		new_polygon.append(Vector2(pt.x + path_road.position.x, pt.y + path_road.position.y))
	return new_polygon


func with_redraw_editor(new_value) -> void:
	with_redraw = new_value
	if Engine.editor_hint and with_redraw:
		$refresh.start()
	else:
		$refresh.stop()


func get_nearest_point(target :Vector2) -> Vector2:
	var distance_squared = target.distance_squared_to($road_line.points[0])
	var nearest_point = $road_line.points[0]
	var next_point = $road_line.points[1]
	var idx = 0
	
	for point in $road_line.points:
		if target.distance_squared_to(point) < distance_squared:
			nearest_point = point
			next_point = $road_line.points[idx + 1 if idx + 1 < $road_line.points.size() - 1 else 0]
		idx += 1
	
	return (next_point - nearest_point).normalized()


func build_exterior(polygon) -> Array:
	var polygon_ext = build_polygon_exterior(polygon)
	
	var col_polygon_ext = polygon_ext
	var limit := get_limit(polygon_ext)
	var start = polygon_ext[0]
	var end = polygon_ext[polygon_ext.size() - 2]
	
	col_polygon_ext[polygon_ext.size() - 1] = Vector2(end.x, limit.position.y)
	add_sub_point_x_axis(col_polygon_ext, end, limit.position, 10, limit.position.y)
	col_polygon_ext.append(Vector2(limit.position.x, limit.position.y))
	add_sub_point_y_axis(col_polygon_ext, limit.position, limit.end, 20, limit.position.x)
	col_polygon_ext.append(Vector2(limit.position.x, limit.end.y))
	add_sub_point_x_axis(col_polygon_ext, limit.position, limit.end, 20, limit.end.y)
	col_polygon_ext.append(Vector2(limit.end.x, limit.end.y))
	add_sub_point_y_axis(col_polygon_ext, limit.end, limit.position, 20, limit.end.x)
	col_polygon_ext.append(Vector2(limit.end.x, limit.position.y))
	add_sub_point_x_axis(col_polygon_ext, limit.end, start, 10, limit.position.y)
	col_polygon_ext.append(Vector2(start.x, limit.position.y))
	
	add_square_col_to_finalize_exterior(limit, start, end)
	
	return col_polygon_ext


func add_sub_point_x_axis(col_polygon_ext, start, end, nb_point, y_axis) -> void:
	for sub_div in range(nb_point - 2):
		col_polygon_ext.append(Vector2(start.x + (sub_div + 1) * (end.x - start.x) / nb_point, y_axis))


func add_sub_point_y_axis(col_polygon_ext, start, end, nb_point, x_axis) -> void:
	for sub_div in range(nb_point - 2):
		col_polygon_ext.append(Vector2(x_axis, start.y + (sub_div + 1) * (end.y - start.y) / nb_point))


func add_square_col_to_finalize_exterior(limit, start, end) -> void:
	var square_col = CollisionPolygon2D.new()
	var new_square_ext = []
	new_square_ext.append(Vector2(end.x, limit.position.y))
	new_square_ext.append(Vector2(start.x, limit.position.y))
	new_square_ext.append(Vector2(start.x, start.y))
	new_square_ext.append(Vector2(end.x, end.y))
	square_col.polygon = new_square_ext
	$road_line/limit_exterior.add_child(square_col)
	
	var square_bg = Polygon2D.new()
	square_bg.polygon = new_square_ext
	$road_line/limit_exterior.add_child(square_bg)


func get_limit(polygon_ext) -> Rect2:
	var x_min = 100000
	var y_min = 100000
	var x_max = 0
	var y_max = 0
	
	for point in polygon_ext:
		if point.x < x_min: x_min = point.x
		if point.x > x_max: x_max = point.x
		if point.y < y_min: y_min = point.y
		if point.y > y_max: y_max = point.y

	var rect_position := Vector2(ceil(x_min) - circuit_exterior_width, ceil(y_min) - circuit_exterior_width)
	var rect_size := Vector2(abs(ceil(x_min) - circuit_exterior_width) + abs(ceil(x_max) + circuit_exterior_width),
							abs(ceil(y_min) - circuit_exterior_width) + abs(ceil(y_max) + circuit_exterior_width))
	return Rect2(rect_position, rect_size)


func build_interior(polygon) -> Array:
	var size = polygon.size()
	var build_polygon = []
	
	if size > 1:
		var vect
		for idx in range(size - 1):
			vect = (polygon[idx + 1] - polygon[idx]).rotated(PI / 2).normalized() * ($road_line.width / 2)
			build_polygon.append(polygon[idx] + vect)
	
	return build_polygon


func build_polygon_exterior(polygon) -> Array:
	var size = polygon.size()
	var build_polygon = []
	
	if size > 1:
		var vect
		for idx in range(size - 1):
			vect = (polygon[idx + 1] - polygon[idx]).rotated(PI / 2).normalized() * ($road_line.width / 2) * -1
			build_polygon.append(polygon[idx] + vect)
		
		vect = (polygon[size - 1] - polygon[size - 2]).rotated(PI / 2).normalized() * ($road_line.width / 2) * -1
		build_polygon.append(polygon[size - 1] + vect)
	
	return build_polygon


func _on_refresh_timeout():
	if with_redraw and node_path and get_node(node_path) is Path2D:
		_ready()
		with_redraw_editor(false)

func rain_effect_apply(weather):
	if previous_weather == weather:
		return
	
	previous_weather = weather
	if weather == WEATHER.LIGHT_RAIN:
		$ligthly_rain.emitting = true
		$rain.emitting = false
		change_colorate_road(Color(0.85, 0.85, 0.85, 1.0))
		
	elif weather == WEATHER.RAIN:
		$ligthly_rain.emitting = true
		$rain.emitting = true
		change_colorate_road(Color(0.7, 0.7, 0.7, 1.0))
		
	else:
		$ligthly_rain.emitting = false
		$rain.emitting = false
		change_colorate_road(Color(1.0, 1.0, 1.0, 1.0))


func change_colorate_road(new_modulate):
	if $road_line.modulate != new_modulate:
		$tw_weather.interpolate_property($road_line, "modulate", modulate, new_modulate, 10.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$tw_weather.start()


func _on_limit_interior_body_entered(car):
	car.out_circuit = OUT_CIRCUIT.INTERIOR

func _on_limit_interior_body_exited(car):
	car.out_circuit = OUT_CIRCUIT.IN_CIRCUIT

func _on_limit_exterior_body_entered(car):
	car.out_circuit = OUT_CIRCUIT.EXTERIOR

func _on_limit_exterior_body_exited(car):
	car.out_circuit = OUT_CIRCUIT.IN_CIRCUIT

func _on_line_straight_body_entered(car):
	car.in_circuit = IN_CIRCUIT.LINE

func _on_slow_turn_body_entered(car):
	car.in_circuit = IN_CIRCUIT.TURN
