extends KinematicBody2D

enum CAR_COLOR {RED, GOLD, SKY, SAND, GREEN, PURPLE, ORANGE, BROWN, BLUE, PINK, GRASS, CYAN, DARK_RED, WATER, WINE, DARK}
enum TEAM { TEAM_1, TEAM_2, TEAM_3, TEAM_4, TEAM_5, TEAM_6, TEAM_7, TEAM_8, TEAM_9, TEAM_10, TEAM_11 }
enum STATE_IN_PITLANE {ENTER, ENTER_GARAGE, GARAGE, EXIT_GARAGE, EXIT, RETURN_ROAD }

export(String) var car_name := "voiture"
export(CAR_COLOR) var car_color
export(TEAM) var team_position
export(float) var limit_speed := 100.0 # to m/s
export(float) var coef_accelerate := 0.5
export(float) var direction_angle_degree := 10.0
export(Color) var modulate_color = Color(1.0, 1.0, 1.0, 1.0)
export(Color) var mini_map_color = Color(1.0, 1.0, 1.0, 1.0)
export(Color) var text_color = Color(1.0, 1.0, 1.0, 1.0)
export(String) var number_car = "99"
export(Color) var helmet_color = Color(1.0, 1.0, 1.0, 1.0)
export(bool) var has_pit_stop = false


const SCALE = 20
const COEF_BRAKE = 1.05
const CAR_HEIGHT = 500
const CAR_WIDTH = 150
const LIMIT_CIRCUIT_WIDTH = 120
const LIMIT_BEFORE_ZERO_VELOCITY = 0.01
const MIN_SPEED = 5.0
const MIN_SPEED_ANGULAR = 4.0
const SPEED_MAX_TURN = 40
const MEDIAN_SPEED_ANGULAR = 90.0
const MEDIAN_ANGLE_ANGULAR = PI * 10.0 / 360.0
const GRAVAR_COEF_BRAKE = 1.1
const GRAVAR_SPEED = 20.0
const GRAVAR_ANGLE = PI * 3.0 / 360.0
const PITLANE_COEF_BRAKE = 1.1
const PITLANE_SPEED = 35.0
const pitlane_ANGLE = PI * 8.0 / 360.0
enum DIRECTION { TURN_LEFT, TURN_RIGHT, TURN_AND_BRAKE_LEFT, TURN_AND_BRAKE_RIGHT, DONT_TURN, BRAKE }
enum ROAD_TYPE { INNER, OUTER, ROAD, PITLANE }


var sys_time := 0.0
var velocity := Vector2.ZERO
var direction_angle := 0.0
var gravar_sys_time := 0.0
var road_type = ROAD_TYPE.ROAD
var gravar_nb_turn := 0
var max_speed := 0.0
var time_max_speed := 0.0
var current_direction := 0
var is_in_pitlane_area = false
var state_in_pitlane = STATE_IN_PITLANE.ENTER
var mechanic_working = false
var circuit_width = 0.0

func _ready():
	circuit_width = get_parent().get_parent().get_node("circuit/road_line").width
	
	modulate = modulate_color
	$number.text = number_car
	$number.modulate = text_color
	$helmet.modulate = helmet_color
	$car_design.frame = car_color
	direction_angle = (direction_angle_degree / 360.0) * PI
	gravar_sys_time = calculate_time(GRAVAR_SPEED * SCALE)
	max_speed = limit_speed
	
	$detect_crash.enabled = true
	$detect_limit_left.enabled = true
	$detect_limit_rigth.enabled = true
	update_ray_cast()
	
	var circuit_height_ray_cast = circuit_width * 4.0
	$detect_turn_left.cast_to = Vector2(circuit_height_ray_cast * cos(PI / 4.0), -circuit_height_ray_cast * sin(PI / 4.0))
	$detect_turn_left.enabled = true
	$detect_turn_rigth.cast_to = Vector2(circuit_height_ray_cast * cos(PI / 4.0), circuit_height_ray_cast * sin(PI / 4.0))
	$detect_turn_rigth.enabled = true
	
	time_max_speed = calculate_time(limit_speed / 2.0) * 5.0


