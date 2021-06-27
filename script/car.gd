extends KinematicBody2D

const MAX_DISTANCE_COLLISION := 1000000.0
const SCALE := 20
const COEF_BRAKE := 1.2
const CAR_WIDTH := 500
const CAR_HEIGHT := 150
const LIMIT_CIRCUIT_WIDTH := 120
const LIMIT_BEFORE_ZERO_VELOCITY := 0.01
const MIN_SPEED := 10.0
const SPEED_MAX_TURN := 40
const GRAVAR_COEF_BRAKE := 1.1
const GRAVAR_SPEED := 20.0
const GRAVAR_ANGLE := PI * 5.0 / 360.0
const OVERTAKE_ANGLE := PI * 7.5 / 360.0
const OVERTAKE_TIME := 0.2
const PITLANE_COEF_BRAKE := 1.1
const PITLANE_SPEED := 35.0
const PITLANE_ANGLE := PI * 8.0 / 360.0
enum CAR_COLOR {RED, GOLD, SKY, SAND, GREEN, PURPLE, ORANGE, BROWN, BLUE, PINK, GRASS, CYAN, DARK_RED, WATER, WINE, DARK}
enum TEAM { TEAM_1, TEAM_2, TEAM_3, TEAM_4, TEAM_5, TEAM_6, TEAM_7, TEAM_8, TEAM_9, TEAM_10, TEAM_11 }
enum STATE_IN_PITLANE {ENTER, ENTER_GARAGE, GARAGE, EXIT_GARAGE, EXIT, RETURN_ROAD }
enum STATE_IN_OVERTAKE { BEGIN, CONTINUE, END }
enum DIRECTION { TURN_LEFT, TURN_RIGHT, TURN_AND_BRAKE_LEFT, TURN_AND_BRAKE_RIGHT, DONT_TURN, BRAKE, CONTINUE }
enum ROAD_TYPE { INNER, OUTER, ROAD, PITLANE, STRAIGHT_AND_OVERTAKE }
enum TYRE { SOFT, MEDIUM, HARD, INTERMEDIATE, WET }
enum ROAD_CONDITION { DRY, SLIGHTLY_WET, WET, VERY_WET, TOTALY_WET }
enum OUT_CIRCUIT { IN_CIRCUIT, EXTERIOR, INTERIOR }
enum IN_CIRCUIT { NONE, LINE, TURN }


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
var current_lap := 0
var position_car := 0
var total_time = []
var inside_final_line = false
var nb_tick := 0.0
var energy_level = 100.0
var tyre_health = 100.0
var max_speed_inital
var direction_angle_inital
var coef_accelerate_inital
var max_speed_final
var direction_angle_final
var coef_accelerate_final
var make_param_update = true
var actual_weather
var count := 0.0
var out_circuit = OUT_CIRCUIT.IN_CIRCUIT
var in_circuit = IN_CIRCUIT.LINE

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
		CAR_COLOR.PINK: team_color = Color(1.0, 0.6, 1.0, 1.0)
		CAR_COLOR.GRASS: team_color = Color(0.7, 1.0, 0.3, 1.0)
		CAR_COLOR.CYAN: team_color = Color(0.0, 0.0, 1.0, 1.0)
		CAR_COLOR.DARK_RED: team_color = Color(0.7, 0.0, 0.0, 1.0)
		CAR_COLOR.WATER: team_color = Color(0.0, 1.0, 1.0, 1.0)
		CAR_COLOR.WINE: team_color = Color(0.6, 0.1, 0.2, 1.0)
		CAR_COLOR.DARK: team_color = Color(0.5, 0.5, 0.5, 1.0)


