@icon ("res://graphics/images/class_icons/heart_green.png")
extends Control

class_name InspectorStatIcon
## Displays a [StatTracker] and what its [method StatTracker.get_stat] value was upon the initialization of this node.

@export var textureIcon : TextureRect;
@export var lbl_amt : Label;
var stat : StatTracker
var amt := 0.0;

func load_data_from_statTracker(_stat: StatTracker):
	if is_instance_valid(_stat):
		stat = _stat;
		textureIcon.texture = stat.statIcon;
		name = stat.statFriendlyName.capitalize();
		update_stat_num();
		TextFunc.set_text_color(lbl_amt, stat.textColor);

var updateTimer := 30;
func _process(delta):
	if updateTimer > 0:
		updateTimer -= 1;
	if updateTimer == 0:
		update_stat_num();
		updateTimer += 30;

func update_stat_num():
	if is_instance_valid(stat):
		var statText = TextFunc.format_stat(stat.get_stat_for_display(), 2, false)
		lbl_amt.text = statText;
		
		var tooltipText = stat.statFriendlyName.capitalize() + str("\n",statText);
		tooltipText += "\nModifier: %s"%stat.bonusAdd if stat.bonusAdd > 0 else ""
		tooltipText += "\nFlat mult: %s"%stat.bonusMult_Flat if stat.bonusMult_Flat > 0 else ""
		tooltipText += "\nTimes mult: %s"%stat.bonusMult_Mult if stat.bonusMult_Mult != 1.0 else ""
		tooltipText += str("\n",stat.statModifiers);
		tooltip_text = tooltipText;

func mouse_entered():
	updateTimer = -1;
	update_stat_num();

func mouse_exited():
	updateTimer = 0;

func _on_mouse_entered():
	mouse_entered()
	pass # Replace with function body.

func _on_mouse_exited():
	mouse_exited()
	pass # Replace with function body.

func _on_icon_mouse_entered():
	mouse_entered()
	pass # Replace with function body.

func _on_icon_mouse_exited():
	mouse_exited()
	pass # Replace with function body.

func _on_amt_mouse_entered():
	mouse_entered()
	pass # Replace with function body.

func _on_amt_mouse_exited():
	mouse_exited()
	pass # Replace with function body.
