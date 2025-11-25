@icon ("res://graphics/images/class_icons/energy_green.png")
extends Control

class_name InspectorStatIcon
## Displays a [StatTracker] and what its [method StatTracker.get_stat] value was upon the initialization of this node.

@export var textureIcon : TextureRect;
@export var lbl_amt : Label;
var stat : StatTracker

func load_data_from_statTracker(_stat: StatTracker):
	if is_instance_valid(_stat):
		stat = _stat;
		textureIcon.texture = stat.statIcon;
		var statText = TextFunc.format_stat(stat.get_stat(), 2, false)
		tooltip_text = stat.statFriendlyName.capitalize() + str("\n",statText);
		name = stat.statFriendlyName.capitalize();
		lbl_amt.text = statText;
		TextFunc.set_text_color(lbl_amt, stat.textColor);
