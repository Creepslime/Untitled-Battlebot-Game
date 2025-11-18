extends Control
class_name ShopStation

var player : Robot_Player;
@export var manager : ShopManager;

@export var shopDoor : TextureRect;
var shopDoorVelocity := 0.0;
var shopDoorPrevPosY := 0.0;
var doorOpen := false;
var doorActuallyClosed := true;
var doorStomps := 9;
var thumping := true;
var shopOpen := false;

var awaiting_reroll := false;


func _ready():
	reset_shop();

func _physics_process(delta):
	if is_node_ready():
		##Fancy door shutting
		var makeThump = false;
		if doorOpen && !is_equal_approx(shopDoor.position.y, -237):
			shopDoorVelocity = move_toward(shopDoorVelocity, -10, delta*100);
		else:
			shopDoorVelocity += 9.87 * delta;
			if (shopDoor.position.y + shopDoorVelocity) > 0:
				shopDoor.position.y = 0;
				shopDoorVelocity *= -0.3;
				makeThump = true;
				if not doorActuallyClosed:
					door_closed();
				else:
					if doorStomps < 1:
						doorStomps += 1;
						door_closed_sound(0.7);
					else:
						if doorStomps < 2:
							doorStomps += 1;
							door_closed_sound(0.5);
						else:
							if doorStomps < 3:
								doorStomps += 1;
								#inventory.inventory_panel_toggle(false);
		
		shopDoor.position.y = clamp(shopDoor.position.y + shopDoorVelocity, -237, 0);
		
		
		if awaiting_reroll:
			if all_stalls_closed():
				awaiting_reroll = false;
				reroll_shop();
				if shopOpen:
					clopen_stalls(true);





func deselect():
	for stall in get_children():
		if stall is ShopStall:
			stall.deselect();

func reset_shop():
	new_round(-1);

## Opens this hop up. Only run once at the start of the shop.
func open_up_shop():
	clopen_door(true);
	shopOpen = true;
	clopen_stalls(true);

func clopen_stalls(open:bool):
	if open:
		for stall in get_children():
			if stall is ShopStall:
				stall.open_stall();
	else:
		for stall in get_children():
			if stall is ShopStall:
				stall.close_stall();


## Closes the shop.
func new_round(roundNumber:int):
	set_item_pool_waves(roundNumber);
	close_up_shop();
	reroll_shop();

func close_up_shop():
	clopen_door(false);
	shopOpen = false;
	clopen_stalls(false);

func clopen_door(open:=false):
	if open:
		if ! doorOpen:
			SND.play_sound_nondirectional("Shop.Door.Open", 1.0, 2.0)
		doorOpen = true;
		doorActuallyClosed = false;
		doorStomps = 0;
	else:
		doorOpen = false;
		shopDoorVelocity = 0;

func door_closed():
	reroll_shop();
	doorActuallyClosed = true;
	door_closed_sound(0.9);

func door_closed_sound(volume := 1.0):
	if GameState.get_in_state_of_play():
		var pitchMod = randf_range(0.7, 1.3)
		SND.play_sound_nondirectional("Shop.Door.Thump", volume, pitchMod);


func can_reroll():
	return not GameState.is_paused() and ScrapManager.is_affordable(manager.get_reroll_price()) and not awaiting_reroll and not all_stalls_frozen();

func _on_reroll_button_pressed():
	if can_reroll():
		clopen_stalls(false);
		awaiting_reroll = true;
		Hooks.OnRerollShop();
	pass # Replace with function body.

func all_stalls_frozen() -> bool:
	var count = 0;
	for stall in get_children():
		if stall is ShopStall:
			if stall.is_frozen():
				count += 1;
				if count >= 3:
					return true;
	return false;

func all_stalls_closed() -> bool:
	for stall in get_children():
		if stall is ShopStall:
			if ! stall.doors_actually_closed():
				return false;
	return true;

func clear_shop_stalls():
	for stall in get_children():
		if stall is ShopStall:
			if ! stall.doors_actually_closed():
				return false;
	return true;

func clear_shop_stall(stall:ShopStall, ignoreFrozen := false):
	if is_instance_valid(stall):
		if is_instance_valid(stall.partRef): ## Destroys whatever part was in here.
			if ignoreFrozen:
				stall.freeze(false);
				stall.partRef.destroy();
			else:
				if (stall.curState != ShopStall.doorState.FROZEN): ## Destroys whatever part was in here.
					#print(stall.name + " is NOT frozen")
					stall.partRef.destroy();



##The pool of parts currently available
var partPool := {};
var partPoolCalculated := [];

func clear_shop_spawn_list():
	partPool.clear();

func add_part_to_spawn_list(_scene : String, weightOverride := -99, recalculate := false):
	var scene = load(_scene);
	var part = scene.instantiate();
	var weight = 1;
	if is_instance_valid(weightOverride) && weightOverride != -99:
		weight = weightOverride;
	else:
		weight = part.poolWeight;
	var rarity = part.myPartRarity;
	if scene in partPool.keys():
		if partPool[scene]:
			if partPool[scene]["weight"]:
				partPool[scene]["weight"] += weight;
				if partPool[scene]["weight"] && partPool[scene]["weight"]  <= 0:
					partPool.erase(scene);
	else:
		partPool[scene] = {"weight":weight,"rarity":rarity};
	part.queue_free();
	if recalculate:
		calculate_part_pool()