func _ready():
	race_node = get_parent().get_parent()
	circuit_width = race_node.get_node("circuit/road_line").width
	current_direction = DIRECTION.DONT_TURN
	state_in_overtake = STATE_IN_OVERTAKE.END
	
	$number.text = number_car
	$number.modulate = text_color
	$helmet.modulate = helmet_color
	$car_design.frame = car_color
	direction_angle = (fast_direction_angle_degree / 360.0) * PI
	gravar_sys_time = calculate_time(GRAVAR_SPEED * SCALE)
	max_speed = limit_speed
	
	$detect_crash_l.enabled = true
	$detect_crash_r.enabled = true
	$detect_limit.enabled = true
	update_ray_cast()
	
	var circuit_height_ray_cast = circuit_width * 6.0
	$detect_turn_left.cast_to = Vector2(circuit_height_ray_cast * cos(PI / 4.0), -circuit_height_ray_cast * sin(PI / 4.0))
	$detect_turn_left.enabled = true
	$detect_turn_rigth.cast_to = Vector2(circuit_height_ray_cast * cos(PI / 4.0), circuit_height_ray_cast * sin(PI / 4.0))
	$detect_turn_rigth.enabled = true
	
	team_color_init()
	
	time_max_speed = calculate_time(limit_speed / 2.0) * 5.0
	actual_weather = race_node.weather
	update_param(true)


func _physics_process(delta):
	count += delta
	chronometre()
	
	if mechanic_working:
		update_param(true)
		return
	
	update_param(make_param_update)
	update_tyre_wear(delta)
	calculate_road()
	move_car(delta)
	
	if velocity.length() / SCALE > max_speed:
		velocity = velocity.normalized() * max_speed
	
	var collision = move_and_collide(velocity * delta)
	if collision and collision.collider is StaticBody2D:
		var bounce = velocity.angle_to(velocity.bounce(collision.normal))
		velocity = velocity.rotated(bounce / 2.0)
		brake()
		
	if get_speed() > GRAVAR_SPEED and road_type == ROAD_TYPE.ROAD and not ($detect_crash_l.is_colliding() or $detect_crash_r.is_colliding()) and collision and collision.collider is KinematicBody2D and collision.collider.is_in_group("car"):
		var bounce = velocity.angle_to(velocity.bounce(collision.normal))
		if 0.0 < bounce and bounce < PI / 4.0 or -3.0 * PI / 4.0 < bounce and bounce < 0.0:
			turn(DIRECTION.TURN_LEFT, bounce / 10.0)
		elif 0.0 > bounce and bounce > -PI / 4.0 or 3.0 * PI / 4.0 > bounce and bounce > 0.0:
			turn(DIRECTION.TURN_RIGHT, bounce / 10.0)
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
	var speed_car = get_speed()
	var coef_size_ray_cast = circuit_width + pow(speed_car, 2.0) * 0.5
	
	var size_limit_ray_cast = Vector2(coef_size_ray_cast, 0.0)
	$detect_limit.cast_to = size_limit_ray_cast
	
	var coef_car_detect = CAR_WIDTH + (CAR_WIDTH * speed_car / 100.0)
	$detect_overtake_l.cast_to = Vector2(coef_car_detect, 0)
	$detect_overtake_r.cast_to = Vector2(coef_car_detect, 0)
	$detect_crash_l.cast_to = Vector2(coef_car_detect / 4.0, 0)
	$detect_crash_r.cast_to = Vector2(coef_car_detect / 4.0, 0)


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


func update_tyre_wear(delta):
	var coef_condition
	match race_node.road_condition:
		ROAD_CONDITION.DRY: coef_condition = 1.0
		ROAD_CONDITION.SLIGHTLY_WET: coef_condition = 0.9
		ROAD_CONDITION.WET: coef_condition = 0.8
		ROAD_CONDITION.VERY_WET: coef_condition = 0.8
		ROAD_CONDITION.SLIGHTLY_WET: coef_condition = 0.8
		_: coef_condition = 0.8
	
	var coef_tyre
	match tyre:
		TYRE.HARD: coef_tyre = 0.8
		TYRE.MEDIUM: coef_tyre = 0.9
		TYRE.SOFT: coef_tyre = 1.0
		TYRE.INTERMEDIATE: coef_tyre = 1.0
		TYRE.SOFT: coef_tyre = 1.0
		_: coef_tyre = 1.0
	
	var tyre_wear = tilt_front_spoiler_pourcentage / 100.0 * tilt_back_spoiler_pourcentage / 100.0 * coef_accelerate * delta * coef_tyre * coef_condition
	tyre_health -= tyre_wear


