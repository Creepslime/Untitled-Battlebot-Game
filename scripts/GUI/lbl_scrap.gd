extends Label
class_name ScrapLabel
## Provides a display for a scrap amount.

@export var zeroesBG : Label;
var actualAmount := 0;
var displayedAmount := 0.0;

func _ready():
	if ! is_instance_valid(zeroesBG):
		if is_instance_valid($BG_zeroes):
			zeroesBG = $BG_zeroes;
		else:
			queue_free();

func _process(delta):
	displayedAmount = lerp(displayedAmount, float(actualAmount), delta * 25);
	update_label();

func update_label():
	#print(actualAmount)
	if roundi(displayedAmount) < 0:
		text = ""
		zeroesBG.text = "000000"
	else:
		text = str(roundi(displayedAmount));
		#zeroesBG = text.
		var zeroes = 6 - text.length();
		var zeroesText = "";
		if zeroes > 0:
			for i in zeroes:
				zeroesText += "0";
		zeroesBG.text = zeroesText;

func update_amt(amt := 0):
	actualAmount = amt;
