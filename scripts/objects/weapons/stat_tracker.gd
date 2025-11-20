@icon ("res://graphics/images/class_icons/heart_white.png")
extends Resource

##A resource used for keeping track of stats on [Robot]s, [Part]s and [Piece]s, among other things.
class_name StatTracker

@export var statFriendlyName : String; ## This stat's name [i]without[/i] [member statID] appended.
@export var statName : String; ## This stat's name [i]with[/i] [member statID] appended.
var statID : int = -1;  ## A unique identifier created so the Robots stop sharing custody.
@export var statIcon : Texture2D = preload("res://graphics/images/HUD/statIcons/magazineIconStriped.png"); ## The icon used when a [InspectorStatIcon] node displays this stat.
var textColor := Color("789be9"); ## The text color used when a [InspectorStatIcon] node displays this stat.
@export var baseStat : float; ## The base number defined before calculation.
var currentValue : float; ## The current value of this stat.
var bonusAdd : float = 0.0; ##@experimental: Adds this value to baseStat.
var bonusMult_Flat : float = 0.0; ##@experimental:Multiplies the total value after baseStat + bonusAdd.
var bonusMult_Mult : float = 1.0; ##@experimental:Multiplies bonusMult_Flat by this number before multiplying.

##[enum roundingMode.None] means no modifications to the number when getting it; it will remain an unrounded [float]. [br][enum roundingMode.Floor], [enum roundingMode.Round], and [enum roundingMode.Ceil] will perform those mathematic functions on the number, to the appropriate nearest [float].[br][enum roundingMode.Floori], [enum roundingMode.Roundi], and [enum roundingMode.Ceili] will perform those mathematic functions on the number, to the appropriate nearest [int]. [br][enum roundingMode.NoOverride] is used in [method StatHolder.register_stat] as a default value; should not be used as the rounding mode, but will behave the same as [enum roundingMode.None].
enum roundingModes {
	None,
	Floor,
	Round,
	Ceil,
	Floori,
	Roundi,
	Ceili,
	NoOverride,
}
@export var roundingMode := roundingModes.None; ##Keeps track of the current [enum roundingModes] value.[br][br]

## This [StatTracker]'s get function called by [method get_stat].
var getFunc := func (): var stat : float = (currentValue + bonusAdd)  * (((1.0 + bonusMult_Flat) * bonusMult_Mult)); return stat;
## This [StatTracker]'s set function called by [method set_stat].
var setFunc := func (newValue): return newValue;

## @experimental: Theoretically, an array of floats that each add onto this value, as applied by bonuses. TODO: Not implemented yet.
var additions = []

## Gets the current rounding mode from [enum roundingModes].
func get_rounding_mode() -> roundingModes:
	return roundingMode;

## Gets the stat by calling [member getFunc].
func get_stat(roundingModeOverride : roundingModes = get_rounding_mode()):
	var stat = getFunc.call();
	#currentValue = return_rounded_stat(stat, roundingModeOverride);
	#return currentValue;
	#print("getting ", statName, " ", stat)
	return stat;

## Rounds the stat according to the current rounding mode.
func return_rounded_stat(stat, roundingModeOverride : roundingModes = roundingMode):
	match roundingModeOverride:
		roundingModes.Floor:
			return floorf(stat);
		roundingModes.Round:
			return roundf(stat);
		roundingModes.Ceil:
			return ceilf(stat);
		roundingModes.Floori:
			return floori(stat);
		roundingModes.Roundi:
			return roundi(stat);
		roundingModes.Ceili:
			return ceili(stat);
		roundingModes.None: ##Both None and NoOverride should return just the base value without any rounding.
			return stat;
		roundingModes.NoOverride: ##Both None and NoOverride should return just the base value without any rounding.
			return stat;
	return stat;

## Sets the stat by calling [member setFunc].
func set_stat(newValue):
	#print(is_instance_valid(setFunc))
	if (! is_queued_for_deletion()
	 #and is_instance_valid(setFunc)
	and is_instance_valid(self)
	):
		#prints(get_reference_count())
		#print(setFunc)
		#prints("Stat",statName,"was set properly.")
		currentValue = setFunc.call(newValue);
		
	#print( get_property_list())

## @experimental: Returns a filepath. Not used for anything!
func get_stat_path():
	if statID == null:
		statID = GameState.get_unique_stat_id();
	return "user://stats/"+statName+"_"+str(statID)+".res";

## TODO: Make this do anything. Port over the bonuses system from [Part].
func register_bonus():
	pass;

## Used to determine whether to erase this resource during [method StatHolder3D.clear_stats].
func stat_id_invalid_or_matching(idToCheck):
	if statID == -1:
		return true;
	return idToCheck == statID;