func _physics_process(delta):
	if mechanic_working:
		return
	
	go_pitlane()
	var direction = direction()
	
	if ROAD_TYPE.ROAD == road_type:
		if direction == DIRECTION.BRAKE:
			if velocity.length() / SCALE < MIN_SPEED:
				accelerate(delta)
			else:
				brake()
			
		elif direction == DIRECTION.TURN_LEFT or direction == DIRECTION.TURN_RIGHT:
			accelerate(delta)
			turn(direction, direction_angle)
			
		elif direction == DIRECTION.TURN_AND_BRAKE_LEFT or direction == DIRECTION.TURN_AND_BRAKE_RIGHT:
			if velocity.length() / SCALE < MIN_SPEED:
				accelerate(delta)
				turn(direction, direction_angle)
			else:
				turn_and_brake(direction)
			
		else:
			accelerate(delta)
	
	elif road_type in [ROAD_TYPE.INNER, ROAD_TYPE.OUTER]:
		if (velocity.length() / SCALE) / GRAVAR_COEF_BRAKE > GRAVAR_SPEED: 
			velocity /= GRAVAR_COEF_BRAKE
		
		if get_speed() < GRAVAR_SPEED:
			velocity *= GRAVAR_COEF_BRAKE
		
		if direction == DIRECTION.TURN_LEFT or direction == DIRECTION.TURN_RIGHT:
			turn_in_gravar(direction)
			
	elif road_type == ROAD_TYPE.PITLANE:
		if is_in_pitlane_area:
			var angle = get_angle_in_pitlane()
			velocity = Vector2(1, 0).rotated(angle) * PITLANE_SPEED * SCALE
		
		else :
			if (velocity.length() / SCALE) / PITLANE_COEF_BRAKE > PITLANE_SPEED: 
				velocity /= PITLANE_COEF_BRAKE

			if direction == DIRECTION.TURN_LEFT or direction == DIRECTION.TURN_RIGHT:
				turn_in_pitlane(direction)
		
		
	if velocity.length() / SCALE > max_speed:
		velocity = velocity.normalized() * max_speed
	
	
	var collision = move_and_collide(velocity * delta)
	if collision  and collision.collider is KinematicBody2D and collision.collider.is_in_group("car"):
		var angle = collision.normal.angle()
		var bounce = velocity.bounce(collision.normal).normalized().angle()
		if 0.0 < angle and angle < PI / 4.0 or -3.0 * PI / 4.0 < angle and angle < 0.0:
			turn(DIRECTION.TURN_LEFT, bounce / 20.0)
		elif 0.0 > angle and angle > -PI / 4.0 or 3.0 * PI / 4.0 > angle and angle > 0.0:
			turn(DIRECTION.TURN_RIGHT, bounce / 20.0)
		else:
			brake()
	
	var speed_measured = velocity.length() / SCALE
	play_effect(speed_measured)
	update_ray_cast()
	sys_time = calculate_time(speed_measured)
	self.rotation = velocity.angle()


############################################
############################################


func update_ray_cast():
	var coef_size_ray_cast = (get_speed() / MEDIAN_SPEED_ANGULAR) * 2.0
	
	var size_car_ray_cast = Vector2(CAR_HEIGHT * coef_size_ray_cast / 2.0, 0.0)
	$detect_crash.cast_to = size_car_ray_cast
	
	var size_limit_ray_cast = Vector2(circuit_width * 4.0 * coef_size_ray_cast, 0.0)
	$detect_limit_left.cast_to = size_limit_ray_cast
	$detect_limit_rigth.cast_to = size_limit_ray_cast


func play_effect(speed_measured :float) -> void:
	$vortex.modulate = Color(1.0, 1.0, 1.0, min(1.0, pow(speed_measured / 200.0, 4.0)))
	
	var effect_wheel = min(0.2, pow(speed_measured / 200.0, 3.0))
	$wheel_effect_bl.modulate = Color(1.0, 1.0, 1.0, effect_wheel)
	$wheel_effect_br.modulate = Color(1.0, 1.0, 1.0, effect_wheel)
	$wheel_effect_fl.modulate = Color(1.0, 1.0, 1.0, effect_wheel)
	$wheel_effect_fr.modulate = Color(1.0, 1.0, 1.0, effect_wheel)
	
	var emitting_gravar_effect = road_type in [ROAD_TYPE.OUTER, ROAD_TYPE.INNER]
	$gravar_effect_bl.emitting = emitting_gravar_effect
	$gravar_effect_br.emitting = emitting_gravar_effect
	$gravar_effect_fl.emitting = emitting_gravar_effect
	$gravar_effect_fr.emitting = emitting_gravar_effect


