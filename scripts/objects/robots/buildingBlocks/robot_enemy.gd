extends Robot

class_name Robot_Enemy
## Holds some helper functions for enemy [Robot]s that would be useless for a [Robot_Player].

var frontRay : RayCast3D;
var playerRay : RayCast3D;
var directionRay : RayCast3D;

var frontRayCollision = null;## Collider gathered in [method update_front_ray_result]. Set to null if invalid.
var frontRayColType : rayColTypes = rayColTypes.NONE; ## Collider type in [enum rayColTypes] gathered in [method update_front_ray_result] based on [member frontRayCollision]. 
var frontRayNormal = Vector3(0,0,0).normalized();## Collision normal gathered in [method update_front_ray_result]. Set to null if invalid.
var frontDirection := Vector2(0,1).normalized();## The front of the robot, determined by body rotation.
@export var frontRayDistance = 5.0; ## How long the front collision ray should be.
var frontRayDistanceToPoint = 0.0; ## Calculated in [method update_front_ray_result]. how far away from colliding the bot is directly in front of it.
@export var chasesPlayerInReverse := false; ##@experimental: When set to true, this bot will go into reverse when the player is behind them.
@export var playerChaseDistance := 30.;
## Used by pointer swivels. They will try to point to this global position when on an enemy.
var pointerTarget := Vector3(0,0,0);
var playerWallDodgeVector : Vector2;
var playerWallDodgeAngle : float;

func _ready():
	super();

func assign_references(forceTemp := false):
	if referencesAssigned: return;
	super(forceTemp);
	if !is_instance_valid(frontRay):
		var newRay = RayCast3D.new();
		newRay.set_collision_mask_value(11, true);
		add_child(newRay);
		frontRay = newRay;
		frontRay.enabled = true;
		frontRay.add_exception(body);
		frontRay.set_debug_shape_thickness(5)
		frontRay.set_debug_shape_custom_color(Color(0,1,0))
	if !is_instance_valid(playerRay):
		var newRay = RayCast3D.new();
		newRay.set_collision_mask_value(11, true);
		add_child(newRay);
		playerRay = newRay;
		playerRay.enabled = true;
		playerRay.add_exception(body);
		playerRay.set_debug_shape_thickness(5)
		playerRay.set_debug_shape_custom_color(Color(1,0,1))
	if !is_instance_valid(directionRay):
		var newRay = RayCast3D.new();
		newRay.set_collision_mask_value(11, true);
		add_child(newRay);
		directionRay = newRay;
		directionRay.enabled = true;
		directionRay.add_exception(body);
		directionRay.set_debug_shape_thickness(5)
		directionRay.set_debug_shape_custom_color(Color(1,0,1))

func get_front_direction_vector3(inVector := frontDirection):
	return Vector3(inVector.x, 0, inVector.y);

func phys_process_pre(delta):
	#return;
	super(delta);
	## Set the calculated 'front' direction this frame.
	frontDirection = Vector2.from_angle(body.global_rotation.y - PI/2)
	frontDirection.y *= -1;

var randomizedVector : Vector2;
var randomizedVectorTimer := 0.0;
var randomizedFactor := 1.0; ## 1.0 or -1.0 based on the randomizedVectorTimer loop.
func phys_process_timers(delta):
	#return;
	super(delta);
	if not is_frozen():
		## Subtract delta from rayCheckTimer.
		## If the bot is asleep, set the timer to that instead.
		rayCheckTimer = max(rayCheckTimer - delta, sleepTimer, 0);
		
		if rayCheckTimer <= 0:
			frontRay.global_position = body.global_position
			#frontRay.global_position += Vector3(0,4,0);
			frontRay.enabled = true;
			rayCheckTimer = rayCheckFrequency;
			#print(rayCheckFrequency)
			phys_process_detection(delta)
		else:
			#frontRay.enabled = false;
			pass;
		
		
		##For wandering movement.
		randomizedVectorTimer -= delta;
		
		if randomizedVectorTimer < 0:
			randomizedVectorTimer += randf_range(0.5,2.0);
			if randi_range(0,10) > 3:
				randomizedVector = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized();
			else:
				randomizedVector = Vector2.ZERO;
			if randi_range(1,10) > 5:
				randomizedFactor = 1.0;
			else:
				randomizedFactor = -1.0;