func update_param(with_update :bool) -> void:
	if with_update:
		update_param_car()
		update_param_with_meteo_condition()
		make_param_update = false
		
	if actual_weather != race_node.weather:
		make_param_update = true
		actual_weather = race_node.weather
		
	if max_speed_inital != max_speed_final:
		max_speed = lerp(max_speed, max_speed_final, 0.05)
		direction_angle = lerp(direction_angle, direction_angle_final, 0.05)
		coef_accelerate = lerp(coef_accelerate, coef_accelerate_final, 0.05)
	else:
		max_speed = max_speed_final
		direction_angle = direction_angle_final
		coef_accelerate = coef_accelerate_final
	
	direction_angle = slow_direction_angle_degree * PI / 360.0 if in_circuit == IN_CIRCUIT.TURN else fast_direction_angle_degree * PI / 360.0


func update_param_car():
	max_speed_inital = max_speed
	direction_angle_inital = direction_angle
	coef_accelerate_inital = coef_accelerate
	
	var speed_lost_by_front = 15.0 * (tilt_front_spoiler_pourcentage / 100.0)
	var speed_lost_by_back = 15.0 * (tilt_back_spoiler_pourcentage / 100.0)
	var speed_diff_by_gearbox = 40.0 * gearbox_pourcentage / 100.0
	
	var coef_angle = 2.5
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


func update_param_with_meteo_condition_helper(coef):
	max_speed_final = max_speed * coef
	direction_angle_final = direction_angle * coef
	coef_accelerate_final = coef_accelerate * coef
	
	max_speed = max_speed_inital
	direction_angle = direction_angle_inital
	coef_accelerate = coef_accelerate_inital

