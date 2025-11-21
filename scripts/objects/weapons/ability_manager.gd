@icon ("res://graphics/images/class_icons/abilityManager.png")
extends Resource

class_name AbilityManager
## Controls an Ability for all [Piece]s or [Part]s that plan on using it. Holds [AbilityData] for each node that is using the ability, and is distributed with the global script [AbilityDistributor].

@export var abilityName : String = "Active Ability";
@export var abilityDescriptionConstructor : Array[RichTextConstructor] = [];
@export_multiline var abilityDescription : String = "No Description Found.";
@export var energyCost : float = 0.0;
@export var cooldownTimeBase : float = 0.0;
##If you want to have the cooldown use a stat from within the host piece for its timer, put it here. Otherwise, leave it blank.
@export var cooldownStatName : String; 
@export var runType : runTypes = runTypes.Default; ## How this gets called. [br]Default makes the ability perform manually or on a loop, for Active and Passive abilities respectively.[br]Manual is the default for all Active abilities; You must fire it manually with the press of a button.[br]LoopingCooldown is the default for all Passive abilities; it runs automatically based on its [member cooldownTimeBase], attempting to restart when it hits 0.[br]OnContactDamage makes this passive go onto cooldown when the Piece it's on deals contact damage. Use this for passives that control how often a passive hitbox interaction is allowed to stay up.
@export var functionNameWhenUsed : StringName;
@export var statsUsed : Array[String] = []; ## Any stats from the host piece you want to be displayed in this ability's inspector box.
@export var icon : Texture2D;
@export var hookName : String; ## If you want this ability to be called
@export_subgroup("Internal bits")
@export var initialized := false;
@export var disabled := false;
@export var functionWhenUsed : Callable;
var abilityID := -1:
	get:
		if abilityID == -1:
			abilityID = AbilityDistributor.get_unique_ability_id();
		return abilityID;

var statHolderUserData : Dictionary[int, AbilityData] = {};

## Gets the [AbilityData] associated with the given StatHolder Id ([param id]).
func get_ability_data(id : int) -> AbilityData:
	if statHolderUserData.has(id):
		return statHolderUserData[id];
	#print("INVALID ID ",id," in ability ", abilityName, " Whole list: ", statHolderUserData)
	return null;
## Assigns a [StatHolder3D] or (TODO)[StatHolder2D] to this ability, giving it a unique instance of this ability.
func assign_stat_holder(object):
	if object is StatHolder3D:
		var newData = AbilityData.new();
		newData.abilityID = abilityID;
		var statolderID = object.statHolderID;
		newData.statHolderID = statolderID;
		newData.get_assigned_piece_or_part()
		statHolderUserData[statolderID] = newData;
		if object is Piece:
			object.regen_namedActions();
		print("ABILITY REGISTRAR: Ability with name ",abilityName," and ID ",abilityID," being copied to piece ", object, "with ID ", statolderID,". Here's what it thinks it's assigned to: ", newData.assignedPieceOrPart, " ...Which is an assigned piece? ", newData.is_on_assigned_piece(), " Is it assigned to a socket? ", newData.assignedPieceOrPart.is_assigned());
		pass;

#var cooldownTimer := 0.0; ##@deprecated: Timers are run in individual [AbilityData] resources now.

## The way this ability gets called/put on cooldown.
enum runTypes {
	Default, ## Gets run manually.
	LoopingCooldown, ## Gets run every time the cooldown runs out.
	OnContactDamage, ## Runs when contact damage happens.
	Manual, ## Gets run manually.
}

#var assignedRobot : Robot; ## @deprecated
#var assignedPieceOrPart; ## @deprecated

var isPassive := false;

## @deprecated: There should only ever be one of these at a time. Only [AbilityData] is copied now.
func create_copy() -> AbilityManager:
	construct_description();
	var newAbility = AbilityManager.new();
	newAbility.abilityName = abilityName;
	newAbility.abilityDescription = abilityDescription;
	newAbility.cooldownStatName = cooldownStatName;
	newAbility.cooldownTimeBase = cooldownTimeBase;
	newAbility.disabled = disabled;
	newAbility.energyCost = energyCost;
	newAbility.functionNameWhenUsed = functionNameWhenUsed;
	newAbility.functionWhenUsed = functionWhenUsed;
	newAbility.statsUsed = statsUsed;
	newAbility.runType = runType;
	newAbility.icon = icon;
	newAbility.abilityID = GameState.get_unique_ability_id();
	return newAbility;

## Removes the given StatHolder from the user data.
func remove_stat_holder_id(id : int):
	statHolderUserData.erase(id);

func assign_robot(id : int, robot : Robot, slotNum : int):
	var data = get_ability_data(id);
	if is_instance_valid(data):
		data.assign_robot(robot, slotNum);
