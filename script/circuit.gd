tool
extends Node2D


export(int)var circuit_exterior_width := 500
export(int)var road_width := 300
export(NodePath) var node_path
export(StreamTexture) var background
export(int)var modulo_to_draw_interior := 2
export(bool)var with_redraw := false setget with_redraw_editor 


func _ready():
	if background:
		$road_line/limit_exterior/bg.texture = background
		$road_line/limit_interior/bg.texture = background
	
	if node_path and get_node(node_path) is Path2D:
		var node := get_node(node_path)
		var polygon = get_polygon_adjust(node)
		if polygon.size() > 0:
			$road_line.width = road_width
			var polygon_interior =  build_interior(polygon)
			var polygon_exterior = build_exterior(polygon)
			$road_line/limit_interior/col.polygon = polygon_interior
			$road_line/limit_interior/bg.polygon = polygon_interior
			$road_line/limit_exterior/col.polygon = polygon_exterior
			$road_line/limit_exterior/bg.polygon = polygon_exterior
			$road_line.points = polygon
			for child in $buzers.get_children(): 
				$buzers.remove_child(child)
			build_buzer(polygon_interior)
			build_buzer(polygon_exterior)


func build_buzer(polygon :Array) -> void:
	var size = polygon.size()
	var polygon_buzer = Array()
	
	for idx in range(size):
		var angle
		if 0 < idx and idx < size - 2:
			angle = abs((polygon[idx]  - polygon[idx - 1]).normalized().angle_to((polygon[idx + 1] - polygon[idx]).normalized()))
		elif idx == 0:
			angle = abs((polygon[0] - polygon[size - 1]).normalized().angle_to((polygon[1] - polygon[0]).normalized()))
		else:
			angle = abs((polygon[size - 1] - polygon[size - 2]).normalized().angle_to((polygon[0] - polygon[size - 1]).normalized()))
			
		if angle > 0.02 and angle < PI / 4.0:
			polygon_buzer.append(polygon[idx])
			
		elif polygon_buzer.size() > 0:
			if polygon_buzer.size() > 5:
				var buzer_new_ref = Line2D.new()
				buzer_new_ref.width = road_width / 10.0
				buzer_new_ref.default_color = Color(1.0, 1.0, 1.0, 1.0)
				buzer_new_ref.texture = load("res://sprite/buzzer.png")
				buzer_new_ref.texture_mode = Line2D.LINE_TEXTURE_TILE
				buzer_new_ref.points = polygon_buzer
				$buzers.add_child(buzer_new_ref)
				polygon_buzer = Array()
				
			else:
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
	if background:
		square_bg.texture = background
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
			if idx % modulo_to_draw_interior == 0:
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



func _on_limit_interior_body_entered(body) -> void:
	if body.is_in_group("car"):
		body.limit_inner()


func _on_limit_interior_body_exited(body) -> void:
	if body.is_in_group("car"):
		body.limit_road()


func _on_limit_exterior_body_entered(body) -> void:
	if body.is_in_group("car"):
		body.limit_outer()


func _on_limit_exterior_body_exited(body) -> void:
	if body.is_in_group("car"):
		body.limit_road()


func _on_refresh_timeout():
	if with_redraw and node_path and get_node(node_path) is Path2D:
		_ready()
		with_redraw_editor(false)
