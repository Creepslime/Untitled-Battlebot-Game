extends Label3D

class_name Flyaway
## A bit of text spawned in 3D space that floats up into the air and fades away after spawning.

var timeBeforeFade := 1.8;
var timeBeforeDeath := 2.0;
var timer := 0.0;
var initPosY := 0.0;

func _process(delta):
	timer += delta;
	global_position.y = initPosY + (timer / 2);
	
	if timer > timeBeforeDeath:
		queue_free();
		return;
	
	if timeBeforeDeath > timeBeforeFade:
		if timer > timeBeforeFade:
			var timeDif = timeBeforeDeath - timeBeforeFade;
			var timeFaded = timer - timeBeforeFade;
			var completion = timeFaded / timeDif;
			transparency = completion;
	pass;

func _ready():
	font_size = 8;
	outline_size = 2;
	billboard = BaseMaterial3D.BILLBOARD_ENABLED;
	fixed_size = true;
