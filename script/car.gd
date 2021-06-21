extends KinematicBody2D

const SCALE = 20
const COEF_BRAKE = 1.05
const CAR_WIDTH = 500
const CAR_HEIGHT = 150
const LIMIT_CIRCUIT_WIDTH = 120
const LIMIT_BEFORE_ZERO_VELOCITY = 0.01
const MIN_SPEED = 1.0
const SPEED_MAX_TURN = 40
const GRAVAR_COEF_BRAKE = 1.1
const GRAVAR_SPEED = 20.0
const GRAVAR_ANGLE = PI * 5.0 / 360.0
const OVERTAKE_ANGLE = PI * 7.5 / 360.0
const PITLANE_COEF_BRAKE = 1.1
const PITLANE_SPEED = 35.0
const pitlane_ANGLE = PI * 8.0 / 360.0
enum CAR_COLOR {RED, GOLD, SKY, SAND, GREEN, PURPLE, ORANGE, BROWN, BLUE, PINK, GRASS, CYAN, DARK_RED, WATER, WINE, DARK}
enum TEAM { TEAM_1, TEAM_2, TEAM_3, TEAM_4, TEAM_5, TEAM_6, TEAM_7, TEAM_8, TEAM_9, TEAM_10, TEAM_11 }
enum STATE_IN_PITLANE {ENTER, ENTER_GARAGE, GARAGE, EXIT_GARAGE, EXIT, RETURN_ROAD }
enum STATE_IN_OVERTAKE { BEGIN, CONTINUE_1, CONTINUE_2, END }
enum DIRECTION { TURN_LEFT, TURN_RIGHT, TURN_AND_BRAKE_LEFT, TURN_AND_BRAKE_RIGHT, DONT_TURN, BRAKE, CONTINUE }
enum ROAD_TYPE { INNER, OUTER, ROAD, PITLANE, STRAIGHT_AND_OVERTAKE }
enum TYRE { SOFT, MEDIUM, HARD, INTERMEDIATE, WET }
enum ROAD_CONDITION { DRY, SLIGHTLY_WET, WET, VERY_WET, TOTALY_WET }


export(String) var car_name := "voiture"
export(CAR_COLOR) var car_color
export(TEAM) var team_position
export(float) var limit_speed := 100.0 # to m/s
export(Color) var text_color = Color(1.0, 1.0, 1.0, 1.0)
export(String) var number_car = "99"
export(Color) var helmet_color = Color(1.0, 1.0, 1.0, 1.0)
export(bool) var has_pit_stop = false
export(float) var tilt_front_spoiler_pourcentage = 30 # 0 à 100
export(float) var tilt_back_spoiler_pourcentage = 30 # 0 à 100
export(float) var suspension_hardness_pourcentage = 100 # 0 à 100
export(float) var gearbox_pourcentage = 100 # 0 à 100
export(TYRE) var tyre = TYRE.MEDIUM
export(bool) var human_player = false


var race_node
var team_color = Color(1.0, 1.0, 1.0, 1.0)
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
var state_in_overtake = STATE_IN_OVERTAKE.END
var mechanic_working = false
var circuit_width = 0.0
var coef_accelerate := 0.5
var slow_direction_angle_degree := 5.0
var fast_direction_angle_degree := 5.0
var chronometre_start := 0
var chronometre_in_lap := 0
var last_lap := 0
var best_lap := 0
var total_time = []
var inside_final_line = false
var nb_tick := 0.0
var angle_in_overtake = 0.0
var energy_level = 100.0


func set_coef_accelerate(new_coef_accelerate :float) -> void:
	if new_coef_accelerate > 2.0: coef_accelerate = 2.0
	elif new_coef_accelerate < 0.5: coef_accelerate = 0.5
	else: coef_accelerate = new_coef_accelerate

func set_tilt_front_spoiler_degree(new_tilt_front_spoiler_pourcentage :float) -> void:
	if new_tilt_front_spoiler_pourcentage > 100.0: tilt_front_spoiler_pourcentage = 100.0
	elif new_tilt_front_spoiler_pourcentage < 0.0: tilt_front_spoiler_pourcentage = 0.0
	else: tilt_front_spoiler_pourcentage = new_tilt_front_spoiler_pourcentage
	