func update_param_with_meteo_condition():
	if race_node.road_condition == ROAD_CONDITION.DRY and tyre == TYRE.HARD:
		update_param_with_meteo_condition_helper(0.8)
	elif race_node.road_condition == ROAD_CONDITION.DRY and tyre == TYRE.MEDIUM:
		update_param_with_meteo_condition_helper(0.9)
	elif race_node.road_condition == ROAD_CONDITION.DRY and tyre == TYRE.SOFT:
		update_param_with_meteo_condition_helper(1.0)
	elif race_node.road_condition == ROAD_CONDITION.SLIGHTLY_WET and tyre == TYRE.HARD:
		update_param_with_meteo_condition_helper(0.7)
	elif race_node.road_condition == ROAD_CONDITION.SLIGHTLY_WET and tyre == TYRE.MEDIUM:
		update_param_with_meteo_condition_helper(0.8)
	elif race_node.road_condition == ROAD_CONDITION.SLIGHTLY_WET and tyre == TYRE.SOFT:
		update_param_with_meteo_condition_helper(0.9)
	elif race_node.road_condition == ROAD_CONDITION.WET and tyre == TYRE.HARD:
		update_param_with_meteo_condition_helper(0.5)
	elif race_node.road_condition == ROAD_CONDITION.WET and tyre == TYRE.MEDIUM:
		update_param_with_meteo_condition_helper(0.6)
	elif race_node.road_condition == ROAD_CONDITION.WET and tyre == TYRE.SOFT:
		update_param_with_meteo_condition_helper(0.7)
	elif race_node.road_condition == ROAD_CONDITION.VERY_WET and tyre == TYRE.HARD:
		update_param_with_meteo_condition_helper(0.3)
	elif race_node.road_condition == ROAD_CONDITION.VERY_WET and tyre == TYRE.MEDIUM:
		update_param_with_meteo_condition_helper(0.4)
	elif race_node.road_condition == ROAD_CONDITION.VERY_WET and tyre == TYRE.SOFT:
		update_param_with_meteo_condition_helper(0.5)
	elif race_node.road_condition == ROAD_CONDITION.TOTALY_WET and tyre == TYRE.HARD:
		update_param_with_meteo_condition_helper(0.1)
	elif race_node.road_condition == ROAD_CONDITION.TOTALY_WET and tyre == TYRE.MEDIUM:
		update_param_with_meteo_condition_helper(0.2)
	elif race_node.road_condition == ROAD_CONDITION.TOTALY_WET and tyre == TYRE.SOFT:
		update_param_with_meteo_condition_helper(0.3)
	
	elif race_node.road_condition == ROAD_CONDITION.DRY and tyre == TYRE.INTERMEDIATE:
		update_param_with_meteo_condition_helper(0.7)
	elif race_node.road_condition == ROAD_CONDITION.SLIGHTLY_WET and tyre == TYRE.INTERMEDIATE:
		update_param_with_meteo_condition_helper(0.9)
	elif race_node.road_condition == ROAD_CONDITION.WET and tyre == TYRE.INTERMEDIATE:
		update_param_with_meteo_condition_helper(0.7)
	elif race_node.road_condition == ROAD_CONDITION.VERY_WET and tyre == TYRE.INTERMEDIATE:
		update_param_with_meteo_condition_helper(0.7)
	elif race_node.road_condition == ROAD_CONDITION.TOTALY_WET and tyre == TYRE.INTERMEDIATE:
		update_param_with_meteo_condition_helper(0.5)
	
	elif race_node.road_condition == ROAD_CONDITION.DRY and tyre == TYRE.WET:
		update_param_with_meteo_condition_helper(0.3)
	elif race_node.road_condition == ROAD_CONDITION.SLIGHTLY_WET and tyre == TYRE.WET:
		update_param_with_meteo_condition_helper(0.5)
	elif race_node.road_condition == ROAD_CONDITION.WET and tyre == TYRE.WET:
		update_param_with_meteo_condition_helper(0.7)
	elif race_node.road_condition == ROAD_CONDITION.VERY_WET and tyre == TYRE.WET:
		update_param_with_meteo_condition_helper(0.8)
	elif race_node.road_condition == ROAD_CONDITION.TOTALY_WET and tyre == TYRE.WET:
		update_param_with_meteo_condition_helper(0.7)


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
			state_in_overtake = STATE_IN_OVERTAKE.CONTINUE
			return OVERTAKE_ANGLE * (1 if dist_left < dist_right else -1)
			
		STATE_IN_OVERTAKE.CONTINUE:
			if nb_tick > OVERTAKE_TIME:
				state_in_overtake = STATE_IN_OVERTAKE.END
			return 0.0
			
		STATE_IN_OVERTAKE.END:
			road_type = ROAD_TYPE.ROAD
			return 0.0
			
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


func limit_road():
	if road_type != ROAD_TYPE.PITLANE:
		road_type = ROAD_TYPE.ROAD


func limit_outer(): 
	if road_type != ROAD_TYPE.PITLANE:
		road_type = ROAD_TYPE.OUTER


func limit_pitlane():
	road_type = ROAD_TYPE.PITLANE
	is_in_pitlane_area = true
	state_in_pitlane = STATE_IN_PITLANE.ENTER


func exit_pitlane():
	road_type = ROAD_TYPE.ROAD
	has_pit_stop = false
	is_in_pitlane_area = false


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
	if get_speed() > MIN_SPEED and road_type in [ROAD_TYPE.INNER, ROAD_TYPE.OUTER]:
		var velocity_rotation = GRAVAR_ANGLE * (1 if direction == DIRECTION.TURN_RIGHT else -1)
		velocity = velocity.rotated(velocity_rotation)


func turn_in_pitlane(direction :int) -> void:
	if direction in [DIRECTION.TURN_LEFT, DIRECTION.TURN_RIGHT]:
		var velocity_rotation = PITLANE_ANGLE * (1 if direction == DIRECTION.TURN_RIGHT else -1)
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
	if not raycast.is_colliding(): 
		return MAX_DISTANCE_COLLISION
	else:
		return raycast.global_transform.origin.distance_to(raycast.get_collision_point()) 