func get_angle_in_pitlane() -> float:
	var enter_dir_car = (get_tree().current_scene.get_node("pitlane/enter").global_position - self.global_position)
	var enter_garage_dir_car = (get_tree().current_scene.get_node("pitlane/teams/team_" + str(team_position + 1) + "_in").global_position - self.global_position)
	var garage_dir_car = (get_tree().current_scene.get_node("pitlane/teams/team_" + str(team_position + 1)).global_position - self.global_position)
	var exit_garage_dir_car = (get_tree().current_scene.get_node("pitlane/teams/team_" + str(team_position + 1) + "_out").global_position - self.global_position)
	var exit_dir_car = (get_tree().current_scene.get_node("pitlane/exit").global_position - self.global_position)
	var return_dir_car = (get_tree().current_scene.get_node("pitlane/return_in_road").global_position - self.global_position)
	
	match state_in_pitlane:
		STATE_IN_PITLANE.ENTER:
			if enter_dir_car.length() < CAR_HEIGHT / 8.0:
				state_in_pitlane = STATE_IN_PITLANE.ENTER_GARAGE
			return Vector2(1, 0).angle_to(enter_dir_car.normalized())
			
		STATE_IN_PITLANE.ENTER_GARAGE:
			if enter_garage_dir_car.length() < CAR_HEIGHT / 8.0:
				state_in_pitlane = STATE_IN_PITLANE.GARAGE
			return Vector2(1, 0).angle_to(enter_garage_dir_car.normalized())
			
		STATE_IN_PITLANE.GARAGE:
			if garage_dir_car.length() < CAR_HEIGHT / 8.0:
				mechanic_working = true
				$pitstop_time.wait_time = 5.0
				$pitstop_time.start()
				state_in_pitlane = STATE_IN_PITLANE.EXIT_GARAGE
				var angle = Vector2(1, 0).angle_to((exit_dir_car - enter_dir_car).normalized())
				self.rotation = angle
				return angle
				
			else:
				return Vector2(1, 0).angle_to(garage_dir_car.normalized())
			
		STATE_IN_PITLANE.EXIT_GARAGE:
			if exit_garage_dir_car.length() < CAR_HEIGHT / 8.0:
				state_in_pitlane = STATE_IN_PITLANE.EXIT
			return Vector2(1, 0).angle_to(exit_garage_dir_car.normalized())
			
		STATE_IN_PITLANE.EXIT:
			if exit_dir_car.length() < CAR_HEIGHT / 8.0:
				state_in_pitlane = STATE_IN_PITLANE.RETURN_ROAD
			return Vector2(1, 0).angle_to(exit_dir_car.normalized())
			
		STATE_IN_PITLANE.RETURN_ROAD:
			return Vector2(1, 0).angle_to(return_dir_car.normalized())
			
		_:
			return 0.0


func limit_inner():
	if road_type != ROAD_TYPE.PITLANE:
		road_type = ROAD_TYPE.INNER
		enable_disable_raycast(false)
		gravar_nb_turn = 0


func limit_road():
	if road_type != ROAD_TYPE.PITLANE:
		road_type = ROAD_TYPE.ROAD
		enable_disable_raycast(true)
		gravar_nb_turn = 0


func limit_outer(): 
	if road_type != ROAD_TYPE.PITLANE:
		road_type = ROAD_TYPE.OUTER
		enable_disable_raycast(false)
		gravar_nb_turn = 0


func limit_pitlane():
	road_type = ROAD_TYPE.PITLANE
	is_in_pitlane_area = true
	state_in_pitlane = STATE_IN_PITLANE.ENTER
	enable_disable_raycast(true)
	gravar_nb_turn = 0


func exit_pitlane():
	road_type = ROAD_TYPE.ROAD
	enable_disable_raycast(true)
	has_pit_stop = false
	is_in_pitlane_area = false
	gravar_nb_turn = 0


func enable_disable_raycast(enabled :bool) -> void:
	$detect_limit_left.enabled = enabled
	$detect_limit_rigth.enabled = enabled
	$detect_turn_left.enabled = enabled
	$detect_turn_rigth.enabled = enabled


func turn_and_brake(direction:int) -> void:
	turn(direction, direction_angle)
	brake()


func turn(direction :int, angle :float) -> void:
	var speed = get_speed()
	if speed > MIN_SPEED_ANGULAR:
		var factor = (1 if direction == DIRECTION.TURN_RIGHT or direction == DIRECTION.TURN_AND_BRAKE_RIGHT else -1)
		var velocity_rotation = (SPEED_MAX_TURN / speed) * angle * factor
		velocity = velocity.rotated(velocity_rotation if velocity_rotation < direction_angle else direction_angle) 