func set_tilt_back_spoiler_degree(new_tilt_back_spoiler_pourcentage :float) -> void:
	if new_tilt_back_spoiler_pourcentage > 100.0: tilt_back_spoiler_pourcentage= 100.0
	elif new_tilt_back_spoiler_pourcentage < 10.0: tilt_back_spoiler_pourcentage = 10.0
	else: tilt_back_spoiler_pourcentage = new_tilt_back_spoiler_pourcentage
	
func set_suspension_hardness_pourcentage(new_suspension_hardness_pourcentage :float) -> void:
	if new_suspension_hardness_pourcentage > 100.0: suspension_hardness_pourcentage = 100.0
	elif new_suspension_hardness_pourcentage < 0.0: suspension_hardness_pourcentage = 0.0
	else: suspension_hardness_pourcentage = new_suspension_hardness_pourcentage


func team_color_init():
	match car_color:
		CAR_COLOR.RED: team_color = Color(1.0, 0.2, 0.2, 1.0)
		CAR_COLOR.GOLD: team_color = Color(0.9, 1.0, 0.4, 1.0)
		CAR_COLOR.SKY: team_color = Color(0.4, 0.9, 1.0, 1.0)
		CAR_COLOR.SAND: team_color = Color(1.0, 0.8, 0.3, 1.0)
		CAR_COLOR.GREEN: team_color = Color(0.2, 1.0, 0.2, 1.0)
		CAR_COLOR.PURPLE: team_color = Color(1.0, 0.2, 1.0, 1.0)
		CAR_COLOR.ORANGE: team_color = Color(1.0, 0.3, 0.0, 1.0)
		CAR_COLOR.BROWN: team_color = Color(0.5, 0.3, 0.2, 1.0)
		CAR_COLOR.BLUE: team_color = Color(0.2, 0.2, 1.0, 1.0)
		CAR_COLOR.PINK: team_color = Color(0.0, 0.6, 1.0, 1.0)
		CAR_COLOR.GRASS: team_color = Color(0.7, 1.0, 0.3, 1.0)
		CAR_COLOR.CYAN: team_color = Color(0.0, 0.0, 1.0, 1.0)
		CAR_COLOR.DARK_RED: team_color = Color(0.7, 0.0, 0.0, 1.0)
		CAR_COLOR.WATER: team_color = Color(0.0, 1.0, 1.0, 1.0)
		CAR_COLOR.WINE: team_color = Color(0.6, 0.1, 0.2, 1.0)
		CAR_COLOR.DARK: team_color = Color(0.5, 0.5, 0.5, 1.0)


func _ready():
	race_node = get_parent().get_parent()
	circuit_width = race_node.get_node("circuit/road_line").width
	
	$number.text = number_car
	$number.modulate = text_color
	$helmet.modulate = helmet_color
	$car_design.frame = car_color
	direction_angle = (fast_direction_angle_degree / 360.0) * PI
	gravar_sys_time = calculate_time(GRAVAR_SPEED * SCALE)
	max_speed = limit_speed
	
	$detect_crash.enabled = true
	$detect_limit_left.enabled = true
	$detect_limit_rigth.enabled = true
	update_ray_cast()
	
	$detect_overtake.cast_to = Vector2(CAR_WIDTH, 0)
	$detect_crash.cast_to = Vector2(CAR_WIDTH / 2.5, 0)
	
	var circuit_height_ray_cast = circuit_width * 4.0
	$detect_turn_left.cast_to = Vector2(circuit_height_ray_cast * cos(PI / 4.0), -circuit_height_ray_cast * sin(PI / 4.0))
	$detect_turn_left.enabled = true
	$detect_turn_rigth.cast_to = Vector2(circuit_height_ray_cast * cos(PI / 4.0), circuit_height_ray_cast * sin(PI / 4.0))
	$detect_turn_rigth.enabled = true
	
	team_color_init()
	
	time_max_speed = calculate_time(limit_speed / 2.0) * 5.0
	update_param(true)


