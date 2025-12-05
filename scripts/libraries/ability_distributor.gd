@icon("res://graphics/images/class_icons/abilityDistributor.png")
## This serves to store all abilities and distribut copies of them.[br]
## Super annoying, I know.
extends Node

var activeAbilities : Dictionary[StringName,AbilityManager] = {};
var passiveAbilities : Dictionary[StringName,AbilityManager] = {};
var allAbilities :
	get:
		return get_all_ability_managers();

#### PIECES

func distribute_active_ability_to_piece(piece:Piece, abilityName:StringName):
	if activeAbilities.has(abilityName):
		var ability = activeAbilities[abilityName];
		ability.assign_stat_holder(piece);
		piece.activeAbilitiesDistributed.append(ability);

func distribute_all_actives_to_piece(piece:Piece, abilityNames : Array):
	for abilityName in abilityNames:
		distribute_active_ability_to_piece(piece, abilityName);

func distribute_passive_ability_to_piece(piece:Piece, abilityName:StringName):
	if passiveAbilities.has(abilityName):
		var ability = passiveAbilities[abilityName];
		ability.assign_stat_holder(piece);
		piece.passiveAbilitiesDistributed.append(ability);

func distribute_all_passives_to_piece(piece:Piece, abilityNames : Array):
	for abilityName in abilityNames:
		distribute_passive_ability_to_piece(piece, abilityName);

func distribute_all_abilities_to_piece(piece:Piece):
	## Duplicate the resources so the ability doesn't get joint custody with another piece of the same type.
	## Construct the description FIRST, because the constructor array is not going to get copied over.
	
	var activeNames = [];
	for ability in piece.activeAbilities:
		if ability is AbilityManager:
			activeNames.append(ability.abilityNameInternal);
			#piece.activeAbilities.erase(ability);
	
	var passiveNames = [];
	for ability in piece.passiveAbilities:
		if ability is AbilityManager:
			passiveNames.append(ability.abilityNameInternal);
			#piece.passiveAbilities.erase(ability);
	
	piece.clear_abilities();
	
	distribute_all_actives_to_piece(piece, activeNames);
	distribute_all_passives_to_piece(piece, passiveNames);
	
	#piece.ability
	#print("StatHolder Piece with id ", piece.statHolderID, )
	pass;

func piece_has_passive_with_same_name(abilityName : String, piece:Piece):
	for passive in piece.passiveAbilities:
		if passive.abilityName == abilityName:
			return true;
	return false;
func piece_has_active_with_same_name(abilityName : String, piece:Piece):
	for active in piece.passiveAbilities:
		if active.abilityName == abilityName:
			return true;
	return false;

##### PARTS

func distribute_active_ability_to_part(part:Part, abilityName:StringName):
	if activeAbilities.has(abilityName):
		var ability = activeAbilities[abilityName];
		ability.assign_stat_holder(part);
		part.activeAbilitiesDistributed.append(ability);

func distribute_all_actives_to_part(part:Part, abilityNames : Array):
	for abilityName in abilityNames:
		distribute_active_ability_to_part(part, abilityName);

func distribute_passive_ability_to_part(part:Part, abilityName:StringName):
	if passiveAbilities.has(abilityName):
		var ability = passiveAbilities[abilityName];
		ability.assign_stat_holder(part);
		part.passiveAbilitiesDistributed.append(ability);

func distribute_all_passives_to_part(part:Part, abilityNames : Array):
	for abilityName in abilityNames:
		distribute_passive_ability_to_part(part, abilityName);

func distribute_all_abilities_to_part(part:Part):
	## Duplicate the resources so the ability doesn't get joint custody with another part of the same type.
	## Construct the description FIRST, because the constructor array is not going to get copied over.
	
	var activeNames = [];
	for ability in part.activeAbilities:
		if ability is AbilityManager:
			activeNames.append(ability.abilityNameInternal);
			#part.activeAbilities.erase(ability);
	
	var passiveNames = [];
	for ability in part.passiveAbilities:
		if ability is AbilityManager:
			passiveNames.append(ability.abilityNameInternal);
			#part.passiveAbilities.erase(ability);
	
	part.clear_abilities();
	
	distribute_all_actives_to_part(part, activeNames);
	distribute_all_passives_to_part(part, passiveNames);
	
	#part.ability
	#print("StatHolder Part with id ", part.statHolderID, )
	pass;

func part_has_passive_with_same_name(abilityName : String, part:Part):
	for passive in part.passiveAbilities:
		if passive.abilityName == abilityName:
			return true;
	return false;
func part_has_active_with_same_name(abilityName : String, part:Part):
	for active in part.passiveAbilities:
		if active.abilityName == abilityName:
			return true;
	return false;

const passivesFilePrefix = "res://scenes/prefabs/abilities/passive/"
const activesFilePrefix = "res://scenes/prefabs/abilities/active/"

func _ready():
	get_passives();
	get_actives();

##Resets the list of viewed Pieces.
func get_passives():
	var prefix = passivesFilePrefix
	var dir = DirAccess.open(prefix)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				print("Found file: " + file_name)
				
				var fullName = prefix + file_name
				print(fullName)
				if FileAccess.file_exists(fullName):
					var loadedFile = load(fullName);
					if loadedFile is AbilityManager:
						var abilityName = loadedFile.abilityNameInternal;
						loadedFile.construct_description();
						loadedFile.isPassive = true;
						passiveAbilities[abilityName] = loadedFile;
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	
	print(passiveAbilities);

##Resets the list of viewed Pieces.
func get_actives():
	var prefix = activesFilePrefix;
	var dir = DirAccess.open(prefix)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				print("Found file: " + file_name)
				
				var fullName = prefix + file_name
				print(fullName)
				if FileAccess.file_exists(fullName):
					var loadedFile = load(fullName);
					if loadedFile is AbilityManager:
						var abilityName = loadedFile.abilityNameInternal;
						loadedFile.construct_description();
						activeAbilities[abilityName] = loadedFile;
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	print(activeAbilities);

func get_all_ability_managers() -> Array[AbilityManager]:
	var ret : Array[AbilityManager] = [];
	for value in activeAbilities.values():
		ret.append(value);
	for value in passiveAbilities.values():
		ret.append(value);
	return ret;

func remove_id_from_abilities(id):
	for ability in get_all_ability_managers():
		ability.remove_stat_holder_id(id);

## abilityID stuff.
var abilityID := 0;

func get_unique_ability_id() -> int:
	var ret = abilityID;
	abilityID += 1;
	return ret;

func get_ability_manager_with_id(id:int) -> AbilityManager:
	for ability in get_all_ability_managers():
		if ability.abilityID == id:
			return ability;
	return null;

func tick_all_cooldowns(delta):
	if not GameState.is_paused() and GameState.get_in_state_of_play(true):
		for manager in allAbilities:
			manager.tick_all_cooldowns(delta);

func _process(delta):
	tick_all_cooldowns(delta);
