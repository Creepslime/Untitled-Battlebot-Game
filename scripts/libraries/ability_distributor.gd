@icon("res://graphics/images/class_icons/energy_white.png")
## This serves to store all abilities and distribut copies of them.[br]
## Super annoying, I know.
extends Node

var activeAbilities : Dictionary[StringName,AbilityManager] = {};
var passiveAbilities : Dictionary[StringName,AbilityManager] = {};

func distribute_active_ability_to_piece(piece:Piece, abilityName:StringName):
	if activeAbilities.has(abilityName):
		var dupe = activeAbilities[abilityName].create_copy();
		#print(dupe.resource_scene_unique_id)
		dupe.assign_references(piece);
		dupe.initialized = true;
		piece.activeAbilities.append(dupe);
		print("ABILITY REGISTRAR: Active with name ",dupe.abilityName," and ID ",dupe.abilityID," being copied to piece ", piece);

func distribute_all_actives_to_piece(piece:Piece, abilityNames : Array):
	for abilityName in abilityNames:
		distribute_active_ability_to_piece(piece, abilityName);

func distribute_passive_ability_to_piece(piece:Piece, abilityName:StringName):
	if passiveAbilities.has(abilityName):
		var dupe = passiveAbilities[abilityName].create_copy();
		dupe.assign_references(piece);
		dupe.initialized = true;
		dupe.isPassive = true;
		piece.passiveAbilities.append(dupe);
		print("ABILITY REGISTRAR: Passive with name ",dupe.abilityName," and ID ",dupe.abilityID," being copied to piece ", piece);

func distribute_all_passives_to_piece(piece:Piece, abilityNames : Array):
	for abilityName in abilityNames:
		distribute_passive_ability_to_piece(piece, abilityName);

func distribute_all_abilities_to_piece(piece:Piece):
	## Duplicate the resources so the ability doesn't get joint custody with another piece of the same type.
	## Construct the description FIRST, because the constructor array is not going to get copied over.
	
	var activeNames = [];
	for ability in piece.activeAbilities:
		if ability is AbilityManager:
			activeNames.append(ability.abilityName);
	piece.activeAbilities.clear();
	distribute_all_actives_to_piece(piece, activeNames);
	
	var passiveNames = [];
	for ability in piece.passiveAbilities:
		if ability is AbilityManager:
			passiveNames.append(ability.abilityName);
	piece.passiveAbilities.clear();
	distribute_all_passives_to_piece(piece, passiveNames);
	
	#piece.ability
	pass;

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
						var abilityName = loadedFile.abilityName;
						loadedFile.construct_description();
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
						var abilityName = loadedFile.abilityName;
						loadedFile.construct_description();
						activeAbilities[abilityName] = loadedFile;
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	print(activeAbilities);
