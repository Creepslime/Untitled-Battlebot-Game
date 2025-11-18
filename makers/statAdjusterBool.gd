@icon("res://graphics/images/class_icons/statEditNumber.png")
extends CheckBox
class_name StatAdjusterBoolean
## Interfaces with [StatAdjusterDataPanel]. The variable name being changed is placed within [member suffix].

var manager : StatAdjusterDataPanel;

func _ready():
	name = text;
	if not is_connected("toggled", _on_value_changed):
		connect("toggled", _on_value_changed);

func _on_value_changed(value : bool):
	manager.adjust_stat_bool(self, value);
	pass # Replace with function body.
