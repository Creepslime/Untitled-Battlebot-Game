@icon("res://graphics/images/class_icons/arena.png")
extends Node3D

class_name Arena

@export var fallbackCameraPosition : = Vector3.ZERO; ## Where the camera goes to when there is no player to spy on.
@export var variantsFromFile : Dictionary[String, String] = {"Empty" : "res://scenes/prefabs/arenas/wallgridmap_empty.tscn",};
@export var variantsFromScene : Dictionary[String, ArenaObstacleGrid] = {};
var variants : Dictionary[String, ArenaObstacleGrid] = {};
var obstaclesNode : ArenaObstacleGrid;
var currentVariant := "None";
var usedVariants := [];

func _ready():
	prep_dict();

func prep_dict():
	for variantKey in variantsFromFile:
		var variant = variantsFromFile[variantKey];
		if FileAccess.file_exists(variant):
			var scn = load(variant);
			var instance = scn.instantiate();
			if instance is ArenaObstacleGrid:
				variants[variantKey] = instance;
	for variantKey in variantsFromScene:
		var variant = variantsFromScene[variantKey];
		if is_instance_valid(variant):
			if variant is ArenaObstacleGrid:
				variants[variantKey] = variant;
				if variant.is_inside_tree():
					variant.get_parent().remove_child(variant);
	variantsFromFile.clear();
	variantsFromScene.clear();

func destroy_current_obstacles():
	if is_instance_valid(obstaclesNode):
		obstaclesNode.queue_free();

func get_current_variant():
	return currentVariant;

func load_variant(nameOfVariant := currentVariant) -> int:
	var pauseAmt = 1;
	if (currentVariant != nameOfVariant) or (nameOfVariant == "Empty"):
		print("STATE: Loading Arena variant ",nameOfVariant)
		if variants.keys().has(nameOfVariant):
			var obstaclesVariant = variants[nameOfVariant];
			
			if is_instance_valid(obstaclesVariant):
				if obstaclesVariant is ArenaObstacleGrid:
					## Reset spawning locations, since the new variant is likely to have new ones.
					clear_spawning_locations();
					
					var new = obstaclesVariant.duplicate();
					
					if new is ArenaObstacleGrid:
						
						## Delete the old obstacles.
						destroy_current_obstacles();
						
						add_child(new, true);
						new.show();
						
						## Set these obstacles as current.
						obstaclesNode = new;
						
						## Set this variant's name as current.
						currentVariant = nameOfVariant;
						
						## Return the amount of obstacles.
						print("STATE: STARTING BUILDING NOW")
						pauseAmt = obstaclesNode.start_building_sequence();
						
	else:
		pass;
	print("STATE: Arena variant went from ",currentVariant, " to ",nameOfVariant)
	
	reset_spawning_locations();
	return pauseAmt;

func load_new_random_variant() -> int:
	usedVariants.append(get_current_variant());
	var newVar = get_random_variant(usedVariants);
	print("STATE: Loading new RANDOM variant.")
	return load_variant(newVar);

func clear_used_variants():
	usedVariants = [];
	currentVariant = "Empty";

## Gets a random variant key from [member variants], excluding* "empty".[br][br]
## * "empty" will be returned if it's the only key in there, or if the table is emptied, for debug purposes.
func get_random_variant(exclusions := []):
	var all = variants.duplicate(true);
	all.erase("Empty");
	for entry in exclusions:
		all.erase(entry);
	if all.is_empty():
		return "Empty";
	var keys = all.keys();
	keys.shuffle(); ##TODO: Seeded outcomes?
	prints("STATE: why", keys);
	return keys.pop_front();



####### SPAWNING STUFF
@export var spawningLocations : Array[RobotSpawnLocation] = [];

func clear_spawning_locations():
	spawningLocations = [];

func reset_spawning_locations():
	clear_spawning_locations();
	for child in Utils.get_all_children("Arena resetting spawning locations", self):
		if child is RobotSpawnLocation:
			spawningLocations.append(child);
	print("STATE: RESETTING ARENA SPAWNERS: ",spawningLocations.size())
	return spawningLocations;

func get_spawning_locations():
	if spawningLocations.is_empty():
		return reset_spawning_locations();
	return spawningLocations;

func return_random_unoccupied_spawn_location():
	var locations : Array[RobotSpawnLocation] = get_spawning_locations().duplicate();
	var unoccupiedLocation = null;
	
	while locations.size() > 0 and unoccupiedLocation == null:
		locations.shuffle();
		var location = locations.pop_front();
		if location.check_is_unoccupied():
			unoccupiedLocation = location;
	return unoccupiedLocation;