func turn_in_gravar(direction :int) -> void:
	if get_speed() > MIN_SPEED and (gravar_nb_turn % 2) == 0 and (ROAD_TYPE.INNER == road_type or ROAD_TYPE.OUTER == road_type):
		var velocity_rotation = GRAVAR_ANGLE * (1 if direction == DIRECTION.TURN_LEFT else -1)
		velocity = velocity.rotated(velocity_rotation)
	
	gravar_nb_turn += 1


func turn_in_pitlane(direction :int) -> void:
	if direction in [DIRECTION.TURN_LEFT, DIRECTION.TURN_RIGHT]:
		var velocity_rotation = pitlane_ANGLE * (1 if direction == DIRECTION.TURN_RIGHT else -1)
		velocity = velocity.rotated(velocity_rotation)

func brake() -> void:
	var next_velocity = velocity / COEF_BRAKE
	if next_velocity.length_squared() < LIMIT_BEFORE_ZERO_VELOCITY:
		velocity = Vector2.ZERO
	else:
		velocity = next_velocity


func accelerate(delta :float):
	var add_speed = SCALE * speed_accelerate_add_after_accelerate(delta)
	velocity = Vector2(velocity.x + add_speed * cos(velocity.angle()), velocity.y + add_speed * sin(velocity.angle()))


func get_distance_collision(raycast :RayCast2D) -> float:
	var origin = raycast.global_transform.origin
	var collision_point = raycast.get_collision_point()
	return origin.distance_to(collision_point)


func go_pitlane():
	if has_pit_stop and road_type != ROAD_TYPE.PITLANE:
		var is_turn_pitlane_left = $detect_turn_left.is_colliding() and $detect_turn_left.get_collider().is_in_group("pitlane")
		var is_turn_pitlane_right = $detect_turn_rigth.is_colliding() and $detect_turn_rigth.get_collider().is_in_group("pitlane")
		var is_limit_pitlane_left = $detect_limit_left.is_colliding() and $detect_limit_left.get_collider().is_in_group("pitlane")
		var is_limit_pitlane_right = $detect_limit_rigth.is_colliding() and $detect_limit_rigth.get_collider().is_in_group("pitlane")
	
		if is_turn_pitlane_left or is_turn_pitlane_right or is_limit_pitlane_left or is_limit_pitlane_right:
			road_type = ROAD_TYPE.PITLANE


func direction() -> int:
	var direction = DIRECTION.DONT_TURN
	
	if ROAD_TYPE.ROAD == road_type:
		var direction_colision = direction_colision()
		var direction_position_car = direction_position_car()
		if direction_position_car != DIRECTION.DONT_TURN:
			direction = direction_position_car
		else:
			direction = direction_colision
	elif road_type in [ROAD_TYPE.INNER, ROAD_TYPE.OUTER]:
		direction = direction_out_limit()
		
	elif road_type == ROAD_TYPE.PITLANE:
		direction = direction_pitlane()
	
	# Pour eviter l'effet zigzag
	if current_direction == DIRECTION.TURN_LEFT and direction == DIRECTION.TURN_RIGHT or current_direction == DIRECTION.TURN_RIGHT and direction == DIRECTION.TURN_LEFT:
		direction = DIRECTION.DONT_TURN
	elif current_direction == DIRECTION.TURN_AND_BRAKE_LEFT and direction == DIRECTION.TURN_AND_BRAKE_RIGHT or current_direction == DIRECTION.TURN_AND_BRAKE_RIGHT and direction == DIRECTION.TURN_AND_BRAKE_LEFT:
		direction = DIRECTION.BRAKE
	
	current_direction = direction
	return direction


func direction_pitlane() -> int:
	var is_turn_pitlane_left = $detect_turn_left.is_colliding() and $detect_turn_left.get_collider().is_in_group("pitlane")
	var is_turn_pitlane_right = $detect_turn_rigth.is_colliding() and $detect_turn_rigth.get_collider().is_in_group("pitlane")
	var is_limit_pitlane_left = $detect_limit_left.is_colliding() and $detect_limit_left.get_collider().is_in_group("pitlane")
	var is_limit_pitlane_right = $detect_limit_rigth.is_colliding() and $detect_limit_rigth.get_collider().is_in_group("pitlane")
	
	if is_limit_pitlane_left or is_limit_pitlane_right:
		return DIRECTION.DONT_TURN
	elif is_turn_pitlane_left:
		return DIRECTION.TURN_LEFT
	elif is_turn_pitlane_right:
		return DIRECTION.TURN_RIGHT
	
	return DIRECTION.DONT_TURN