func unassign_robot(id:int):
	var data = get_ability_data(id);
	if is_instance_valid(data):
		data.unassign_robot();

func unassign_slot(id, slotNum : int):
	var data = get_ability_data(id);
	if is_instance_valid(data):
		data.unassign_slot(slotNum);

func unassign_all_slots(id : int):
	var data = get_ability_data(id);
	if is_instance_valid(data):
		data.unassign_all_slots();

func get_assigned_slots(id : int) -> Array[int]:
	var array : Array[int] = [];
	var data = get_ability_data(id);
	if is_instance_valid(data):
		array = data.slots
		return data.assignedSlots;
	return array;

func get_assigned_piece_or_part(id : int):
	var data = get_ability_data(id);
	if is_instance_valid(data):
		return data.get_assigned_piece_or_part();
	return null;

func get_assigned_robot(id : int):
	var data = get_ability_data(id);
	if is_instance_valid(data):
		return data.get_assigned_robot();
	return null;

## @deprecated
func register(partOrPiece : Node, _abilityName : String = "Active Ability", _abilityDescription : String = "No Description Found.", _functionWhenUsed : Callable = func(): pass, _statsUsed : Array[String] = [], _passive := false):
	if partOrPiece is PartActive or partOrPiece is Piece:
		#assignedPieceOrPart = partOrPiece;
		
		abilityName = _abilityName;
		abilityDescription = _abilityDescription;
		functionWhenUsed = _functionWhenUsed;
		statsUsed = _statsUsed;
		isPassive = _passive;

## @deprecated: Use [method assign_stat_holder] instead.
func assign_references(partOrPiece : Node):
	if partOrPiece is Piece:
		#assignedPieceOrPart = partOrPiece;
		print("ABILITY REGISTRAR: Piece ", partOrPiece, " assigned to Ability ", abilityName,abilityID);
		#assignedPieceOrPart.regen_namedActions();

## Constructs [member abilityDescription] out of the [member abilityDescriptionConstructor] if there is anything in there.
func construct_description():
	if ! abilityDescriptionConstructor.is_empty():
		abilityDescription = TextFunc.parse_text_constructor_array(abilityDescriptionConstructor);

func call_ability(id : int) -> bool:
	var data = get_ability_data(id);
	if is_instance_valid(data):
		var assignedThing = data.get_assigned_piece_or_part();
		if is_instance_valid(assignedThing):
			#print("ABILITY ",abilityName," HAS VALID HOST...");
			if assignedThing is PartActive:
				return assignedThing._activate();
			if assignedThing is Piece:
				if data.is_on_assigned_piece():
					return assignedThing.use_ability(self);
	return false;

func is_disabled(id) -> bool:
	var data = get_ability_data(id);
	if is_instance_valid(data):
		return data.disabled;
	return true;

func disable(id:int,foo : bool = is_disabled(id)):
	var data = get_ability_data(id);
	if is_instance_valid(data):
		data.disabled = foo;

#var currentAbilityInfobox : AbilityInfobox;
#var selected := false; ## @deprecated: Whether this guy is selected on the infobox. [br]Individual AbilityData
## Returns [member selected]. 
func get_selected(id)->bool:
	var data = get_ability_data(id);
	if is_instance_valid(data):
		return data.get_selected();
	return false;
## Changes [member selected].
func select(id:int, foo := not get_selected(id)):
	var data = get_ability_data(id);
	if is_instance_valid(data):
		data.select(foo);

func deselect(id:int):
	var data = get_ability_data(id);
	if is_instance_valid(data):
		data.select(false);

## Gets the base energy cost for this. Does NOT require an ID, since the base energy cost can't be modified.
func get_energy_cost_base(override = null)->float:
	if override is float: 
		if override < 999.0:
			return override;
	return energyCost;

func get_energy_cost(id : int):
	if is_instance_valid(get_assigned_piece_or_part(id)):
		var data = get_ability_data(id);
		if is_instance_valid(data):
			if get_assigned_piece_or_part(id) is Piece:
				return get_assigned_piece_or_part(id).get_active_energy_cost(self);
	return get_energy_cost_base();

func get_energy_cost_string(id : int):
	var s = ""
	s += TextFunc.format_stat(get_energy_cost(id), 2);
	if isPassive:
		s += "/s"
	return s

## @deprecated: 1 is removed from this each frame, if above 0.
var freezeFrames := 0;
## Adds to [member freezeFrames].
func add_freeze_frames(id : int, amt := 1):
	var data = get_ability_data(id);
	if is_instance_valid(data):
		data.freezeFrames += amt;