func _physics_process(delta):
	chronometre()
	
	if mechanic_working:
		update_param(true)
		return
	
	update_param(false)
	go_circuit()
	go_pitlane()
	go_overtake()
	var direction = direction()
	
	if road_type == ROAD_TYPE.ROAD:
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
			
	elif road_type == ROAD_TYPE.STRAIGHT_AND_OVERTAKE:
		accelerate(delta)
		velocity = velocity.rotated(get_angle_in_overtake(delta)) 
	
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
	if collision and collision.collider is StaticBody2D:
		var bounce = velocity.angle_to(velocity.bounce(collision.normal))
		velocity = velocity.rotated(bounce / 2.0)
		brake()
		
	elif get_speed() > GRAVAR_SPEED and road_type == ROAD_TYPE.ROAD and not $detect_crash.is_colliding() and collision and collision.collider is KinematicBody2D and collision.collider.is_in_group("car"):
		var angle = collision.normal.angle()
		var bounce = velocity.bounce(collision.normal).angle()
		if 0.0 < angle and angle < PI / 4.0 or -3.0 * PI / 4.0 < angle and angle < 0.0:
			turn(DIRECTION.TURN_LEFT, bounce / 25.0)
		elif 0.0 > angle and angle > -PI / 4.0 or 3.0 * PI / 4.0 > angle and angle > 0.0:
			turn(DIRECTION.TURN_RIGHT, bounce / 25.0)
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
	var coef_size_ray_cast = circuit_width + pow(get_speed(), 2.0) * 0.5
	
	var size_limit_ray_cast = Vector2(coef_size_ray_cast, 0.0)
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
	
	if race_node.road_condition == ROAD_CONDITION.SLIGHTLY_WET:
		rain_effect_apply(true, Color(1.0, 1.0, 1.0, 0.04))
	elif race_node.road_condition == ROAD_CONDITION.WET:
		rain_effect_apply(true, Color(1.0, 1.0, 1.0, 0.08))
	elif race_node.road_condition == ROAD_CONDITION.VERY_WET:
		rain_effect_apply(true, Color(1.0, 1.0, 1.0, 0.12))
	elif race_node.road_condition == ROAD_CONDITION.TOTALY_WET:
		rain_effect_apply(true, Color(1.0, 1.0, 1.0, 0.16))
	else:
		rain_effect_apply(false, Color(1.0, 1.0, 1.0, 0.16))

func rain_effect_apply(emitting, modulate_effect):
	$rain_effect_bl.emitting = emitting
	$rain_effect_bl.modulate = modulate_effect
	$rain_effect_br.emitting = emitting
	$rain_effect_br.modulate = modulate_effect
	$rain_effect_fl.emitting = emitting
	$rain_effect_fl.modulate = modulate_effect
	$rain_effect_fr.emitting = emitting
	$rain_effect_fr.modulate = modulate_effect


func update_param(with_update :bool) -> void:
	var with_slow_turn = $detect_slow_turn.is_colliding()
	
	if with_update:
		var speed_lost_by_front = 15.0 * (tilt_front_spoiler_pourcentage / 100.0)
		var speed_lost_by_back = 15.0 * (tilt_back_spoiler_pourcentage / 100.0)
		var speed_diff_by_gearbox = 40.0 * gearbox_pourcentage / 100.0
		
		var coef_angle = 5.0
		var angle_diff_by_front = coef_angle * (tilt_front_spoiler_pourcentage / 100.0)
		var angle_diff_by_suspension_front = coef_angle * suspension_hardness_pourcentage / 100.0
		
		var angle_diff_by_back = (coef_angle / 2.0) * (tilt_back_spoiler_pourcentage / 100.0)
		var angle_diff_by_suspension_back = (coef_angle / 3.0)  * (suspension_hardness_pourcentage / 100.0)
		
		coef_accelerate = 0.1
		coef_accelerate += 0.2 * (tilt_back_spoiler_pourcentage / 100.0) 
		coef_accelerate += 0.8 * (100.0 - gearbox_pourcentage) / 100.0
		coef_accelerate += 0.4 * (100.0 - suspension_hardness_pourcentage) / 100.0
		max_speed = limit_speed - speed_lost_by_front - speed_lost_by_back + speed_diff_by_gearbox
		time_max_speed = calculate_time(max_speed / 2.0) * 5.0
	
		slow_direction_angle_degree = angle_diff_by_front + angle_diff_by_back + angle_diff_by_suspension_front
		fast_direction_angle_degree = angle_diff_by_back + angle_diff_by_suspension_back
	
	update_param_with_tyre_condition()
	direction_angle = slow_direction_angle_degree * PI / 360.0 if with_slow_turn else fast_direction_angle_degree * PI / 360.0