func move_car(delta):
	var direction = direction()
	
	if road_type == ROAD_TYPE.ROAD:
		move_car_circuit(direction, delta)
	elif road_type == ROAD_TYPE.STRAIGHT_AND_OVERTAKE:
		move_car_overtake(direction, delta)
	elif road_type == ROAD_TYPE.PITLANE:
		move_car_pitlane(direction)
	elif road_type in [ROAD_TYPE.INNER, ROAD_TYPE.OUTER]:
		move_car_out_circuit(direction)


func move_car_circuit(direction, delta):
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


func move_car_pitlane(direction):
	if is_in_pitlane_area:
		var angle = get_angle_in_pitlane()
		velocity = Vector2(1, 0).rotated(angle) * PITLANE_SPEED * SCALE
	
	else :
		if (velocity.length() / SCALE) / PITLANE_COEF_BRAKE > PITLANE_SPEED: 
			velocity /= PITLANE_COEF_BRAKE

		if direction == DIRECTION.TURN_LEFT or direction == DIRECTION.TURN_RIGHT:
			turn_in_pitlane(direction)


func move_car_overtake(direction, delta):
	accelerate(delta)
	velocity = velocity.rotated(get_angle_in_overtake(delta)) 


func move_car_out_circuit(direction):
	if (velocity.length() / SCALE) / GRAVAR_COEF_BRAKE > GRAVAR_SPEED: 
		velocity /= GRAVAR_COEF_BRAKE
	
	if get_speed() < GRAVAR_SPEED:
		velocity = velocity.normalized() * GRAVAR_SPEED * SCALE
	
	if direction == DIRECTION.TURN_LEFT or direction == DIRECTION.TURN_RIGHT:
		turn_in_gravar(direction)


func calculate_road():
	calculate_road_circuit()
	calculate_road_pitlane()
	calculate_road_overtake()


func calculate_road_pitlane():
	if has_pit_stop and road_type != ROAD_TYPE.PITLANE:
		var is_turn_pitlane_left = $detect_turn_left.is_colliding() and $detect_turn_left.get_collider().is_in_group("pitlane")
		var is_turn_pitlane_right = $detect_turn_rigth.is_colliding() and $detect_turn_rigth.get_collider().is_in_group("pitlane")
		var is_limit_pitlane = $detect_limit.is_colliding() and $detect_limit.get_collider().is_in_group("pitlane")
	
		if is_turn_pitlane_left or is_turn_pitlane_right or is_limit_pitlane:
			road_type = ROAD_TYPE.PITLANE


func calculate_road_circuit() -> void:
	if road_type in [ROAD_TYPE.INNER, ROAD_TYPE.OUTER] and out_circuit == OUT_CIRCUIT.IN_CIRCUIT:
		limit_road()
		road_type = ROAD_TYPE.ROAD
		
	elif road_type in [ROAD_TYPE.ROAD, ROAD_TYPE.STRAIGHT_AND_OVERTAKE] and out_circuit in [OUT_CIRCUIT.EXTERIOR, OUT_CIRCUIT.INTERIOR]:
		if out_circuit == OUT_CIRCUIT.INTERIOR:
			limit_inner()
			road_type = ROAD_TYPE.INNER
		elif out_circuit == OUT_CIRCUIT.EXTERIOR:
			limit_outer()
			road_type = ROAD_TYPE.OUTER


