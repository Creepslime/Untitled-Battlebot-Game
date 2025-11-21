extends ScrapLabel
class_name ScrapLabel_Player
## Provides a display for a scrap amount.

var forcedUpdatetimer := 6;

func _ready():
	Hooks.add(self, "OnGainScrap", "HUD Scrap Label", hook_update);

func _process(delta):
	forcedUpdatetimer -= 1;
	if forcedUpdatetimer <= 0:
		update_amt(min(999999, ScrapManager.get_scrap()));
		forcedUpdatetimer = 6;
	super(delta);

func hook_update(_source, _amount):
	update_amt(min(999999, ScrapManager.get_scrap()));

func update_label():
	super();
	
	if actualAmount >= 999999:
		TextFunc.set_text_color(self, "scrap");
	else:
		TextFunc.set_text_color(self, "white");
