@icon ("res://graphics/images/class_icons/tread_2.png")
extends Node3D

class_name UnderbellyContactPoints

@export var underbellyCollider : ContactPoint;
@export var rightTread : TreadContactPoints;
@export var leftTread : TreadContactPoints;
@export var mesh_leftTread : MeshInstance3D;
@export var mesh_rightTread : MeshInstance3D;
@export var pivot_left : Node3D;
@export var pivot_right : Node3D;

var onFloor := false;
var onDriveable := false;

func full_status_report(centerOnly:=false):
	onFloor = is_on_floor(centerOnly);
	onDriveable = is_on_driveable(centerOnly);
	return {"right":rightTread.status_report(), "left":leftTread.status_report(), "center":underbellyCollider.status_report(), "onFloor":onFloor, "onDriveable":onDriveable};

func is_on_floor(centerOnly:=false):
	if centerOnly:
		return underbellyCollider.is_on_floor();
	else:
		return rightTread.is_on_floor() or leftTread.is_on_floor() or underbellyCollider.is_on_floor();

func is_on_driveable(centerOnly:=false):
	if centerOnly:
		return underbellyCollider.is_on_something_driveable();
	else:
		return (rightTread.is_on_something_driveable() or leftTread.is_on_something_driveable()) and underbellyCollider.is_on_something_driveable();

##gets the vector that the contact of the treads is returning.
func get_tread_contact_vector():
	var left = leftTread.get_driveable_contact_axis();
	var right = rightTread.get_driveable_contact_axis();
	var x = 0;
	var y = 0;
	if right != null and left != null:
		x = 0;
		y = right + left;
	else:
		if left == null:
			x += 1;
		else:
			y += left;
		if right == null:
			x -= 1;
		else: 
			y += right;
	return Vector2(x, y);

func get_tread_normal() -> Vector3:
	if rightTread.is_on_something_driveable() && leftTread.is_on_something_driveable():
		var normF := rightTread.get_tread_normal();
		var normB := leftTread.get_tread_normal();
		return ((normF + normB) / 2).normalized();
	elif rightTread.is_on_something_driveable() and not leftTread.is_on_something_driveable():
		var normB := rightTread.get_tread_normal();
		return (normB).normalized();
	elif leftTread.is_on_something_driveable() and not rightTread.is_on_something_driveable():
		var normF := leftTread.get_tread_normal();
		return (normF).normalized();
	else:
		return Vector3.ZERO;

var targetPivotRotation := 0.0;
var targetPivotDisplacement := 0.0;
var bodSpeedLength := 0;
func update_visuals_to_match_rotation(angleDifferenceThisFrame, _bodSpeedLength):
	#if rad_to_deg(angleDifferenceThisFrame) 
	#targetPivotDisplacement = (angleDifferenceThisFrame * 10);
	targetPivotRotation = clamp((angleDifferenceThisFrame * 10) + deg_to_rad(90), deg_to_rad(90-50), deg_to_rad(90+50));
	#print(bodSpeedLength)
	#print(rad_to_deg(targetPivotRotation))
	bodSpeedLength = _bodSpeedLength;
	
	pass;

func _physics_process(delta):
	if is_instance_valid(pivot_left) and is_instance_valid(pivot_right):
		pivot_left.rotation.y = lerp_angle(pivot_left.rotation.y, targetPivotRotation, delta * (10.0 + (bodSpeedLength / 5)));
		pivot_right.rotation.y = lerp_angle(pivot_right.rotation.y, targetPivotRotation, delta * (10.0 + (bodSpeedLength / 5)));
	if is_instance_valid(leftTread) and is_instance_valid(rightTread):
		call_for_dust(bodSpeedLength * delta);

var dustTimerL := 0.0; 
var dustTimerR := 0.0;
var maxDustTimer := 2.;
var minDustTimer := 1.;
func call_for_dust(speed):
	dustTimerL -= speed;
	dustTimerR -= speed;
	if dustTimerL <= 0.0:
		dustTimerL += randf_range(maxDustTimer, minDustTimer);
		leftTread.dust_particle();
	if dustTimerR <= 0.0:
		dustTimerR += randf_range(maxDustTimer, minDustTimer);
		rightTread.dust_particle();
