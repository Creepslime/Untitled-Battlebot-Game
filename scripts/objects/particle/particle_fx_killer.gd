@icon ("res://graphics/images/class_icons/particleEffect.png")
extends Node3D

class_name ParticleEffect
## A node which holds a series of [GPUParticles3D]. When they're all done firing, this node deletes itself.

var checkTimer := 1.0;
var nodeToFollow : Node3D;
var posOffset : Vector3;
@export var forceFireOnce := false;
var dying = false;
var queueFreeTimer := 2.0;


func _ready():
	emit();

func emit():
	for child in get_children():
		if child is GPUParticles3D:
			child.emitting = true;
			if forceFireOnce:
				child.one_shot = true;

func _process(delta):
	if is_instance_valid(nodeToFollow):
		if nodeToFollow.is_inside_tree():
			if nodeToFollow.is_visible_in_tree():
				global_position = nodeToFollow.global_position + posOffset;
				rotation = nodeToFollow.rotation;
		else:
			start_free();
	
	if checkTimer > 0:
		checkTimer -= delta;
	else:
		check_emitting();
		checkTimer = 1.0;
	
	
	if dying:
		queueFreeTimer -= delta;
		if queueFreeTimer < 0:
			queue_free();

func check_emitting():
	for child in get_children():
		if child is GPUParticles3D:
			if child.emitting:
				return;
	
	start_free();

func start_free():
	dying = true;

## Changes which layer mask the particles appear on.
func set_visibility_layer(num:int):
	for child in get_children():
		if child is GPUParticles3D:
			child.layers = 0;
			child.set_layer_mask_value(num, true);
