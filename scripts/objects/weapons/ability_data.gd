@icon ("res://graphics/images/class_icons/energy_white.png")
extends Resource
class_name AbilityData
## A sub-resource held by an [AbilityManager] to keep track of indiidual cooldowns for different [Piece]s and [Part]s.

var abilityID := -1;
var statHolderID := -1;
var cooldownTimer := 0.0;
var disabled := false;
func is_disabled():
	return disabled;
var freezeFrames := 0;
var freezeTime := 0.0;

var assignedSlots : Array[int] = []
var assignedRobot : Robot;
var abilityName:
	get:
		if abilityName == null:
			abilityName = manager.abilityName;
		return abilityName;

var manager: AbilityManager:
	get:
		if manager == null:
			manager = get_manager();
		return manager;

func call_ability():
	return manager.call_ability(statHolderID);

func assign_robot(robot, slotNum):
	if is_instance_valid(robot):
		assign_slot(slotNum);
		assignedRobot

func unassign_robot():
	assignedRobot = null;
	unassign_all_slots();

func get_assigned_robot():
	return assignedRobot;

func assign_slot(slotNum):
	Utils.append_unique(assignedSlots, slotNum);
	pass;

func unassign_slot(slotNum):
	assignedSlots.erase(slotNum);
	if !is_equipped() and is_instance_valid(assignedRobot):
		unassign_robot();
	pass;

func unassign_all_slots():
	assignedSlots.clear()

func get_assigned_slots():
	return assignedSlots;

var assignedPieceOrPart:
	get:
		if assignedPieceOrPart == null:
			assignedPieceOrPart = get_assigned_piece_or_part();
		GameState.profiler_ping_create("Ability assignedPieceOrPart Ping");
		return assignedPieceOrPart;

func get_assigned_piece_or_part():
	var thing = StatHolderManager.get_stat_holder_by_id(statHolderID);
	if is_instance_valid(thing):
		GameState.profiler_ping_create("Assigned Piece Found")
		return thing;
	GameState.profiler_ping_create("Assigned Piece NOT Found")
	return null;

func is_equipped() -> bool:
	return get_assigned_slots().is_empty() == false;

func is_on_piece() -> bool:
	return is_instance_valid(assignedPieceOrPart) and assignedPieceOrPart is Piece;

func is_on_assigned_piece() -> bool:
	return is_on_piece() and is_instance_valid(assignedPieceOrPart) and assignedPieceOrPart.assignedToSocket;

func remove_stat_holder_id():
	manager.remove_stat_holder_id(statHolderID);


var currentAbilityInfobox : AbilityInfobox;
var selected := false; ## Whether this guy is selected on the infobox. 
## Returns [member selected]. 
func get_selected()->bool:
	return selected;
## Changes [member selected].
func select(foo:= not get_selected()):
	selected = foo;
	
	if is_instance_valid(currentAbilityInfobox):
		currentAbilityInfobox.select(foo);
	else:
		#print("Ability infobox? Yello?")
		pass;
	
	if foo:
		pass;
	else:
		pass;

func deselect():
	select(false);



## Returns true if both [member abilityID] and [member statHolderID] match the inputs [param in_abilityID] and [param in_statHolderID] respectively.
func is_exact_match(in_abilityID, in_statHolderID):
	return in_abilityID == abilityID and in_statHolderID == statHolderID;

func get_ability_slot_data():
	var mgr = get_manager();
	return mgr.get_ability_slot_data(statHolderID);

func get_manager() -> AbilityManager:
	return AbilityDistributor.get_ability_manager_with_id(abilityID);

func is_running_cooldowns() -> bool:
	if assignedPieceOrPart is Piece:
		return assignedPieceOrPart.is_running_cooldowns();
	elif assignedPieceOrPart is Part:
		pass;
	return false;