func update_param_with_tyre_condition():
	
	if race_node.road_condition == ROAD_CONDITION.DRY and tyre == TYRE.HARD:
		direction_angle *= 0.8
	elif race_node.road_condition == ROAD_CONDITION.DRY and tyre == TYRE.MEDIUM:
		direction_angle *= 0.9
	elif race_node.road_condition == ROAD_CONDITION.DRY and tyre == TYRE.SOFT:
		direction_angle *= 1.0
	elif race_node.road_condition == ROAD_CONDITION.SLIGHTLY_WET and tyre == TYRE.HARD:
		direction_angle *= 0.7
	elif race_node.road_condition == ROAD_CONDITION.SLIGHTLY_WET and tyre == TYRE.MEDIUM:
		direction_angle *= 0.8
	elif race_node.road_condition == ROAD_CONDITION.SLIGHTLY_WET and tyre == TYRE.SOFT:
		direction_angle *= 0.9
	elif race_node.road_condition == ROAD_CONDITION.WET and tyre == TYRE.HARD:
		direction_angle *= 0.5
	elif race_node.road_condition == ROAD_CONDITION.WET and tyre == TYRE.MEDIUM:
		direction_angle *= 0.6
	elif race_node.road_condition == ROAD_CONDITION.WET and tyre == TYRE.SOFT:
		direction_angle *= 0.7
	elif race_node.road_condition == ROAD_CONDITION.VERY_WET and tyre == TYRE.HARD:
		direction_angle *= 0.3
	elif race_node.road_condition == ROAD_CONDITION.VERY_WET and tyre == TYRE.MEDIUM:
		direction_angle *= 0.4
	elif race_node.road_condition == ROAD_CONDITION.VERY_WET and tyre == TYRE.SOFT:
		direction_angle *= 0.5
	elif race_node.road_condition == ROAD_CONDITION.TOTALY_WET and tyre == TYRE.HARD:
		direction_angle *= 0.1
	elif race_node.road_condition == ROAD_CONDITION.TOTALY_WET and tyre == TYRE.MEDIUM:
		direction_angle *= 0.2
	elif race_node.road_condition == ROAD_CONDITION.TOTALY_WET and tyre == TYRE.SOFT:
		direction_angle *= 0.3
		
	elif race_node.road_condition == ROAD_CONDITION.DRY and tyre == TYRE.MEDIUM:
		direction_angle *= 0.7
	elif race_node.road_condition == ROAD_CONDITION.SLIGHTLY_WET and tyre == TYRE.MEDIUM:
		direction_angle *= 0.9
	elif race_node.road_condition == ROAD_CONDITION.WET and tyre == TYRE.MEDIUM:
		direction_angle *= 0.9
	elif race_node.road_condition == ROAD_CONDITION.VERY_WET and tyre == TYRE.MEDIUM:
		direction_angle *= 0.7
	elif race_node.road_condition == ROAD_CONDITION.TOTALY_WET and tyre == TYRE.MEDIUM:
		direction_angle *= 0.5
		
	elif race_node.road_condition == ROAD_CONDITION.DRY and tyre == TYRE.WET:
		direction_angle *= 0.3
	elif race_node.road_condition == ROAD_CONDITION.SLIGHTLY_WET and tyre == TYRE.WET:
		direction_angle *= 0.5
	elif race_node.road_condition == ROAD_CONDITION.WET and tyre == TYRE.WET:
		direction_angle *= 0.7
	elif race_node.road_condition == ROAD_CONDITION.VERY_WET and tyre == TYRE.WET:
		direction_angle *= 0.8
	elif race_node.road_condition == ROAD_CONDITION.TOTALY_WET and tyre == TYRE.WET:
		direction_angle *= 0.7
	
func chronometre():
	
	if chronometre_start == 0:
		chronometre_start = OS.get_system_time_msecs()
	
	if $detect_final_line.is_colliding() and not inside_final_line:
		inside_final_line = true
		var tick = OS.get_system_time_msecs()
		chronometre_in_lap = (tick - chronometre_start) if chronometre_start > 0 else 0
		chronometre_start = tick
		if chronometre_in_lap > 0:
			last_lap = chronometre_in_lap
			total_time.append(chronometre_in_lap)
			best_lap = get_min_time()
			get_tree().current_scene.update_ranking()
			
	elif not $detect_final_line.is_colliding():
		inside_final_line = false


func get_min_time() -> int:
	if total_time.size() < 2:
		return 0
	
	var min_time = total_time[1]
	
	for idx in range(1, total_time.size()):
		if total_time[idx] < min_time : 
			min_time = total_time[idx]
	
	return min_time