func calculate_road_overtake() -> void:
	if road_type in [ROAD_TYPE.INNER, ROAD_TYPE.OUTER, ROAD_TYPE.PITLANE]:
		return
	
	var with_col_limit_int = $detect_limit.is_colliding() and $detect_limit.get_collider().is_in_group("interior")
	var with_col_limit_ext = $detect_limit.is_colliding() and $detect_limit.get_collider().is_in_group("exterior")

	if out_circuit in [OUT_CIRCUIT.EXTERIOR, OUT_CIRCUIT.INTERIOR] or (road_type == ROAD_TYPE.STRAIGHT_AND_OVERTAKE and (with_col_limit_int or with_col_limit_ext)):
		state_in_overtake = STATE_IN_OVERTAKE.END
		nb_tick = 0.0
		if road_type == ROAD_TYPE.STRAIGHT_AND_OVERTAKE: 
			if out_circuit == OUT_CIRCUIT.EXTERIOR: road_type = ROAD_TYPE.OUTER
			elif out_circuit == OUT_CIRCUIT.INTERIOR: road_type = ROAD_TYPE.INNER
			else: road_type = ROAD_TYPE.ROAD
		return
	
	var detect_crash = $detect_crash_l.is_colliding() or $detect_crash_r.is_colliding()
	if detect_crash:
		state_in_overtake = STATE_IN_OVERTAKE.END
		nb_tick = 0.0
		road_type = ROAD_TYPE.ROAD if road_type == ROAD_TYPE.STRAIGHT_AND_OVERTAKE else road_type
		return
	
	var with_overtake_car = $detect_overtake_l.is_colliding() or $detect_overtake_r.is_colliding()
	
	if nb_tick > OVERTAKE_TIME or out_circuit in [OUT_CIRCUIT.EXTERIOR, OUT_CIRCUIT.INTERIOR]:
		state_in_overtake = STATE_IN_OVERTAKE.END
		nb_tick = 0.0
		if road_type == ROAD_TYPE.STRAIGHT_AND_OVERTAKE: 
			if out_circuit == OUT_CIRCUIT.EXTERIOR: road_type = ROAD_TYPE.OUTER
			elif out_circuit == OUT_CIRCUIT.INTERIOR: road_type = ROAD_TYPE.INNER
			else: road_type = ROAD_TYPE.ROAD
	
	elif in_circuit == IN_CIRCUIT.LINE and out_circuit == OUT_CIRCUIT.IN_CIRCUIT and with_overtake_car and state_in_overtake == STATE_IN_OVERTAKE.END:
		road_type = ROAD_TYPE.STRAIGHT_AND_OVERTAKE
		state_in_overtake = STATE_IN_OVERTAKE.BEGIN
		nb_tick = 0.0


func direction() -> int:
	var direction = DIRECTION.DONT_TURN
	
	if road_type == ROAD_TYPE.ROAD:
		var direction_position_car = direction_position_car()
		if direction_position_car != DIRECTION.DONT_TURN:
			direction = direction_position_car
		
		else:
			direction = direction_in_circuit()
			
	elif road_type in [ROAD_TYPE.INNER, ROAD_TYPE.OUTER]:
		direction = direction_out_circuit()
		
	elif road_type == ROAD_TYPE.PITLANE:
		direction = direction_pitlane()
	
	current_direction = direction
	return direction


func direction_pitlane() -> int:
	var is_turn_pitlane_left = $detect_turn_left.is_colliding() and $detect_turn_left.get_collider().is_in_group("pitlane")
	var is_turn_pitlane_right = $detect_turn_rigth.is_colliding() and $detect_turn_rigth.get_collider().is_in_group("pitlane")
	var is_limit_pitlane = $detect_limit.is_colliding() and $detect_limit.get_collider().is_in_group("pitlane")
	
	if is_limit_pitlane:
		return DIRECTION.DONT_TURN
	elif is_turn_pitlane_left:
		return DIRECTION.TURN_LEFT
	elif is_turn_pitlane_right:
		return DIRECTION.TURN_RIGHT
	
	return DIRECTION.DONT_TURN


func direction_out_circuit() -> int:
	var is_seeing_road = $detect_return_road.is_colliding()
	var is_seeing_road_left = $detect_return_road_left.is_colliding()
	var is_seeing_road_right = $detect_return_road_right.is_colliding()
	
	if not is_seeing_road:
		if is_seeing_road_left:
			return DIRECTION.TURN_LEFT
		elif is_seeing_road_right:
			return DIRECTION.TURN_RIGHT
		elif road_type == ROAD_TYPE.INNER:
			return DIRECTION.TURN_LEFT
		elif road_type == ROAD_TYPE.OUTER:
			return DIRECTION.TURN_RIGHT
	
	return DIRECTION.DONT_TURN


