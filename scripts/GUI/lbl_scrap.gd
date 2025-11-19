extends Label
class_name ScrapLabel

@export var zeroesBG : Label;
var forcedUpdatetimer := 0;

func _ready():
	Hooks.add(self, "OnGainScrap", "HUD Scrap Label", hook_update);

func _process(delta):
	forcedUpdatetimer -= 1;
	if forcedUpdatetimer <= 0:
		update_label();
		forcedUpdatetimer = 6;

func hook_update(source, amount):
	update_label();

func update_label():
	var amt = min(999999, ScrapManager.get_scrap())
	text = str(amt);
	#zeroesBG = text.
	var zeroes = 6 - text.length();
	var zeroesText = "";
	if zeroes > 0:
		for i in zeroes:
			zeroesText += "0";
	zeroesBG.text = zeroesText;
	if amt >= 999999:
		TextFunc.set_text_color(self, "scrap");
	else:
		TextFunc.set_text_color(self, "white");