func get_wandering_movement() -> Vector2:
	return randomizedVector;

@export var rayCheckFrequency := 0.10; ## The amount of time between [method phys_process_detection] updates.
var rayCheckTimer := 0.15; ## The amount of time before the next [method phys_process_detection] call.[br]If [member sleepTimer] is greater than this value, it gets set to it.
## Runs after [method phys_process_timers] if [method is_frozen] does not return true, and when rayCheckTimer < 0.
func phys_process_detection(delta):
	update_if_ray_colliding_with_player(0.0,true);
	update_front_ray_result();
	playerWallDodgeAngle = rotation_to_dodge_walls_and_move_towards_player();

func phys_process_motion(delta):
	#return;
	if not is_frozen():
		GameState.profiler_time_msec_start("Checking if player is behind")
		if chasesPlayerInReverse:
			if player_is_behind():
				put_in_reverse();
		GameState.profiler_time_msec_end("Checking if player is behind")
	super(delta);

var playerInRaySight := false; ## Updated in [method update_if_ray_colliding_with_player]. True if [member playerRay] was colliding with the player that frame.
var wallInWayOfPlayer := false; ## Updated in [method update_if_ray_colliding_with_player]. True if [member playerRay] was colliding with a wall that frame.
var enemyInWayOfPlayer := false; ## Updated in [method update_if_ray_colliding_with_player]. True if [member playerRay] was colliding with a [Robot] that wasn't a [Robot_Player] that frame.
var playerInRaySightOG := false; ## Updated in [method update_if_ray_colliding_with_player] if [param update_if_ray_colliding_with_player.isOriginal] == true. True if [member playerRay] was colliding with the player that frame. Serves to show what the value was at the start of the frame before doing any dodging or whatever.
var wallInWayOfPlayerOG := false; ## Updated in [method update_if_ray_colliding_with_player] if [param update_if_ray_colliding_with_player.isOriginal] == true. True if [member playerRay] was colliding with a wall that frame. Serves to show what the value was at the start of the frame before doing any dodging or whatever.
var enemyInWayOfPlayerOG := false; ## Updated in [method update_if_ray_colliding_with_player] if [param update_if_ray_colliding_with_player.isOriginal] == true. True if [member playerRay] was colliding with a [Robot] that wasn't a [Robot_Player] that frame. Serves to show what the value was at the start of the frame before doing any dodging or whatever.
## Sets [member playerRay] directly forward and updates stuff based on what it hits. 
func update_if_ray_colliding_with_player(rotationalOffset := 0.0, isOriginal := false) -> bool:
	wallInWayOfPlayer = false;
	playerInRaySight = false;
	enemyInWayOfPlayer = false;
	if isOriginal:
		wallInWayOfPlayerOG = false;
		playerInRaySightOG = false;
		enemyInWayOfPlayerOG = false;
	if is_instance_valid(playerRay) and player_in_range():
		playerRay.global_position = body.global_position;
		playerRay.target_position = GameState.get_player_pos_offset(body.global_position);
		if rotationalOffset != 0.0:
			playerRay.target_position = playerRay.target_position.rotated(Vector3(0,1,0),rotationalOffset);
		
		playerRay.force_raycast_update();
		var col = null;
		if playerRay.is_colliding():
			col = playerRay.get_collider();
		
		match parse_ray_collider_result(col):
			rayColTypes.NONE:
				playerRay.set_debug_shape_custom_color(Color(0.8,0.8,0.8));
				pass;
			rayColTypes.PLAYER:
				playerRay.set_debug_shape_custom_color(Color(0,1,0));
				if isOriginal:
					playerInRaySightOG = true;
				playerInRaySight = true;
				pass;
			rayColTypes.ENEMY:
				playerRay.set_debug_shape_custom_color(Color(0,0,1));
				if isOriginal:
					enemyInWayOfPlayerOG = true;
				enemyInWayOfPlayer = true;
				pass;
			rayColTypes.OBSTACLE:
				playerRay.set_debug_shape_custom_color(Color(1,1,0));
				if isOriginal:
					wallInWayOfPlayerOG = true;
				wallInWayOfPlayer = true;
				pass;
			rayColTypes.WALL:
				playerRay.set_debug_shape_custom_color(Color(0.5,0.5,0));
				if isOriginal:
					wallInWayOfPlayerOG = true;
				wallInWayOfPlayer = true;
				pass;
			rayColTypes.FLOOR:
				playerRay.set_debug_shape_custom_color(Color(0.5,0.5,0));
				if isOriginal:
					wallInWayOfPlayerOG = true;
				wallInWayOfPlayer = true;
				pass;
		
		return playerInRaySight;
	
	playerRay.set_debug_shape_custom_color(Color(0.0,0.0,0.0));
	playerInRaySight = false;
	if isOriginal:
		playerInRaySightOG = true;
	return playerInRaySight;

