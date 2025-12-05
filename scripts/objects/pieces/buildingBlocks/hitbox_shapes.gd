@icon ("res://graphics/images/class_icons/sword.png")
extends Area3D

class_name HitboxHolder
## Holds all the collision required for hitting stuff with melee attacks from a [Piece].

## Collision layers.
const layerFlags : Dictionary[int, bool] = {
	1 : false, ## This is NOT a robot body.
	5 : true, ## This is a hitbox.
}
## Collision mask.
const maskFlags : Dictionary[int, bool] = {
	1 : false, ## DON'T collide with robot bodies.
	4 : true, ## Collide with Piece hurtboxes,
	7 : true, ## Collide with *placed* Piece hurtboxes.
	10: true, ## Collide with bullets.
}

func _ready():
	collision_layer = 0;
	collision_mask = 0;
	for layerNum in layerFlags:
		var layerVal = layerFlags[layerNum];
		set_collision_layer_value(layerNum, layerVal);
	for maskNum in maskFlags:
		var maskVal = maskFlags[maskNum];
		set_collision_mask_value(maskNum, maskVal);