## @deprecated: delta time is removed from this each frame, if above 0. 
var freezeTime := 0.0;
## Adds to [member freezeTime].
func add_freeze_time(id : int, amt := 1.0):
	var data = get_ability_data(id);
	if is_instance_valid(data):
		data.freezeTime += amt;
## Ticks all cooldowns variables.[br]If [member freezeFrames] > 0, removes 1 from that this frame, then ends.[br]If [member freezeTime] > 0, removes [param delta] from that this frame, then ends.[br]If [member cooldownTimer] > 0, removes [param delta] from that this frame. Additionally adds [member freezeTime] if < 0, as compensation for delta rollover.
func tick_cooldown(id : int, delta):
	var data = get_ability_data(id);
	if is_instance_valid(data):
		if data.freezeFrames > 0:
			data.freezeFrames -= 1;
		else:
			if data.freezeTime > 0:
				data.freezeTime -= delta;
			else:
				if data.freezeTime < 0: ## Add negative freezeTime to delta as compensation for rollover.
					delta -= data.freezeTime;
					data.freezeTime = 0;
				data.cooldownTimer = max(0, data.cooldownTimer - delta);
## Gets the start time for the cooldown timer.
func get_cooldown_start_time(id : int, multiplier):
	var data = get_ability_data(id);
	if is_instance_valid(data):
		if cooldownStatName != null:
			if is_instance_valid(get_assigned_piece_or_part(id)):
				if get_assigned_piece_or_part(id) is Piece:
					if get_assigned_piece_or_part(id).has_stat(cooldownStatName):
						cooldownTimeBase = get_assigned_piece_or_part(id).get_stat(cooldownStatName);
	return cooldownTimeBase * multiplier;
func queue_cooldown(id : int, multiplier):
	var data = get_ability_data(id);
	if is_instance_valid(data):
		data.set_deferred("cooldownTimer", get_cooldown_start_time(id, multiplier))
func set_cooldown(id : int, multiplier):
	var data = get_ability_data(id);
	if is_instance_valid(data):
		if cooldownTimeBase > 0:
			data.set("cooldownTimer", get_cooldown_start_time(id, multiplier))
func get_cooldown(id : int)->float:
	var data = get_ability_data(id);
	if is_instance_valid(data):
		if data.is_disabled():
			return get_cooldown_start_time(id, 1.0);
		if data.cooldownTimer < 0:
			data.cooldownTimer = 0;
		return data.cooldownTimer;
	return 0;
func on_cooldown(id : int)->bool:
	var data = get_ability_data(id);
	if is_instance_valid(data):
		#print(id)
		return data.cooldownTimer > 0 or data.freezeTime > 0 or data.freezeFrames > 0;
	return true;

func set_ability_infobox(id : int, infobox : AbilityInfobox):
	var data = get_ability_data(id);
	if is_instance_valid(data):
		data.currentAbilityInfobox = infobox;
func clear_ability_infobox(id : int):
	var data = get_ability_data(id);
	if is_instance_valid(data):
		data.currentAbilityInfobox = null;
func get_ability_slot_data(id : int):
	if not is_equipped(id):
		return false;
	var data = {};
	if is_instance_valid(get_assigned_piece_or_part(id)) and get_assigned_piece_or_part(id) is Piece:
		data = get_assigned_piece_or_part(id).get_ability_slot_data(self);
	
	if not ("incomingPower" in data.keys()):
		data["incomingPower"] = 0.0;
	if not ("usable" in data.keys()):
		data["usable"] = false;
	data["requiredEnergy"] = get_energy_cost(id);
	
	data["cooldownTime"] = get_cooldown(id);
	data["cooldownStartTime"] = get_cooldown_start_time(id, 1.0);
	data["onCooldown"] = on_cooldown(id);
	return data;

func is_equipped(id : int) -> bool:
	var data = get_ability_data(id);
	if is_instance_valid(data):
		return data.is_equipped();
	return false;

func is_on_piece(id : int) -> bool:
	var data = get_ability_data(id);
	if is_instance_valid(data):
		return data.is_on_piece();
	return false;

func is_on_assigned_piece(id : int) -> bool:
	var data = get_ability_data(id);
	if is_instance_valid(data):
		return data.is_on_assigned_piece();
	return false;

## @deprecated: Used to determine whether to erase this resource during [method Piece.clear_abilities].[br]
## Also returns true if its actual assigned thing is invalid.
func ability_id_invalid_or_matching(idToCheck):
	if abilityID == -1:
		return true;
	return idToCheck == abilityID;
## @deprecated: AbilityManagers should never be deleted.
func should_delete(thingToCheck : StatHolder3D):
	#if thingToCheck != assignedPieceOrPart:
		#return true;
	#if ability_id_invalid_or_matching(thingToCheck.statHolderID):
		#return false;
	#return true;
	return false;
