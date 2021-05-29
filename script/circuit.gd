extends Line2D


export(int)var border_width := 500
export(NodePath) var node_path


func _ready():
	var node := get_node(node_path)
	if node is Path2D:
		var path_road = node
		var polygon = get_polygon_adjust(path_road)
		$limit_interior/col.polygon = build_interior(polygon)
		$limit_exterior/col.polygon = build_exterior(polygon)
		self.points = polygon


func get_polygon_adjust(path_road) -> Array:
	var polygon = path_road.get_curve().get_baked_points()
	var new_polygon = []
	for pt in polygon:
		new_polygon.append(Vector2(pt.x + path_road.position.x, pt.y + path_road.position.y))
	return new_polygon


func build_exterior(polygon) -> Array:
	var polygon_ext = build_polygon_exterior(polygon, self.width)
	
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


func add_sub_point_x_axis(col_polygon_ext, start, end, nb_point, y_axis):
	for sub_div in range(nb_point - 2):
		col_polygon_ext.append(Vector2(start.x + (sub_div + 1) * (end.x - start.x) / nb_point, y_axis))


func add_sub_point_y_axis(col_polygon_ext, start, end, nb_point, x_axis):
	for sub_div in range(nb_point - 2):
		col_polygon_ext.append(Vector2(x_axis, start.y + (sub_div + 1) * (end.y - start.y) / nb_point))


func add_square_col_to_finalize_exterior(limit, start, end):
	var square_col = CollisionPolygon2D.new()
	var new_square_ext = []
	new_square_ext.append(Vector2(end.x, limit.position.y))
	new_square_ext.append(Vector2(start.x, limit.position.y))
	new_square_ext.append(Vector2(start.x, start.y))
	new_square_ext.append(Vector2(end.x, end.y))
	square_col.polygon = new_square_ext
	$limit_exterior.add_child(square_col)


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

	var rect_position := Vector2(ceil(x_min) - border_width, ceil(y_min) - border_width)
	var rect_size := Vector2(abs(ceil(x_min) - border_width) + abs(ceil(x_max) + border_width), abs(ceil(y_min) - border_width) + abs(ceil(y_max) + border_width))
	return Rect2(rect_position, rect_size)


func build_interior(polygon) -> Array:
	var size = polygon.size()
	var build_polygon = []
	
	if size > 1:
		var vect
		for idx in range(size - 1):
			if idx % 2:
				vect = (polygon[idx + 1] - polygon[idx]).rotated(PI / 2).normalized() * (self.width / 2)
				build_polygon.append(polygon[idx] + vect)
	
	return build_polygon


func build_polygon_exterior(polygon, width) -> Array:
	var size = polygon.size()
	var build_polygon = []
	
	if size > 1:
		var vect
		for idx in range(size - 1):
			vect = (polygon[idx + 1] - polygon[idx]).rotated(PI / 2).normalized() * (width / 2) * -1
			build_polygon.append(polygon[idx] + vect)
		
		vect = (polygon[size - 1] - polygon[size - 2]).rotated(PI / 2).normalized() * (width / 2) * -1
		build_polygon.append(polygon[size - 1] + vect)
	
	return build_polygon



func _on_limit_interior_body_entered(body):
	if body.is_in_group("car"):
		body.limit_inner()


func _on_limit_interior_body_exited(body):
	if body.is_in_group("car"):
		body.limit_road()


func _on_limit_exterior_body_entered(body):
	if body.is_in_group("car"):
		body.limit_outer()


func _on_limit_exterior_body_exited(body):
	if body.is_in_group("car"):
		body.limit_road()
