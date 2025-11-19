extends Label
class_name ScrapLabel
## Provides a display for a scrap amount.

@export var zeroesBG : Label;

func _ready():
	if ! is_instance_valid(zeroesBG):
		if is_instance_valid($BG_zeroes):
			zeroesBG = $BG_zeroes;
		else:
			queue_free();

func update_label(amt := 0):
	if amt < 0:
		text = ""
		zeroesBG.text = "000000"
	else:
		text = str(amt);
		#zeroesBG = text.
		var zeroes = 6 - text.length();
		var zeroesText = "";
		if zeroes > 0:
			for i in zeroes:
				zeroesText += "0";
		zeroesBG.text = zeroesText;
