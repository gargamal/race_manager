extends KinematicBody2D


export(String) var car_name := "voiture"
export(float) var max_speed := 100.0 # to m/s
export(float) var accelerate_G := 2.0
export(float) var direction_angle_degree := 20.0


const SCALE = 20
const COEF_BRAKE = 1.05
const GRAVAR_COEF_BRAKE = 1.1
const CAR_HEIGHT = 500
const CAR_WIDTH = 150
const LIMIT_BEFORE_ZERO_VELOCITY = 0.1
const MIN_SPEED = 5.0
const SPEED_MAX_TURN = 40
const GRAVAR_SPEED = 40.0
const GRAVAR_ANGLE = PI * 8.0 / 360.0
enum DIRECTION { TURN_LEFT, TURN_RIGHT, TURN_AND_BRAKE_LEFT, TURN_AND_BRAKE_RIGHT, DONT_TURN, BRAKE }
enum ROAD_TYPE { INNER, OUTER, ROAD }


var sys_time := 0.0
var velocity := Vector2.ZERO
var direction_angle := 0.0
var gravar_sys_time := 0.0
var road_type = ROAD_TYPE.ROAD
var gravar_nb_turn := 0
var time_max_speed := 0.0
var current_direction := 0


func _ready():
	direction_angle = (direction_angle_degree / 360.0) * PI
	gravar_sys_time = calculate_time(GRAVAR_SPEED * SCALE)
	
	var size_car_ray_cast = Vector2(CAR_HEIGHT, 0.0)
	$detect_car_left.cast_to = size_car_ray_cast
	$detect_car_left.enabled = true
	$detect_car_right.cast_to = size_car_ray_cast
	$detect_car_right.enabled = true
	
	var circuit_width = get_parent().get_node("circuit").width
	var circuit_with_ray_cast = circuit_width * 4.0
	var size_limit_ray_cast = Vector2(circuit_with_ray_cast, 0.0)
	$detect_limit_left.cast_to = size_limit_ray_cast
	$detect_limit_left.enabled = true
	$detect_limit_rigth.cast_to = size_limit_ray_cast
	$detect_limit_rigth.enabled = true
	
	var circuit_height_ray_cast = circuit_width * 4.0
	$detect_turn_left.cast_to = Vector2(circuit_height_ray_cast * cos(PI / 4.0), -circuit_height_ray_cast * sin(PI / 4.0))
	$detect_turn_left.enabled = true
	$detect_turn_rigth.cast_to = Vector2(circuit_height_ray_cast * cos(PI / 4.0), circuit_height_ray_cast * sin(PI / 4.0))
	$detect_turn_rigth.enabled = true
	
	time_max_speed = calculate_time(max_speed / 2.0) * 5


func _physics_process(delta):
	var direction = direction()
	if ROAD_TYPE.ROAD == road_type:
		if direction == DIRECTION.BRAKE:
			brake()
			
		elif direction == DIRECTION.TURN_LEFT or direction == DIRECTION.TURN_RIGHT:
			accelerate(delta)
			turn(direction, direction_angle)
			
		elif direction == DIRECTION.TURN_AND_BRAKE_LEFT or direction == DIRECTION.TURN_AND_BRAKE_RIGHT:
			turn_and_brake(direction)
			
		else:
			accelerate(delta)
	
	else:
		if (velocity.length() / SCALE) / GRAVAR_COEF_BRAKE > GRAVAR_SPEED: 
			velocity /= GRAVAR_COEF_BRAKE
		
		if get_speed() < GRAVAR_SPEED:
			velocity *= GRAVAR_COEF_BRAKE
		
		if direction == DIRECTION.TURN_LEFT or direction == DIRECTION.TURN_RIGHT:
			turn_in_gravar(direction)
	
	if velocity.length() / SCALE > max_speed:
		velocity = velocity.normalized() * max_speed
	
	
	var collision = move_and_collide(velocity * delta)
	if collision  and collision.collider is KinematicBody2D and collision.collider.is_in_group("car"):
		var angle = collision.normal.angle()
		var bounce = velocity.bounce(collision.normal).normalized().angle()
		if 0.0 < angle and angle < PI / 4.0:
			turn(DIRECTION.TURN_LEFT, bounce / 3.0)
		elif 0.0 > angle and angle > -PI / 4.0:
			turn(DIRECTION.TURN_RIGHT, bounce / 3.0)
		else:
			brake()
	
	sys_time = calculate_time(velocity.length() / SCALE)
	self.rotation = velocity.angle()


############################################
############################################


func limit_inner():
	road_type = ROAD_TYPE.INNER
	$detect_limit_left.enabled = false
	$detect_limit_rigth.enabled = false
	$detect_turn_left.enabled = false
	$detect_turn_rigth.enabled = false
	gravar_nb_turn = 0

func limit_road():
	road_type = ROAD_TYPE.ROAD
	$detect_limit_left.enabled = true
	$detect_limit_rigth.enabled = true
	$detect_turn_left.enabled = true
	$detect_turn_rigth.enabled = true
	gravar_nb_turn = 0

func limit_outer(): 
	road_type = ROAD_TYPE.OUTER
	$detect_limit_left.enabled = false
	$detect_limit_rigth.enabled = false
	$detect_turn_left.enabled = false
	$detect_turn_rigth.enabled = false
	gravar_nb_turn = 0


func turn_and_brake(direction:int) -> void:
	turn(direction, direction_angle)
	brake()


