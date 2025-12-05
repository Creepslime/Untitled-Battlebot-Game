@icon ("res://graphics/images/class_icons/heart_white.png")
extends Resource

##A resource used for keeping track of stats on [Robot]s, [Part]s and [Piece]s, among other things.
class_name StatTracker

@export var statFriendlyName : String; ## This stat's name [i]without[/i] [member statID] appended.
@export var statName : String; ## This stat's name [i]with[/i] [member statID] appended.
var statMaxName : String; ## The stat friendly name to search for if [enum StatHolderManager.roundingModes.ClampToZeroAndMax] is your [member roundingMode].
var statID : int = -1;  ## A unique identifier created so the Robots stop sharing custody.
var host:
	get:
		return StatHolderManager.get_stat_holder_by_id(statID);
@export var statIcon : Texture2D = preload("res://graphics/images/HUD/statIcons/magazineIconStriped.png"); ## The icon used when a [InspectorStatIcon] node displays this stat.
var textColor := Color("789be9"); ## The text color used when a [InspectorStatIcon] node displays this stat.
@export var baseStat : float; ## The base number defined before calculation.
var currentValue : float; ## The current value of this stat.
var currentValueModified : float; ## The current value of this stat after applying modifiers.
var bonusAdd : float = 0.0; ##@experimental: Adds this value to baseStat.
var bonusMult_Flat : float = 0.0; ##@experimental:Multiplies the total value after baseStat + bonusAdd.
var bonusMult_Mult : float = 1.0; ##@experimental:Multiplies bonusMult_Flat by this number before multiplying.

var statModifiers : Array[PartModifier] = []; ## The list of [PartModifier] resources this Stat is keeping track of.

@export var roundingMode := StatHolderManager.roundingModes.None; ##Keeps track of the current [enum roundingModes] value.[br][br]
@export var displayMode := StatHolderManager.displayModes.ALWAYS; ## Determines when this stat should be displayed, if at all.
@export var statTag := StatHolderManager.statTags.Miscellaneous; ## What group this stat is in on the inspector.
## Returns true if the stat should be displayed on the base inspector. Not applied to stats called for by abilities.
func should_be_displayed(statIDCheck := statID) -> bool:
	if statIDCheck == statID:
		match displayMode:
			StatHolderManager.displayModes.ALWAYS:
				return true;
				pass;
			StatHolderManager.displayModes.ALWAYS_DIVIDE_BY_100:
				return true;
				pass;
			StatHolderManager.displayModes.NEVER:
				return false;
				pass;
			StatHolderManager.displayModes.NOT_ONE:
				return ! is_equal_approx(get_stat(), 1.0);
				pass;
			StatHolderManager.displayModes.NOT_999:
				return ! is_equal_approx(get_stat(), 999.0);
				pass;
			StatHolderManager.displayModes.NOT_ZERO:
				return ! is_zero_approx(get_stat());
				pass;
			StatHolderManager.displayModes.NOT_ZERO_ABSOLUTE_VALUE:
				return ! is_zero_approx(get_stat());
				pass;
			StatHolderManager.displayModes.ABOVE_ZERO:
				return get_stat() > 0;
				pass;
			StatHolderManager.displayModes.ABOVE_ZERO_NOT_999:
				return get_stat() > 0 and ! is_equal_approx(get_stat(), 999.0);
				pass;
			StatHolderManager.displayModes.IF_MODIFIED:
				return ! is_equal_approx(get_stat(), baseStat);
				pass;
	return false;

## This [StatTracker]'s get function called by [method get_stat].
var getFunc := func (): var stat : float = currentValue; return stat;
## This [StatTracker]'s set function called by [method set_stat].
var setFunc := func (newValue): return newValue;

## @experimental: Theoretically, an array of floats that each add onto this value, as applied by bonuses. TODO: Not implemented yet.
var additions = []

## Gets the current rounding mode from [enum roundingModes].
func get_rounding_mode() -> StatHolderManager.roundingModes:
	return roundingMode;

## Gets the stat by calling [member getFunc].
func get_stat(roundingModeOverride : StatHolderManager.roundingModes = get_rounding_mode()):
	if recalculateModifiersNextGet:
		recalculate_modifiers();
	
	var stat = getFunc.call();
	currentValue = return_rounded_stat(stat, roundingModeOverride);
	currentValueModified = return_rounded_stat(calculate_modified_value(stat), roundingModeOverride);
	return currentValueModified;

func get_stat_for_display():
	var stat = get_stat();
	
	match displayMode:
		StatHolderManager.displayModes.ALWAYS_DIVIDE_BY_100:
			return stat / 100;
		StatHolderManager.displayModes.NOT_ZERO_ABSOLUTE_VALUE:
			return abs(stat);
		_:
			return stat;

## Rounds the stat according to the current rounding mode.
func return_rounded_stat(stat, roundingModeOverride : StatHolderManager.roundingModes = roundingMode):
	match roundingModeOverride:
		StatHolderManager.roundingModes.Floor:
			return floorf(stat);
		StatHolderManager.roundingModes.Round:
			return roundf(stat);
		StatHolderManager.roundingModes.Ceil:
			return ceilf(stat);
		StatHolderManager.roundingModes.Floori:
			return floori(stat);
		StatHolderManager.roundingModes.Roundi:
			return roundi(stat);
		StatHolderManager.roundingModes.Ceili:
			return ceili(stat);
		StatHolderManager.roundingModes.None: ##Both None and NoOverride should return just the base value without any rounding.
			return stat;
		StatHolderManager.roundingModes.NoOverride: ##Both None and NoOverride should return just the base value without any rounding.
			return stat;
		StatHolderManager.roundingModes.ClampToZeroAndMax: ## No rounding. Return this clamped between 0 and the host's stat.
			if is_instance_valid(host):
				return clampf(stat, 0, host.get_stat(statMaxName));
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
		#recalculate_modifiers();
		
	#print( get_property_list())

## @experimental: Returns a filepath. Not used for anything!
func get_stat_path():
	if statID == null:
		statID = GameState.get_unique_stat_id();
	return "user://stats/"+statName+"_"+str(statID)+".res";

## Adds [inMod] to [member statModifiers].
func register_modifier(inMod : PartModifier):
	Utils.append_unique(statModifiers, inMod);
	recalculateModifiersNextGet = true;
	pass;

func reset_modifiers():
	statModifiers.clear();
	recalculateModifiersNextGet = true;

var recalculateModifiersNextGet := false;

func calculate_modified_value(stat : float) -> float:
	if recalculateModifiersNextGet:
		recalculate_modifiers();
	return (stat + bonusAdd) * ((1 + bonusMult_Flat) * bonusMult_Mult)

## Loops over all [PartModifier] resources and recalculates [member modifiedValue].
func recalculate_modifiers():
	recalculateModifiersNextGet = false;
	
	bonusAdd = 0.0;
	bonusMult_Flat = 0.0;
	bonusMult_Mult = 1.0;
	for mod in statModifiers:
		bonusAdd += mod.valueAdd;
		bonusMult_Flat += mod.valueFlatMult
		bonusMult_Mult += mod.valueTimesMult - 1.0;

## Used to determine whether to erase this resource during [method StatHolder3D.clear_stats].
func stat_id_invalid_or_matching(idToCheck):
	if statID == -1:
		return true;
	return idToCheck == statID;
