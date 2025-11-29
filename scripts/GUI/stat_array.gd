@icon ("res://graphics/images/class_icons/statArray.png")
extends Control
class_name StatArrayDisplay

@export var lbl_tag : Label;
@export var statHolder : HFlowContainer;
@export var statTag := StatHolderManager.statTags.INVALID;
@export var statIcon := preload("res://scenes/prefabs/objects/gui/stat_icon.tscn");

#func _ready():
	#for stat in statHolder.get_children():
		#if stat is InspectorStatIcon:
			#stat.queue_free();

func add_stat_icon(stat:StatTracker):
	var newIcon : InspectorStatIcon = statIcon.instantiate();
	newIcon.load_data_from_statTracker(stat);
	statHolder.add_child(newIcon);
	if statTag == StatHolderManager.statTags.INVALID:
		statTag = stat.statTag;
	recalc_height();

const labelSpace := 5;
const spaceAfterList := 2;
const vMargin := 3;
var calculatedHeight = 0.;
func recalc_height():
	lbl_tag.text = str(StatHolderManager.statTags.keys()[statTag]);
	var statNum = 0;
	var statsHeight = 39 - statHolder.get("theme_override_constants/v_separation");
	for stat in statHolder.get_children():
		statNum += 1;
		if statNum > 9:
			statNum -= 9;
			statsHeight += 39 - statHolder.get("theme_override_constants/v_separation");
	statHolder.size.y = statsHeight;
	
	custom_minimum_size.y = labelSpace + spaceAfterList + statsHeight;
	size.y = labelSpace + spaceAfterList + statsHeight;
	
	calculatedHeight = size.y;
	
	#print(size.y)
	
	return calculatedHeight;
