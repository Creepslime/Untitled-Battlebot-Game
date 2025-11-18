extends Label
class_name HealthRefreshLabel

var timer = 0.0;
var valueLastFrame := 0.0;
@export var statName := "Health"
@export var decimalPlaces := 2;
var bot : Robot;
enum updateModes {
	EVERY_FRAME,
	HALF_SECOND,
	SECOND,
}
@export var curMode := updateModes.EVERY_FRAME;

func _ready():
	self_modulate.a = 0;

func ping(damage:float):
	if is_zero_approx(damage): return;
	var damageStr = "";
	var color = "grey";
	var change = TextFunc.format_stat(abs(damage), decimalPlaces);
	if damage > 0:
		color = "unaffordable";
		damageStr = "-" + change;
	elif damage < 0: 
		color = "utility";
		damageStr = "+" + change;
	
	timer = 1.0;
	text = damageStr;
	TextFunc.set_text_color(self, color);

var changeAccrued := 0.0;
var updateTimer := 0;
func _process(delta):
	var getBot = GameState.get_player();
	if is_instance_valid(getBot):
		bot = getBot;
		var stat = bot.get_stat(statName);
		var statDif = valueLastFrame - stat;
		changeAccrued += statDif;
		valueLastFrame = stat;
	
	updateTimer -= 1;
	if updateTimer <= 0:
		if curMode == updateModes.SECOND:
			updateTimer = 60;
		elif curMode == updateModes.HALF_SECOND:
			updateTimer = 30;
		else:
			updateTimer = 1;
		
		if ! is_zero_approx(changeAccrued):
			ping(changeAccrued);
		changeAccrued  = 0;
	#print(timer)
	if timer > 0:
		timer -= delta;
		self_modulate.a = 1;
	else:
		self_modulate.a = move_toward(self_modulate.a, 0.0, delta);
