@icon ("res://graphics/images/class_icons/statHolder2D.png")
extends FreezableControl

class_name StatHolderControl;

@export_category("Stats")
#@export var statCollection : Array[StatTracker] = []
#@export var statCollection : Dictionary[String,StatTracker] = {}
var statCollection : Dictionary[String,StatTracker] = {};

@export var filepathForThisEntity : String;
var statHolderID := -1:
	get:
		if statHolderID == -1:
			statHolderID = set_stat_holder_id();
		return statHolderID;

func _ready():
	super();
	
	clear_stats();
	stat_registry();

func clear_stats():
	var keysToRemove = []
	if statCollection.size() > 0:
		#print_rich("[color=red]Stat collection is NOT empty at start.")
		#print_all_stats();
		for statName in statCollection.keys():
			var stat = statCollection[statName]
			if is_instance_valid(stat):
				if stat is StatTracker:
					if stat.stat_id_invalid_or_matching(statHolderID):
						keysToRemove.append(statName);
						#print("Erasing stat ", statName, " from ", name,"; Was found to have an invalid ID or a matching ID to this StatHolder")
				else:
					#print("Erasing stat ", statName, " from ", name,"; Was somehow not a StatTracker")
					keysToRemove.append(statName);
			else:
				#print("Erasing stat ", statName, "; Was invalid")
				keysToRemove.append(statName);
		pass;
	for statName in keysToRemove:
		statCollection.erase(statName);
	nonexistentStats.clear();

func regenerate_stats():
	clear_stats();
	stat_registry();

##Gets a named stat from the stat collection. Optional rounding mode override.
func get_stat(statName : String, roundModeOverride := StatHolderManager.roundingModes.NoOverride):
	var stat = get_stat_resource(statName);
	if stat != null:
		#if stat.statFriendlyName.contains("Max"): print("Max health found?", stat.statFriendlyName)
		if roundModeOverride != StatHolderManager.roundingModes.NoOverride:
			return stat.get_stat(roundModeOverride);
		else:
			return stat.get_stat();
	return 0.0;
	pass;

func has_stat(statName : StringName):
	return get_stat_resource(statName) != null;

var nonexistentStats = []
## Returns the stat's StatTracker resource.[br]
## If the stat given doesn't exist, and it's trying to get that stat, then it adds its name to [member nonexistentStats] and knows not to try to load it in the future.
func get_stat_resource(statName : StringName, ignoreNonexistent := false) -> StatTracker:
	#if statName == "HealthMax": 
		#print_all_stats();
		#pass;
	if (not ignoreNonexistent) and nonexistentStats.has(stat_name_with_id(statName)):
		return null;
	if statCollection.has(stat_name_with_id(statName)):
		return statCollection[stat_name_with_id(statName)];
	#print_rich("[color=orange]Stat ",stat_name_with_id(statName),"does not exist.")
	if (not ignoreNonexistent):
		#print_rich("[color=red]Stat ",stat_name_with_id(statName),"being added to the nonexistant list.")
		nonexistentStats.append(stat_name_with_id(statName))
	return null;

func print_all_stats():
	print("Printing stats... ", statCollection.size())
	for statName in statCollection.keys():
		var stat = statCollection[statName]
		if stat is StatTracker:
			print("Stat exists:", stat.statName);
	pass;

##Gets a stat from the stat collection, then changes its value directly.
func set_stat(statName : String, newValue : float):
	var stat = get_stat_resource(statName);
	if stat != null:
		var modifiedStat = stat.set_stat(newValue);

##Adds the given value numToAdd to the named stat.
func stat_plus(statName : String, numToAdd : float):
	set_stat(statName, get_stat(statName) + numToAdd);

##Subtracts the given value [param numToSubtract] to the named stat by just running stat_plus() in reverse.
func stat_minus(statName : String, numToSubtract : float):
	stat_plus(statName, - numToSubtract);

## Registers new stats. Only ever call this from stat_registry().[br]In the [param getFunction] field, you can define a new function that is called and returned when get_stat() is called.[br]In the setFunction field, you can define a new function that is called when set_stat() is called.[br]Both getFunction and setFunction can be set to null to have them use the default get or set.
func register_stat(statName : String, baseStat : float, statIcon : Texture2D = StatHolderManager.get_stat_icon("Default"), statTag := StatHolderManager.statTags.Miscellaneous, displayMode := StatHolderManager.displayModes.ALWAYS, roundingMode := StatHolderManager.roundingModes.None, maxStat : String = statName, getFunction : Variant = null, setFunction : Variant = null):
	await ready;
	#print_rich("[color=blue]Creating stat "+stat_name_with_id(statName)+" with value "+str(baseStat)+"[/color]")
	if get_stat_resource(statName, true) == null: #Check if the stat already exists before adding it again.
		var statTracked = StatTracker.new();
		
		
		statTracked.statFriendlyName = statName.capitalize();
		statTracked.statName = stat_name_with_id(statName);
		statTracked.statMaxName = maxStat;
		statTracked.statIcon = statIcon;
		statTracked.textColor = StatHolderManager.get_stat_color_from_image(statTracked.statIcon);
		statTracked.baseStat = baseStat;
		statTracked.currentValue = baseStat;
		statTracked.roundingMode = roundingMode;
		statTracked.displayMode = displayMode;
		statTracked.statTag = statTag;
		if statIcon != null and statIcon is Texture2D:
			statTracked.statIcon = statIcon;
		if getFunction != null and getFunction is Callable:
			statTracked.getFunc = getFunction;
		if setFunction != null and setFunction is Callable:
			statTracked.setFunc = setFunction;
		statTracked.resource_name = stat_name_with_id(statName);
		statTracked.statID = statHolderID;
		GameState.log_unique_stat(statTracked);
		statCollection[stat_name_with_id(statName)] = statTracked;
	else:
		#print_rich("[color=red]stat"+statName+"already exists...")
		pass

func add_multiplier(statName : StringName):
	var stat = get_stat_resource(statName);
	pass;

## Where any and all register_stat() or related calls should go. Runs at _ready().
func stat_registry():
	pass;

func set_stat_holder_id():
	statHolderID = StatHolderManager.get_unique_stat_holder_id();
	StatHolderManager.register_stat_holder(self);
	return statHolderID;

func stat_name_with_id(statName):
	return str(statName, statHolderID);

func stat_exists(statName):
	return get_stat_resource(statName, true) != null;
