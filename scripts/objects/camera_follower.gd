extends Camera

class_name FollowerCamera

@export var camToFollow : Camera;
@export var extraOffset := Vector2.ZERO;

func _process(_delta):
	global_position = camToFollow.global_position
	global_rotation = camToFollow.global_rotation
	h_offset = camToFollow.h_offset + extraOffset.x;
	v_offset = camToFollow.v_offset + extraOffset.y;
	fov = camToFollow.fov;

func switch_cameras(newCam : Camera):
	camToFollow = newCam;
