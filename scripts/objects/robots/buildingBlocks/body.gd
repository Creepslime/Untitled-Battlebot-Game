@icon("res://graphics/images/class_icons/robot_body.png")
extends RigidBody3D

class_name RobotBody

var targetPoint := Vector2(0.0, 1.0);
var targetRotation := 0.0;
var currentRotation := 0.0;

func _ready():
	targetRotation = global_rotation.y;
	currentRotation = global_rotation.y;

func update_target_rotation(inRot, rotationSpeed):
	rotationSpeed = clamp(rotationSpeed, 0.0, 1.0);
	targetPoint = inRot;
	targetRotation = targetPoint.angle();
	currentRotation = lerp_angle(currentRotation, targetRotation, rotationSpeed);
	_integrate_forces("Rotation");

func clamp_speed():
	_integrate_forces("Speed Clamp");

func _integrate_forces(state):
	set_collision_layer_value(1, true);
	set_collision_layer_value(11, false);
	set_collision_mask_value(1, true);
	set_collision_mask_value(11, true);
	match state:
		"Rotation":
			rotation.y = currentRotation;
		"Speed Clamp":
			var max_speed = get_parent().get_stat("MovementSpeedMax");
			var current_velocity = Vector2(linear_velocity.x, linear_velocity.z);
			var current_speed = current_velocity.length();

			if current_speed > max_speed:
				var y = linear_velocity.y;
				var cvFIxd = current_velocity.normalized() * max_speed;
				linear_velocity.x = lerp(linear_velocity.x, cvFIxd.x, 0.85);
				linear_velocity.z = lerp(linear_velocity.z, cvFIxd.y, 0.85);
			#print(global_position.y);
			if global_position.y > 3:
				var force = -(global_position.y) + 3
				constant_force.y = min(force, move_toward(constant_force.y, global_position.y, 0.08 * force));
				Utils.print_if_true(str("force: ",constant_force.y),get_robot() is Robot_Player)
			else:
				if global_position.y < 1:
					constant_force.y = 0;
			#print(constant_force.y)
		_:
			pass;
	#print("Applying current rotation:",currentRotation)
	basis = basis.orthonormalized();

func get_robot() -> Robot:
	return get_parent();
