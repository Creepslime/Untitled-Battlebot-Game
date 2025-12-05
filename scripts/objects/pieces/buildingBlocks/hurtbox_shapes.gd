@icon ("res://graphics/images/class_icons/shield.png")
extends Area3D

class_name HurtboxHolder

## Collision layers.
const layerFlags : Dictionary[int, bool] = {
	1 : false, ## This is NOT a robot body.
	4 : true, ## This is a Piece hurtbox.
}
## Collision mask.
const maskFlags : Dictionary[int, bool] = {
	1 : false, ## DON'T collide with robot bodies.
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

func get_piece() -> Piece:
	var parent = get_parent();
	if parent is Piece:
		return parent;
	return null;

func select_piece():
	var piece = get_piece();
	if piece != null:
		piece.select_via_robot();
