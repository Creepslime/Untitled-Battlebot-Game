@icon ("res://graphics/images/class_icons/tread_arrow.png")
extends RayCast3D

class_name ContactPoint

func _ready():
	set_collision_mask_value(1, true);
	set_collision_mask_value(11, true);

func is_on_floor():
	if is_colliding():
		var col = get_collider();
		if is_instance_valid(col):
			if col.is_in_group("WorldFloor"):
				return true;
	return false;

func is_on_something_driveable():
	if is_colliding():
		var col = get_collider();
		if is_instance_valid(col):
			if col.is_in_group("Driveable") or col.is_in_group("WorldFloor") or col.is_in_group("WorldWall"):
				return true;
	return false;

func get_collider_normal() -> Vector3:
	if is_colliding():
		return get_collision_normal();
	return Vector3(0,0,0);

func status_report():
	return {"onFloor":is_on_floor(), "onDriveable":is_on_something_driveable(), "normal":get_collider_normal()};