func get_angle_in_overtake(delta) -> float:
	nb_tick += delta
	
	var dist_left
	var dist_right
	
	match state_in_overtake:
		STATE_IN_OVERTAKE.BEGIN:
			dist_left = get_distance_collision($detect_turn_left)
			dist_right = get_distance_collision($detect_turn_rigth)
			nb_tick = 0.0
			state_in_overtake = STATE_IN_OVERTAKE.CONTINUE_1
			angle_in_overtake = OVERTAKE_ANGLE * (1 if dist_left < dist_right else -1)
			return angle_in_overtake
			
		STATE_IN_OVERTAKE.CONTINUE_1:
			if nb_tick > 1.5:
				state_in_overtake = STATE_IN_OVERTAKE.CONTINUE_2
			return 0.0
			
		STATE_IN_OVERTAKE.CONTINUE_2:
			state_in_overtake = STATE_IN_OVERTAKE.END
			road_type = ROAD_TYPE.ROAD
			return 0.0#-angle_in_overtake
			
		_:
			return 0.0


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
	$detect_overtake.enabled = enabled
	$detect_final_line.enabled = enabled
	
func turn_and_brake(direction:int) -> void:
	turn(direction, direction_angle)
	brake()


func turn(direction :int, angle :float) -> void:
	var speed = get_speed()
	if speed > MIN_SPEED:
		var factor = (1 if direction == DIRECTION.TURN_RIGHT or direction == DIRECTION.TURN_AND_BRAKE_RIGHT else -1)
		var velocity_rotation = angle * factor * (pow(SPEED_MAX_TURN / speed, 2) if SPEED_MAX_TURN > speed else 1.0)
		velocity = velocity.rotated(velocity_rotation if velocity_rotation < direction_angle else direction_angle) 


func turn_in_gravar(direction :int) -> void:
	if get_speed() > MIN_SPEED and (gravar_nb_turn % 1) == 0 and (ROAD_TYPE.INNER == road_type or ROAD_TYPE.OUTER == road_type):
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
	energy_level -= delta / 60.0
	sys_time += delta
	var new_speed = SCALE * get_speed()
	velocity = Vector2(cos(velocity.angle()), sin(velocity.angle())) * new_speed


func get_distance_collision(raycast :RayCast2D) -> float:
	var origin = raycast.global_transform.origin
	var collision_point = raycast.get_collision_point() if raycast.is_colliding() else Vector2(100000.0, 100000.0)
	return origin.distance_to(collision_point)


func go_pitlane():
	if has_pit_stop and road_type != ROAD_TYPE.PITLANE:
		var is_turn_pitlane_left = $detect_turn_left.is_colliding() and $detect_turn_left.get_collider().is_in_group("pitlane")
		var is_turn_pitlane_right = $detect_turn_rigth.is_colliding() and $detect_turn_rigth.get_collider().is_in_group("pitlane")
		var is_limit_pitlane_left = $detect_limit_left.is_colliding() and $detect_limit_left.get_collider().is_in_group("pitlane")
		var is_limit_pitlane_right = $detect_limit_rigth.is_colliding() and $detect_limit_rigth.get_collider().is_in_group("pitlane")
	
		if is_turn_pitlane_left or is_turn_pitlane_right or is_limit_pitlane_left or is_limit_pitlane_right:
			road_type = ROAD_TYPE.PITLANE


func go_circuit() -> void:
	var is_colliding = $detect_circuit.is_colliding()
	var detect_out_circuit_interior = is_colliding and $detect_circuit.get_collider().is_in_group("interior") 
	var detect_out_circuit_exterior = is_colliding and $detect_circuit.get_collider().is_in_group("exterior")
	var detect_out_circuit = detect_out_circuit_interior or detect_out_circuit_exterior
	var detect_in_circuit = is_colliding and ($detect_circuit.get_collider().is_in_group("turn") or $detect_circuit.get_collider().is_in_group("line"))
	
	if road_type in [ROAD_TYPE.INNER, ROAD_TYPE.OUTER] and detect_in_circuit:
		limit_road()
		road_type = ROAD_TYPE.ROAD
		
	elif road_type in [ROAD_TYPE.ROAD, ROAD_TYPE.STRAIGHT_AND_OVERTAKE] and detect_out_circuit:
		if detect_out_circuit_interior:
			limit_inner()
			road_type = ROAD_TYPE.INNER
		elif detect_out_circuit_exterior:
			limit_outer()
			road_type = ROAD_TYPE.OUTER


