extends TextureButton

class_name PartButton

var part : Part;
var buttonHolder : Control;
var selectGFXon = false;
var mouseOver = false;
var mouseOverTimer = 0.0;
var signalsRepressed := false;
var signalsRepresedFrames := 0;

func _process(delta):
	if signalsRepresedFrames > 0:
		signalsRepresedFrames -= 1;
		signalsRepressed = true;
	else:
		signalsRepressed = false;
	#self_modulate = (Color(0, 0, 0, 0))
	#visible = selectGFXon;
	##If the player clicks and holds the thing for 0.5 seconds, move mode is enabled
	
	if not disabled:
		if mouseOver:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				button_pressed = true;
				if part.ownedByPlayer:
					mouseOverTimer += delta;
					if mouseOverTimer >= 0.5 && is_instance_valid(part.thisRobot):
						part.thisRobot.part_move_mode_enable(self, true);
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
	set_pressed_no_signal(foo);

func _on_toggled(toggled_on):
	if ! signalsRepressed:
		buttonHolder.set_pressed(toggled_on);
	pass # Replace with function body.