func calculate_part_pool():
	var pool = []
	var spawnListCopy = partPool.duplicate(true);
	for scene in spawnListCopy.keys():
		var weight = spawnListCopy[scene]["weight"];
		var rarity = spawnListCopy[scene]["rarity"];
		
		if rarity == Part.partRarities.COMMON:
			weight *= 15
		elif rarity == Part.partRarities.UNCOMMON:
			weight *= 10
		elif rarity == Part.partRarities.RARE:
			weight *= 5
		
		while weight > 0:
			pool.append(scene);
			weight -= 1;
	partPoolCalculated = pool;
	print_rich("[color=yellow]",translated_part_pool());

func translated_part_pool():
	var poolDict = {}
	var pool = partPoolCalculated.duplicate();
	var lastPart;
	for part in pool:
		var partInst = part.instantiate();
		var partName = partInst.partName;
		if lastPart == part:
			poolDict[partName] += 1;
		else:
			poolDict[partName] = 0;
		lastPart = part;
		partInst.queue_free();
	return poolDict;

func set_item_pool_waves(inWave:int):
	print_rich("[b]Setting item pool for wave ", inWave)
	var changed = false;
	if inWave == -1:
		clear_shop_spawn_list();
		inWave = 0;
	if inWave == 0:
		##passives
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_RoundBell.tscn", 2);
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_impact_generator.tscn", 1);
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_impact_magnet.tscn", 1);
		##passives with adjacenty bonuses
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_fan.tscn", 2);
		##Batteries
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/batteries/part_jank_battery.tscn", 2);
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/batteries/battery_1x1.tscn", 3);
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/batteries/battery_1x2.tscn", 2);
		##melee
		#add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_sawblade.tscn", 1);
		##ranged
		#add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_cannon.tscn", 1);
		#add_part_to_spawn_list("res://scenes/prefabs/objects/parts/enemyParts/part_ranger_gun.tscn", 3);
		##utility
		##trap
			#none yet lol
		changed = true;
	if inWave == 3:
		##Passives
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/scrapthirsty.tscn");
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/turtle_coil.tscn");
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_coolant.tscn");
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_scrap_plating.tscn", 1);
		##Batteries
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/batteries/battery_1x3.tscn", 1);
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/batteries/battery_2x3.tscn", 1);
		##Ranged
		#add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_peashooter.tscn", 1);
		#add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_sniper.tscn", 1);
		##Utility
		#add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_repair.tscn");
		#add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_dash.tscn");
		#add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_jump.tscn");
		changed = true;
		
	if changed: 
		calculate_part_pool();

func return_random_part() -> PackedScene:
	var pool = partPoolCalculated.duplicate();
	var sceneReturn = pool.pick_random();
	return sceneReturn;

var slots = {
	"StallA" = null,
	"StallB" = null,
	"StallC" = null,
}

func reroll_shop():
	clear_shop();
	var counter = 0;
	while (next_empty_shop_stall() != null) and counter < 4:
		var thing: = return_random_part();
		if is_instance_valid(thing):
			var sceneString = thing.resource_path;
			add_part_to_shop(sceneString);
			counter += 1;

func add_part_to_shop(_partScene:String):
	var stall = next_empty_shop_stall();
	if is_instance_valid(stall):
		if is_instance_valid(stall.partRef):
			print("No part is to be placed here!!! (", stall.name,")")
			slots[str(stall.name)] = stall.partRef;
			return
		var partScene = load(_partScene);
		var part:Part = partScene.instantiate();
		print(stall.partRef)
		part.hostShopStall = stall;
		part.thisRobot = GameState.get_player();
		part.inPlayerInventory = true;
		part.invHolderNode = stall;
		if part is PartActive:
			part.set_equipped(false);
		stall.partRef = part;
		slots[str(stall.name)] = part;
		print(stall.partRef)
		#part.
		print("Adding ", part.name, " to shop stall ", stall.name)
		part.inventory_vanity_setup();
		add_child(part);
	pass

func next_empty_shop_stall():
	if !is_instance_valid(slots["StallA"]):
		if ! StallA.is_frozen():
			return StallA;
	if !is_instance_valid(slots["StallB"]):
		if ! StallB.is_frozen():
			return StallB;
	if !is_instance_valid(slots["StallC"]):
		if ! StallC.is_frozen():
			return StallC;
	return null;

@export var StallA : ShopStall;
@export var StallB : ShopStall;
@export var StallC : ShopStall;

func clear_shop(ignoreFrozen := false, reroll := false):
	clear_shop_stall(StallA, ignoreFrozen);
	clear_shop_stall(StallB, ignoreFrozen);
	clear_shop_stall(StallC, ignoreFrozen);
	
	if reroll:
		reroll_shop();
