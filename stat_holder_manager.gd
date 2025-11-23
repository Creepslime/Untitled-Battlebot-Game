@icon("res://graphics/images/class_icons/statHolderManager.png")
extends Node
## The global node keeping track of all [StatHolder3D] and (TODO)[StatHolder2D] nodes.

var all_stat_holders : Dictionary[int, Node] = {}

var statHolderID := 0;

var freeIDS : Array[int]; ## An array of IDs that are no longer being used.

func get_unique_stat_holder_id() -> int:
	clear_invalid_stat_holders();
	if freeIDS.is_empty():
		var ret = statHolderID;
		statHolderID += 1;
		return ret;
	else:
		var ret = freeIDS.pop_front();
		return ret;

func register_stat_holder(object):
	clear_invalid_stat_holders();
	##Todo: Add StatHolder2D as a class for Parts to inherit from.
	if object is StatHolder3D:
		all_stat_holders[object.statHolderID] = object;
		print("Added ",object," as a StatHolder with ID ", object.statHolderID)
	#elif object is StatHolder2D:
		#pass;

## Clear out any invalid entries in the list and frees them up.
func clear_invalid_stat_holders():
	var idsToFree = []
	for id in all_stat_holders.keys():
		var holder = all_stat_holders[id];
		if !is_instance_valid(holder):
			idsToFree.append(id);
			pass;
	for id in idsToFree:
		AbilityDistributor.remove_id_from_abilities(id);
		all_stat_holders.erase(id);
		freeIDS.append(id)

func get_stat_holder_by_id(id):
	clear_invalid_stat_holders();
	if all_stat_holders.keys().has(id):
		return all_stat_holders[id];
	return null;

### Vanity stuff.

@onready var statIconDefault = preload("res://graphics/images/HUD/statIcons/defaultIconStriped.png");
@onready var statIconCooldown = preload("res://graphics/images/HUD/statIcons/cooldownIconStriped.png");
@onready var statIconMagazine = preload("res://graphics/images/HUD/statIcons/magazineIconStriped.png");
@onready var statIconEnergy = preload("res://graphics/images/HUD/statIcons/energyIconStriped.png");
@onready var statIconDamage = preload("res://graphics/images/HUD/statIcons/damageIconStriped.png");
@onready var statIconWeight = preload("res://graphics/images/HUD/statIcons/weightIconStriped.png");
@onready var statIconScrap = preload("res://graphics/images/HUD/statIcons/scrapIconStriped.png");
@onready var statIconMove = preload("res://graphics/images/HUD/statIcons/moveIconStriped.png");
@onready var statIconPiece = preload("res://graphics/images/HUD/statIcons/pieceIconStriped.png");
@onready var statIconPart = preload("res://graphics/images/HUD/statIcons/partIconStriped.png");
@onready var statIconPiecePart = preload("res://graphics/images/HUD/statIcons/piecePartIconStriped.png");

@onready var statIconColorDict = {
	"Default" : {"icon" = statIconDefault, "color" = "grey"},
	"Cooldown" : {"icon" = statIconCooldown, "color" = "lightgreen"},
	"Magazine" : {"icon" = statIconMagazine, "color" = "lightblue"},
	"Energy" : {"icon" = statIconEnergy, "color" = "lightblue"},
	"Damage" : {"icon" = statIconDamage, "color" = "lightred"},
	"Weight" : {"icon" = statIconWeight, "color" = "grey"},
	"Move" : {"icon" = statIconMove, "color" = "lightgreen"},
	"Scrap" : {"icon" = statIconScrap, "color" = "scrap"},
	"Piece" : {"icon" = statIconPiece, "color" = "orange"},
	"Part" : {"icon" = statIconPart, "color" = "lightgreen"},
	"PiecePart" : {"icon" = statIconPiecePart, "color" = "scrap"},
}

func get_stat_icon(statIconName : String = "Default") -> Texture2D:
	if statIconColorDict.has(statIconName.capitalize()):
		return statIconColorDict[statIconName.capitalize()].icon;
	else:
		return statIconColorDict["Default"].icon;
func get_stat_color(statIconName : String = "Default") -> Color:
	var color
	if statIconColorDict.has(statIconName.capitalize()):
		color = statIconColorDict[statIconName.capitalize()].color;
	else:
		color = statIconColorDict["Default"].color;
	return TextFunc.get_color(color);
func get_stat_color_from_image(statIcon : Texture2D):
	for statIconName in statIconColorDict:
		var statIconData = statIconColorDict[statIconName];
		if statIconData.icon == statIcon:
			return get_stat_color(statIconName);
	return get_stat_color();
