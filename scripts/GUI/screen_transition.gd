@icon("res://graphics/images/class_icons/screenTransition.png")
extends Control
class_name ScreenTransition;

enum mode {
	CENTER,
	LEFT,
	RIGHT,
}
@export var curMode := mode.CENTER;
var primeASignal := false;

const leftPos := -2184.0;
const rightPos := 2184.0;
const centerPos := 0.0;

func _ready():
	connect("hitCenter", _on_hit_center);
	connect("hitRight", _on_hit_right);

func comeIn():
	show();
	bring_to_left(true, false);
	set_deferred("curMode", mode.CENTER);

func leave():
	if !is_on_right():
		set_deferred("curMode", mode.RIGHT);

signal hitCenter()
signal hitRight()

var leftTimer := -1.;
var lerpedPosXValue := 0.0;
func _process(delta):
	match curMode:
		mode.LEFT:
			visible = false;
			position.x = leftPos;
		mode.CENTER:
			visible = true;
			lerpedPosXValue = lerp(lerpedPosXValue, centerPos, 14 * delta);
		mode.RIGHT:
			visible = true;
			if is_on_right():
				if leftTimer == -1: ## if it was at -1 (reset value), set to 1.
					leftTimer = 1.0 + delta;
				if leftTimer > 0:
					leftTimer -= delta;
				if leftTimer < 0:
					leftTimer = -1;
					bring_to_left(false, true);
			lerpedPosXValue = lerp(lerpedPosXValue, rightPos, 14 * delta);
	position.x = roundi(lerpedPosXValue);



func _on_hit_center():
	primeASignal = false;
	pass # Replace with function body.

func _on_hit_right():
	primeASignal = false;
	pass # Replace with function body.

func bring_to_left(goToPosition := true, changeMode := true):
	if goToPosition:
		position.x = leftPos;
	if changeMode:
		set_deferred("curMode", mode.LEFT);
func bring_to_center(goToPosition := true, changeMode := true):
	if goToPosition:
		position.x = centerPos;
	if changeMode:
		set_deferred("curMode", mode.CENTER);
func bring_to_right(goToPosition := true, changeMode := true):
	if goToPosition:
		position.x = rightPos;
	if changeMode:
		set_deferred("curMode", mode.RIGHT);

func is_on_left():
	return is_equal_approx(position.x, leftPos);
func is_greater_than_left():
	return position.x > leftPos;
func is_on_center():
	return is_equal_approx(position.x, centerPos);
func is_greater_than_center():
	return position.x > centerPos;
func is_on_right():
	return position.x >= rightPos or is_equal_approx(position.x, rightPos);