func direction_in_circuit() -> int:
	var with_col_limit = $detect_limit.is_colliding()
	var is_col_car = $detect_crash_l.is_colliding() or $detect_crash_r.is_colliding()
	var dist_left = get_distance_collision($detect_turn_left)
	var dist_right = get_distance_collision($detect_turn_rigth)
	var dist_car_left = get_distance_collision($detect_car_left)
	var dist_car_right = get_distance_collision($detect_car_rigth)
	var car_on_left = $detect_car_left.is_colliding() and dist_car_left < CAR_HEIGHT / 2.0
	var car_on_right = $detect_car_rigth.is_colliding() and dist_car_right < CAR_HEIGHT / 2.0
	var with_turn_left_bad_col = $detect_turn_left.is_colliding() and $detect_turn_left.get_collider().is_in_group("interior")
	var with_turn_left_good_col = $detect_turn_left.is_colliding() and $detect_turn_left.get_collider().is_in_group("exterior")
	var with_turn_right_bad_col = $detect_turn_rigth.is_colliding() and $detect_turn_rigth.get_collider().is_in_group("exterior")
	var with_turn_right_good_col = $detect_turn_rigth.is_colliding() and $detect_turn_rigth.get_collider().is_in_group("interior")
	
	if with_turn_left_bad_col or with_turn_right_bad_col:
		return DIRECTION.TURN_AND_BRAKE_RIGHT if dist_left - dist_right < 0 else DIRECTION.TURN_AND_BRAKE_LEFT
	
	elif with_col_limit and car_on_left and car_on_right:
		return DIRECTION.BRAKE
		
	elif with_col_limit and not car_on_right and dist_left < dist_right:
		return DIRECTION.TURN_AND_BRAKE_RIGHT
		
	elif with_col_limit and not car_on_left and dist_left > dist_right:
		return DIRECTION.TURN_AND_BRAKE_LEFT
		
	elif with_col_limit and car_on_left and car_on_right:
		return DIRECTION.BRAKE
		
	elif abs(dist_left - dist_right) > (circuit_width * 0.9) and dist_left > dist_right:
		return DIRECTION.TURN_LEFT

	elif abs(dist_left - dist_right) > (circuit_width * 0.9) and dist_left < dist_right:
		return DIRECTION.TURN_RIGHT
		
	else:
		return DIRECTION.DONT_TURN


func direction_position_car() -> int:
	var crash_with_another_car = $detect_crash_l.is_colliding() or $detect_crash_r.is_colliding()
	var with_col_limit_int = $detect_limit.is_colliding() and $detect_limit.get_collider().is_in_group("interior")
	var with_col_limit_ext = $detect_limit.is_colliding() and $detect_limit.get_collider().is_in_group("exterior")
	var is_col_on_left = $detect_turn_left.is_colliding()
	var is_bad_left = is_col_on_left and $detect_turn_left.get_collider().is_in_group("interior")
	var is_col_on_right = $detect_turn_rigth.is_colliding()
	var is_bad_right = is_col_on_right and $detect_turn_rigth.get_collider().is_in_group("exterior")
	var car_on_left = $detect_car_left.is_colliding()
	var car_on_right = $detect_car_rigth.is_colliding()
	var dist_left = get_distance_collision($detect_turn_left)
	var dist_right = get_distance_collision($detect_turn_rigth)

	if crash_with_another_car:
		if is_bad_left and is_bad_right:
			return DIRECTION.BRAKE
		elif with_col_limit_int:
			return DIRECTION.TURN_AND_BRAKE_LEFT
		elif with_col_limit_ext:
			return DIRECTION.TURN_AND_BRAKE_RIGHT
		elif car_on_left and car_on_right:
			return DIRECTION.BRAKE
		elif car_on_left and dist_right > CAR_HEIGHT:
			return DIRECTION.TURN_AND_BRAKE_RIGHT
		elif car_on_right and dist_left > CAR_HEIGHT:
			return DIRECTION.TURN_AND_BRAKE_LEFT
		elif dist_left < dist_right and dist_right > CAR_HEIGHT:
			return DIRECTION.TURN_AND_BRAKE_RIGHT
		elif dist_left > dist_right and dist_left > CAR_HEIGHT:
			return DIRECTION.TURN_AND_BRAKE_RIGHT
		else:
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
