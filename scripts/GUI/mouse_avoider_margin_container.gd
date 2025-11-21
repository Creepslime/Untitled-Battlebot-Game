extends MarginContainer
@export var thingsToMove : Array[Control];

func _ready():
	for thingToMove in thingsToMove:
		if ! thingToMove.is_connected("mouse_entered",switch_sides):
			thingToMove.connect("mouse_entered",switch_sides);

func switch_sides():
	if is_layout_rtl():
		layout_direction = Control.LAYOUT_DIRECTION_LTR;
	else:
		layout_direction = Control.LAYOUT_DIRECTION_RTL;