func turn(direction :int, angle :float) -> void:
	var speed = get_speed()
	if speed > MIN_SPEED:
		var factor = (1 if direction == DIRECTION.TURN_RIGHT or direction == DIRECTION.TURN_AND_BRAKE_RIGHT else -1)
		var velocity_rotation = angle * factor
		velocity_rotation -= (speed - SPEED_MAX_TURN) * factor * PI / 4.0 / 360.0
		velocity = velocity.rotated(velocity_rotation) 


func turn_in_gravar(direction :int) -> void:
	if get_speed() > MIN_SPEED and (gravar_nb_turn % 2) == 0 and (ROAD_TYPE.INNER == road_type or ROAD_TYPE.OUTER == road_type):
		var velocity_rotation = GRAVAR_ANGLE * (1 if direction == DIRECTION.TURN_LEFT else -1)
		velocity = velocity.rotated(velocity_rotation)
	
	gravar_nb_turn += 1


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


func direction() -> int:
	var direction = DIRECTION.DONT_TURN
	
	if ROAD_TYPE.ROAD == road_type:
		var direction_colision = direction_colision()
		var direction_position_car = direction_position_car()
		if direction_colision != DIRECTION.DONT_TURN:
			direction = direction_colision
		else:
			direction = direction_position_car
	else:
		var direction_out_limit = direction_out_limit()
		direction = direction_out_limit
		
	# Pour eviter l'effet zigzag
	if current_direction == DIRECTION.TURN_LEFT and direction == DIRECTION.TURN_RIGHT or current_direction == DIRECTION.TURN_RIGHT and direction == DIRECTION.TURN_LEFT:
		direction = DIRECTION.DONT_TURN
	elif current_direction == DIRECTION.TURN_AND_BRAKE_LEFT and direction == DIRECTION.TURN_AND_BRAKE_RIGHT or current_direction == DIRECTION.TURN_AND_BRAKE_RIGHT and direction == DIRECTION.TURN_AND_BRAKE_LEFT:
		direction = DIRECTION.BRAKE
	
	current_direction = direction
	return direction


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
	var dist_left = get_distance_collision($detect_turn_left) if is_col_on_left else 10000.0
	var dist_right = get_distance_collision($detect_turn_rigth) if is_col_on_right else 10000.0
	var car_on_left = is_col_on_left and $detect_turn_left.get_collider().is_in_group("car") and dist_left < CAR_WIDTH / 2.0
	var car_on_right = is_col_on_right and $detect_turn_rigth.get_collider().is_in_group("car") and dist_right < CAR_WIDTH / 2.0
	
	if is_col_with_another_car_and_dont_touch_limit():
		
		if car_on_left and car_on_right:
			return DIRECTION.BRAKE
		elif car_on_left:
			return DIRECTION.TURN_AND_BRAKE_RIGHT if with_left_col or with_right_col else DIRECTION.TURN_RIGHT
		elif car_on_right:
			return DIRECTION.TURN_AND_BRAKE_LEFT if with_left_col or with_right_col else DIRECTION.TURN_LEFT
		elif dist_left < dist_right:
			return DIRECTION.TURN_AND_BRAKE_RIGHT if with_left_col or with_right_col else DIRECTION.TURN_RIGHT
		else:
			return DIRECTION.TURN_AND_BRAKE_LEFT if with_left_col or with_right_col else DIRECTION.TURN_LEFT
	
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
		
	else:
		return DIRECTION.DONT_TURN


func is_col_with_another_car_and_dont_touch_limit() -> bool:
	var is_car_col_left = $detect_car_left.is_colliding() and $detect_car_left.get_collider().is_in_group("car")
	var is_car_col_right = $detect_car_right.is_colliding() and $detect_car_right.get_collider().is_in_group("car")
	var is_limit_col_left = $detect_car_left.is_colliding() and $detect_car_left.get_collider().is_in_group("exterior")
	var is_limit_col_right = $detect_car_right.is_colliding() and $detect_car_right.get_collider().is_in_group("interior")
	return (is_car_col_left or is_car_col_right) and not is_limit_col_left and not is_limit_col_right


func direction_position_car() -> int:
	var is_col_on_left = $detect_turn_left.is_colliding()
	var is_bad_left = is_col_on_left and $detect_turn_left.get_collider().is_in_group("interior")
	var is_col_on_right = $detect_turn_rigth.is_colliding()
	var is_bad_right = is_col_on_right and $detect_turn_rigth.get_collider().is_in_group("exterior")

	if is_bad_right and not is_col_on_left:
		return DIRECTION.TURN_LEFT
	elif is_bad_left and not is_col_on_right:
		return DIRECTION.TURN_RIGHT
	elif is_bad_left and is_bad_right:
		return DIRECTION.TURN_AND_BRAKE_LEFT
	else:
		return DIRECTION.DONT_TURN


func speed_accelerate_add_after_accelerate(delta :float) -> float:
	var last = max_speed * (1 - exp(-sys_time * accelerate_G))
	var next = max_speed * (1 - exp(-(sys_time + delta) * accelerate_G))
	
	return (next - last)


func calculate_time(speed :float) -> float:
	if speed > max_speed: return time_max_speed
	else: return -log(1 - (speed / max_speed)) / accelerate_G


func calulate_speed(param_time :float) -> float:
	return max_speed * (1 - exp(-param_time * accelerate_G))


func get_speed() -> float:
	return calulate_speed(sys_time)