func direction_out_limit() -> int:
	if ROAD_TYPE.INNER == road_type:
		return DIRECTION.TURN_RIGHT
	elif ROAD_TYPE.OUTER == road_type:
		return DIRECTION.TURN_LEFT
	else:
		return DIRECTION.DONT_TURN


func direction_colision() -> int:
	var is_col_on_left = $detect_turn_left.is_colliding()
	var is_col_on_right = $detect_turn_rigth.is_colliding()
	var with_left_col = $detect_limit_left.is_colliding()
	var with_right_col = $detect_limit_rigth.is_colliding()
	var is_col_car = $detect_crash.is_colliding()
	var dist_left = get_distance_collision($detect_turn_left) if is_col_on_left else 10000.0
	var dist_right = get_distance_collision($detect_turn_rigth) if is_col_on_right else 10000.0
	var car_on_left = is_col_on_left and $detect_turn_left.get_collider().is_in_group("car") and dist_left < CAR_WIDTH / 2.0
	var car_on_right = is_col_on_right and $detect_turn_rigth.get_collider().is_in_group("car") and dist_right < CAR_WIDTH / 2.0
	
	if get_speed() <= MIN_SPEED and not is_col_car:
		return DIRECTION.DONT_TURN
	elif with_left_col and with_right_col:
		if car_on_left and dist_left > dist_right or car_on_right and dist_left < dist_right:
			return DIRECTION.BRAKE
		if dist_left > dist_right:
			return DIRECTION.TURN_AND_BRAKE_LEFT
		elif dist_left < dist_right:
			return DIRECTION.TURN_AND_BRAKE_RIGHT
		else:
			return DIRECTION.BRAKE
		
	elif with_left_col and not car_on_right:
		return DIRECTION.TURN_AND_BRAKE_RIGHT
		
	elif with_right_col and not car_on_left:
		return DIRECTION.TURN_AND_BRAKE_LEFT
		
	elif with_left_col and car_on_right or with_right_col and car_on_left:
		return DIRECTION.BRAKE
		
	elif abs(dist_left - dist_right) > circuit_width and dist_left > dist_right:
		return DIRECTION.TURN_LEFT

	elif abs(dist_left - dist_right) > circuit_width and dist_left < dist_right:
		return DIRECTION.TURN_RIGHT
		
	else:
		return DIRECTION.DONT_TURN


func direction_position_car() -> int:
	var crash_with_another_car = $detect_crash.is_colliding()
	var is_col_on_left = $detect_turn_left.is_colliding()
	var is_bad_left = is_col_on_left and $detect_turn_left.get_collider().is_in_group("interior")
	var is_col_on_right = $detect_turn_rigth.is_colliding()
	var is_bad_right = is_col_on_right and $detect_turn_rigth.get_collider().is_in_group("exterior")

	if crash_with_another_car:
		return DIRECTION.BRAKE
	elif is_bad_right and not is_col_on_left:
		return DIRECTION.TURN_AND_BRAKE_LEFT if current_direction == DIRECTION.TURN_AND_BRAKE_LEFT else DIRECTION.TURN_AND_BRAKE_RIGHT
	elif is_bad_left and not is_col_on_right:
		return DIRECTION.TURN_AND_BRAKE_RIGHT if current_direction == DIRECTION.TURN_AND_BRAKE_RIGHT else DIRECTION.TURN_AND_BRAKE_LEFT
	elif is_bad_left and is_bad_right:
		return DIRECTION.TURN_AND_BRAKE_LEFT if current_direction == DIRECTION.TURN_AND_BRAKE_LEFT else DIRECTION.TURN_AND_BRAKE_RIGHT
	else:
		return DIRECTION.DONT_TURN


func speed_accelerate_add_after_accelerate(delta :float) -> float:
	var last = max_speed * (1 - exp(-sys_time * coef_accelerate))
	var next = max_speed * (1 - exp(-(sys_time + delta) * coef_accelerate))
	
	return (next - last)


func calculate_time(speed :float) -> float:
	if speed > max_speed: return time_max_speed
	else: return -log(1 - (speed / max_speed)) / coef_accelerate


func calulate_speed(param_time :float) -> float:
	return max_speed * (1 - exp(-param_time * coef_accelerate))


func get_speed() -> float:
	return calulate_speed(sys_time)


func _on_pitstop_time_timeout():
	mechanic_working = false


func _on_starting_timeout():
	max_speed = limit_speed
