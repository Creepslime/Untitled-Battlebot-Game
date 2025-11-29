@icon("res://graphics/images/class_icons/partButton_selected.png")
extends TextureButton

class_name PartButton

var part : Part;
var buttonHolder : Control;
var ID := -1;
var selectGFXon = false;
var mouseOver = false;
var mouseOverTimer = 0.0;
var signalsRepressed := false:
	get:
		signalsRepressed = signalsRepresedFrames > 0;
		return signalsRepressed;
var signalsRepresedFrames := 0;

var selected = false;
var moveMode = false;

@export var GFX_move := preload("res://graphics/images/HUD/parts/PartMoving.png")
@export var GFX_normal := preload("res://graphics/images/HUD/parts/PartSelected.png")

func _process(delta):
	if signalsRepresedFrames > 0:
		set_pressed_no_signal(selected);
		signalsRepresedFrames -= 1;
	#self_modulate = (Color(0, 0, 0, 0))
	#visible = selectGFXon;
	##If the player clicks and holds the thing for 0.5 seconds, move mode is enabled
	
	if not disabled:
		if mouseOver:
			if part.ownedByPlayer and Input.is_action_pressed("Select"):
				button_pressed = true;
				mouseOverTimer += delta;
				if mouseOverTimer >= 0.5:
					part.robot_move_mode(true);
			else:
				mouseOverTimer = 0.0;
		else:
			#if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				#button_pressed = false;
			mouseOverTimer = 0.0;
	pass

func _on_mouse_entered():
	mouseOver = true;
	pass # Replace with function body.


func _on_mouse_exited():
	mouseOver = false;
	pass # Replace with function body.


func _on_pressed():
	pass # Replace with function body.

func select(foo:bool):
	signalsRepresedFrames = 5;
	selected = foo;
	if !foo:
		move_mode(foo, false)

func move_mode(foo:bool, _select := true):
	if _select:
		select(foo);
	
	moveMode = foo;
	if foo:
		set("texture_pressed", GFX_move);
	else:
		set("texture_pressed", GFX_normal);

func _on_toggled(toggled_on):
	if ! signalsRepressed:
		#print(str("Part button %s toggled unrepressed" % [ID]))
		buttonHolder.set_pressed(toggled_on);
	pass # Replace with function body.
