@icon("res://graphics/images/class_icons/statHolderManager.png")
extends Node
## The global node keeping track of all [StatHolder3D] and (TODO)[StatHolder2D] nodes.

var all_stat_holders : Dictionary[int, Node] = {}

var statHolderID := 0;

var freeIDS : Array[int]; ## An array of IDs that are no longer being used.

func get_unique_stat_holder_id() -> int:
	if freeIDS.is_empty():
		var ret = statHolderID;
		statHolderID += 1;
		return ret;
	else:
		var ret = freeIDS.pop_front();
		return ret;

func register_stat_holder(object):
	##Todo: Add StatHolder2D as a class for Parts to inherit from.
	if object is StatHolder3D:
		all_stat_holders[object.statHolderID] = object;

## @deprecated: Clear out any invalid entries in the list and frees them up. *Technically* not deprecated, but its use shouold be sparse.
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
	if all_stat_holders.keys().has(id):
		return all_stat_holders[id];
	else:
		all_stat_holders.erase(id);
		freeIDS.append(id);
	return null;

### Vanity stuff.

@onready var statIconDefault = preload("res://graphics/images/HUD/statIcons/defaultIconStriped.png");
@onready var statIconCooldown = preload("res://graphics/images/HUD/statIcons/cooldownIconStriped.png");
@onready var statIconMagazine = preload("res://graphics/images/HUD/statIcons/magazineIconStriped.png");
@onready var statIconHeart = preload("res://graphics/images/HUD/statIcons/heartIconStriped.png");
@onready var statIconEnergy = preload("res://graphics/images/HUD/statIcons/energyIconStriped.png");
@onready var statIconDamage = preload("res://graphics/images/HUD/statIcons/damageIconStriped.png");
@onready var statIconShield = preload("res://graphics/images/HUD/statIcons/shieldIconStriped.png");
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
	"Heart" : {"icon" = statIconHeart, "color" = "red"},
	"Energy" : {"icon" = statIconEnergy, "color" = "lightblue"},
	"Damage" : {"icon" = statIconDamage, "color" = "lightred"},
	"Shield" : {"icon" = statIconShield, "color" = "magenta"},
	"Weight" : {"icon" = statIconWeight, "color" = "grey"},
	"Move" : {"icon" = statIconMove, "color" = "lightgreen"},
	"Scrap" : {"icon" = statIconScrap, "color" = "scrap"},
	"Piece" : {"icon" = statIconPiece, "color" = "orange"},
	"Part" : {"icon" = statIconPart, "color" = "lightgreen"},
	"PiecePart" : {"icon" = statIconPiecePart, "color" = "scrap"},
}

enum roundingModes {
	None, ## No modifications to the number when getting it; it will remain an unrounded [float].
	Floor, ## Performs the [code]floor()[/code] function on the stat when getting it.
	Round, ## Performs the [code]round()[/code] function on the stat when getting it.
	Ceil, ## Performs the [code]ceil()[/code] function on the stat when getting it.
	Floori, ## Performs the [code]floori()[/code] function on the stat when getting it.
	Roundi, ## Performs the [code]roundi()[/code] function on the stat when getting it.
	Ceili, ## Performs the [code]ceili()[/code] function on the stat when getting it.
	NoOverride, ## Used in [method StatHolder.register_stat] as a default value; should not be used as the rounding mode, but will behave the same as [enum roundingMode.None].
	ClampToZeroAndMax, ## Does not round the float, but instead tries to clamp the stat to between 0 and a stat with the name set in [member StatTracker.statMaxName]
}
## Controls how a [StatTracker] is displayed in the [InfoBox].
enum displayModes {
	ALWAYS, ## Always displayed.
	NEVER, ## Never displayed.
	NOT_ONE, ## Displayed if the stat does not currently equal 1.0.
	NOT_ZERO, ## Displayed if the stat does not currently equal 0.0.
	ABOVE_ZERO, ## Displayed if the stat is > 0.
	IF_MODIFIED, ## Displayed if the stat is currently different from its [member baseStat].
	NOT_999, ## Displayed if the stat is not the specific value of 999.
	ABOVE_ZERO_NOT_999, ## Displayed if the stat is not the specific value of 999.
}
enum statTags {
	Hull, ## Health and defense.
	Battery, ## Energy draw and stuff.
	Weaponry, ## Things regarding attack damage.
	Clock, ## Things regarding... cooldowns.
	Projectiles, ## Things regarding specifically projectiles.
	Worth, ## Stuff regarding Scrap.
	Function, ## Sort of a catch-all for specific functions the thing does.
	Miscellaneous, ## Anything else.
	INVALID, ## Don't use this one.
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