## Sets [member frontRay] directly forward and updates stuff based on what it hits. 
func update_front_ray_result(positionOffset := Vector3.ZERO):
	if is_instance_valid(frontRay):
		var dist = frontRayDistance;
		if is_in_reverse():
			dist *= -1;
		frontRay.position += positionOffset;
		frontRay.target_position = get_front_direction_vector3() * dist;
		#prints(frontRay.target_position, get_front_direction_vector3() * dist, dist);
		frontRay.force_raycast_update();
		if frontRay.is_colliding():
			frontRayCollision = frontRay.get_collider();
			frontRayNormal = frontRay.get_collision_normal();
			frontRayDistanceToPoint = frontRay.get_collision_point().distance_to(frontRay.global_position);
		else:
			frontRayCollision = null;
			frontRayNormal = null;
			frontRayDistanceToPoint = -1;
		
		frontRayColType = parse_ray_collider_result(frontRayCollision);

func get_angle_to_player_from_front(inDegrees := false) -> float:
	var playerOffset = GameState.get_player_pos_offset(body.global_position);
	var ply2 = Vector2(playerOffset.x, playerOffset.z);
	var glb2 = frontDirection;
	var plyA = ply2.angle();
	var glbA = glb2.angle();
	
	var angle = Utils.angle_difference_relative(plyA, glbA);
	
	if inDegrees:
		return rad_to_deg(angle);
	return angle;

## Returns true when the player's angle from [member frontDirection] is > 90 degrees (PI/2).
func player_is_behind():
	return get_angle_to_player_from_front(false) > PI/2;

func get_basic_player_chase_vector(reverse := false):
	var plyOffset = GameState.get_player_pos_offset(body.global_position);
	var length = GameState.get_len_to_player(body.global_position);
	var vectorOut = Vector2(-plyOffset.x, -plyOffset.z);
	if reverse:
		vectorOut = vectorOut.rotated(PI);
	return vectorOut;

func set_pointer_to_look_at_player(angleOffset := 0.0):
	var plyOffset = GameState.get_player_pos_offset(body.global_position);
	pointerTarget = plyOffset;
	pointerTarget.z *= -1;
	pointerTarget = pointerTarget.rotated(Vector3.UP, -PI/2)
	pointerTarget = pointerTarget.rotated(Vector3.UP, angleOffset)
	#print(pointerTarget);

func set_pointer_to_look_at_movement_vector(vectorIn := movementVector):
	var vector = vectorIn;
	pointerTarget = get_front_direction_vector3(vector);
	pointerTarget.z *= -1;
	pointerTarget = pointerTarget.rotated(Vector3.UP, -PI/2)
	#print(pointerTarget);
