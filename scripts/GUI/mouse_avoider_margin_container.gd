extends MarginContainer
@export var thingsToMove : Array[Control];

func _ready():
	for thingToMove in thingsToMove:
		#if ! thingToMove.is_connected("mouse_entered",switch_sides):
			#thingToMove.connect("mouse_entered",switch_sides);
		if ! thingToMove.is_connected("mouse_entered",fade_out):
			thingToMove.connect("mouse_entered",fade_out);
		if ! thingToMove.is_connected("mouse_exited",fade_in):
			thingToMove.connect("mouse_exited",fade_in);

var switchTimer := 0.0;
var hasSwitched := false;
func _process(delta):
	var modBefore = modulate.a;
	modulate.a = move_toward(modulate.a, targetMod, delta);
	var modAfter = modulate.a;

func switch_sides():
	hasSwitched = true;
	if is_layout_rtl():
		layout_direction = Control.LAYOUT_DIRECTION_LTR;
	else:
		layout_direction = Control.LAYOUT_DIRECTION_RTL;

const fadeOutMod = 0.2
const fadeInMod = 1.0
var targetMod = fadeInMod;
func fade_in():
	hasSwitched = false;
	targetMod = fadeInMod;
func fade_out():
	hasSwitched = false;
	targetMod = fadeOutMod;
