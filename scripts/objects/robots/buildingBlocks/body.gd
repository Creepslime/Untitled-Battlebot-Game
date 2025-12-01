@icon("res://graphics/images/class_icons/robot_body.png")
extends RigidBody3D

class_name RobotBody

var targetPoint := Vector2(0.0, 1.0);
var targetRotation := 0.0;
var currentRotation := 0.0;
var lastRotation := 0.0;
var isOnGround := false;
var robot : Robot;
var maxSpeed := 0.0;

func _ready():
	targetRotation = global_rotation.y;
	currentRotation = global_rotation.y;
	
	set_collision_layer_value(1, true);
	set_collision_layer_value(11, false);
	set_collision_mask_value(1, true);
	set_collision_mask_value(11, true);

func update_target_rotation(inRotPoint, rotationSpeed):
	if targetPoint != inRotPoint:
		targetPoint = inRotPoint;
		targetRotation = targetPoint.angle();
	if ! is_equal_approx(currentRotation, targetRotation):
		## Save the last rotation.
		lastRotation = currentRotation;
		rotationSpeed = clamp(rotationSpeed, 0.0, 1.0);
		currentRotation = lerp_angle(currentRotation, targetRotation, rotationSpeed);
		_integrate_forces("Rotation");

func clamp_speed():
	_integrate_forces("Speed Clamp");

func _integrate_forces(state):
	GameState.profiler_time_msec_start("robot phys_process_motion 8: Body integrate forces")
	match state:
		"Rotation":
			rotation.y = currentRotation;
		"Speed Clamp":
			var current_velocity = Utils.vec3_to_vec2(linear_velocity);
			var current_speed = current_velocity.length();
			
			if current_speed > maxSpeed:
				var y = linear_velocity.y;
				var cvFIxd = current_velocity.normalized() * maxSpeed;
				linear_velocity.x = lerp(linear_velocity.x, cvFIxd.x, 0.85);
				linear_velocity.z = lerp(linear_velocity.z, cvFIxd.y, 0.85);
			#print(global_position.y);
			if ! isOnGround:
				var force = max(1.0, (global_position.y / 2) + 0.5)	
				gravity_scale = max(1.0, force);
				Utils.print_if_true(str("force: ",gravity_scale),get_robot() is Robot_Player)
				linear_velocity.y = min(linear_velocity.y - force, linear_velocity.y)
			else:
				gravity_scale = 1.0;
			#print(constant_force.y)
		_:
			pass;
	#print("Applying current rotation:",currentRotation)
	basis = basis.orthonormalized();
	GameState.profiler_time_msec_end("robot phys_process_motion 8: Body integrate forces")

func get_robot() -> Robot:
	return get_parent();