## Rotates the [param invector] in steps of [param degreeStep] until its absolute value reaches [param maxRotation] in either direction, or [method update_if_ray_colliding_with_player] returns a result that has the player not obscured by a wall ( [code]playerInRaySight == true[/code] ).[br][br]
## [color=pink][i]This is probably pretty pricey since it deals with raycasts.
func rotate_movement_vector_to_dodge_walls_and_move_towards_player(invector : Vector2 = get_basic_player_chase_vector(), maxRotation := PI * 2/3, degreeStep := 20.) -> Vector2:
	return invector.rotated(rotation_to_dodge_walls_and_move_towards_player(invector, maxRotation, degreeStep));

func rotation_to_dodge_walls_and_move_towards_player(invector : Vector2 = get_basic_player_chase_vector(), maxRotation := PI * 1/3, degreeStep := 20.) -> float:
	var outvector = invector;
	if !(wallInWayOfPlayer or enemyInWayOfPlayer): 
		if playerInRaySight: return 0.0; ## If the player's in sight, ignore this function.
	
	var amtOfRotation = 0.;
	var angleToPlayer = get_angle_to_player_from_front();
	var factor = 1;
	
	## Determine factor based on which angle to them would be closest.
	if angleToPlayer < 0:
		factor = -1;
	## Loop over the rotation until it's reached its maximum.
	while (
		abs(amtOfRotation) < abs(maxRotation)
		and 
		(wallInWayOfPlayer or enemyInWayOfPlayer)
	):
		amtOfRotation += deg_to_rad(degreeStep * factor);
		
		## If this first check passed, we're done here.
		if update_if_ray_colliding_with_player(amtOfRotation):
			return amtOfRotation;
	
	## If the player ray still isn't in sight, check the other way.
	## Save the old result.
	var firstAmt = amtOfRotation;
	## Flip the factor, reset the amount, and try the while again.
	factor *= -1;
	amtOfRotation = 0.0;
	
	## Check the other way.
	while (
		abs(amtOfRotation) < abs(maxRotation)
		and 
		(wallInWayOfPlayer or enemyInWayOfPlayer)
		and 
		abs(amtOfRotation) < abs(firstAmt) ## Don't keep looping if the next loop would bring us over the original check.
	):
		amtOfRotation += deg_to_rad(degreeStep * factor);
		
		## If this second check passed, then we're done here.
		if update_if_ray_colliding_with_player(amtOfRotation):
			return amtOfRotation;
	
	var secondAmt = amtOfRotation;
	
	#outvector = outvector.rotated(amtOfRotation);
	## If the new amt is less than the first, rotate using it.
	if abs(secondAmt) < abs(firstAmt):
		return secondAmt;
	## If the first amt is less than the new, rotate using it.
	elif abs(secondAmt) > abs(firstAmt):
		return firstAmt;
	
	## If neither of the checks passed, and both angles are equal, then it chooses either the second result or the input, at random (50%).
	## The 2nd result is chosen because it will likely move the bot away from the player, and subsequently any walls in the way.
	if randomizedFactor > 0:
		return secondAmt;
	else: 
		return firstAmt;

func player_in_range(distanceOverride := playerChaseDistance):
	return GameState.get_len_to_player(body.global_position) <= distanceOverride;

enum rayColTypes {
	FLOOR,
	WALL,
	OBSTACLE,
	NONE,
	PLAYER,
	ENEMY
}
func parse_ray_collider_result(collision : CollisionObject3D = frontRayCollision) -> rayColTypes:
	if !is_instance_valid(collision):
		return rayColTypes.NONE;
	if collision is RobotBody:
		var bot = collision.get_robot();
		if bot is Robot_Player:
			return rayColTypes.PLAYER;
		return rayColTypes.ENEMY;
	if collision.is_in_group("Obstacle"):
		return rayColTypes.OBSTACLE;
	if collision.is_in_group("WorldWall"):
		return rayColTypes.WALL;
	if collision.is_in_group("World"):
		return rayColTypes.FLOOR;
	return rayColTypes.NONE;