func go_overtake() -> void:
	var with_left_col_limit = $detect_limit_left.is_colliding() and ($detect_limit_left.get_collider().is_in_group("interior") or $detect_limit_left.get_collider().is_in_group("exterior"))
	var with_right_col_limit = $detect_limit_rigth.is_colliding() and ($detect_limit_rigth.get_collider().is_in_group("interior") or $detect_limit_rigth.get_collider().is_in_group("exterior"))
	var is_in_turn =  $detect_slow_turn.is_colliding() 
	
	if road_type != ROAD_TYPE.ROAD or is_in_turn or with_left_col_limit or with_right_col_limit:
		road_type = ROAD_TYPE.ROAD if road_type == ROAD_TYPE.STRAIGHT_AND_OVERTAKE else road_type
		state_in_overtake = STATE_IN_OVERTAKE.END
		return
	
	var with_overtake_car = $detect_overtake.is_colliding()
	var is_car_in_left = $detect_turn_left.is_colliding() and $detect_turn_left.get_collider().is_in_group("car")
	var is_car_in_right = $detect_turn_rigth.is_colliding() and $detect_turn_rigth.get_collider().is_in_group("car")
	if not with_overtake_car or is_car_in_left or is_car_in_right:
		state_in_overtake = STATE_IN_OVERTAKE.END
		road_type = ROAD_TYPE.ROAD if road_type == ROAD_TYPE.STRAIGHT_AND_OVERTAKE else road_type
		return
	
	if state_in_overtake == STATE_IN_OVERTAKE.END:
		state_in_overtake = STATE_IN_OVERTAKE.BEGIN
		road_type = ROAD_TYPE.STRAIGHT_AND_OVERTAKE

func direction() -> int:
	var direction = DIRECTION.DONT_TURN
	
	if ROAD_TYPE.ROAD == road_type:
		var direction_position_car = direction_position_car()
		if direction_position_car != DIRECTION.DONT_TURN:
			direction = direction_position_car
		else:
			direction = direction_colision()
			
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
	var is_seeing_road = $detect_return_road.is_colliding()
	
	if ROAD_TYPE.INNER == road_type and not is_seeing_road:
		return DIRECTION.TURN_RIGHT
	elif ROAD_TYPE.OUTER == road_type and not is_seeing_road:
		return DIRECTION.TURN_LEFT
	else:
		return DIRECTION.DONT_TURN


func direction_colision() -> int:
	var with_left_col = $detect_limit_left.is_colliding() and ($detect_limit_left.get_collider().is_in_group("exterior") or $detect_limit_left.get_collider().is_in_group("interior"))
	var with_right_col = $detect_limit_rigth.is_colliding() and ($detect_limit_rigth.get_collider().is_in_group("exterior") or $detect_limit_rigth.get_collider().is_in_group("interior"))
	var is_col_car = $detect_crash.is_colliding()
	var dist_left = get_distance_collision($detect_turn_left)
	var dist_right = get_distance_collision($detect_turn_rigth)
	var car_on_left = $detect_turn_left.is_colliding() and $detect_turn_left.get_collider().is_in_group("car") and dist_left < CAR_HEIGHT / 2.0
	var car_on_right = $detect_turn_rigth.is_colliding() and $detect_turn_rigth.get_collider().is_in_group("car") and dist_right < CAR_HEIGHT / 2.0
	var with_turn_left_bad_col = $detect_turn_left.is_colliding() and $detect_turn_left.get_collider().is_in_group("interior")
	var with_turn_right_bad_col = $detect_turn_rigth.is_colliding() and $detect_turn_rigth.get_collider().is_in_group("exterior")
	
	if get_speed() <= GRAVAR_SPEED / 2.0 and not is_col_car:
		return DIRECTION.DONT_TURN
		
	elif with_left_col and with_right_col:
		if with_turn_left_bad_col:
			return DIRECTION.TURN_AND_BRAKE_RIGHT
		elif with_turn_right_bad_col:
			return DIRECTION.TURN_AND_BRAKE_LEFT
		elif car_on_left and dist_left > dist_right or car_on_right and dist_left < dist_right:
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


func calculate_time(speed :float) -> float:
	if speed > max_speed: return time_max_speed
	else: return -log(1 - (speed / max_speed)) / coef_accelerate


func calulate_speed(param_time :float) -> float:
	return max_speed * (1 - exp(-param_time * coef_accelerate))


func get_speed() -> float:
	return calulate_speed(sys_time)


func _on_pitstop_time_timeout():
	mechanic_working = false
