@icon("res://graphics/images/class_icons/robotStatAdjuster.png")
extends TabContainer

class_name StatAdjusterDataPanel
## Sets stats based on values written in [StatAdjusterNumber] and [StatAdjusterText] nodes.
##
## When any of [member allStats] gets changed, they notify this and [member currentThing] has its variables adjusted accordingly.

@export var allStats : Array[Control] = []
var currentThing : Node;

func _ready():
	for stat in allStats:
		if stat is StatAdjusterNumber or stat is StatAdjusterText or stat is StatAdjusterBoolean:
			stat.manager = self;


func assign_new_thing(newThing : Node):
	currentThing = newThing;
	for stat in allStats:
		if stat is StatAdjusterNumber:
			if currentThing.get(stat.name) != null:
				stat.value = currentThing.get(stat.name);
		if stat is StatAdjusterText:
			if currentThing.get(stat.name) != null:
				stat.text = currentThing.get(stat.name);
		if stat is StatAdjusterBoolean:
			if currentThing.get(stat.name) != null:
				stat.button_pressed = currentThing.get(stat.name);

func adjust_stat_number(stat:StatAdjusterNumber):
	if is_instance_valid(currentThing):
		if currentThing.get(stat.name) != null:
			currentThing.set(stat.name, stat.value);

func adjust_stat_text(stat:StatAdjusterText):
	if is_instance_valid(currentThing):
		if currentThing.get(stat.name) != null:
			currentThing.set(stat.name, stat.text);

func adjust_stat_bool(stat:StatAdjusterBoolean,value):
	if is_instance_valid(currentThing):
		if currentThing.get(stat.name) != null:
			currentThing.set(stat.name, value);
