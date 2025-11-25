extends Control
class_name ShopStation

var player : Robot_Player; ## The player.
@export var manager : ShopManager; ## The manager.
@export var shopDoor : NinePatchRect; ## The big door.
@export var shopDoorWindow : Control;
var shopDoorVelocity := 0.0; ## The door's Y velocity for its fancy animation.
var shopDoorPrevPosY := 0.0; ## THe door's previous Y position.
var doorOpen := false; ## Set by [method clopen_door].
var doorActuallyClosed := true; ## Is set to true if the 
var doorStomps := 9; ## How many times the door should stomp when it closes.
var thumping := true; ## @deprecated: Not used.
var shopOpen := false; ## Set when [method close_up_shop] or [method open_up_shop] is called.

var awaiting_reroll := false; ## If this is true, the next time all shop stalls are closed, all the stalls have their contents refreshed.

@export var lbl_reroll : ScrapLabel;
@export var btn_reroll : Button;

func _ready():
	shopOpen = false;
	reset_shop();
	shopDoor.show();
	shopDoor.size.y = size.y;
	if ! btn_reroll.is_connected("pressed", _on_reroll_button_pressed):
		btn_reroll.connect("pressed", _on_reroll_button_pressed);

var stallDoorActionSteppy := 0;

func _physics_process(delta):
	for stall in stalls:
		if ! stall.is_connected("thingSelected", stall_thing_selected):
			stall.connect("thingSelected", stall_thing_selected);
	if is_node_ready():
		##Fancy door shutting
		var makeThump = false;
		if doorOpen && !is_equal_approx(shopDoor.position.y, -shopDoor.size.y):
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
		
		shopDoor.position.y = clamp(shopDoor.position.y + shopDoorVelocity, -shopDoor.size.y, 0);
		
		lbl_reroll.update_amt(manager.get_reroll_price());
		#print(stallClopenQueued)
		match stallClopenQueued:
			true:
				if ! all_stalls_open_or_frozen():
					clopen_stalls(true);
				else:
					stallClopenQueued = null;
			false:
				clopen_stalls(false);
				if all_stalls_closed_or_frozen():
					if awaiting_reroll and shopOpen:
						awaiting_reroll = false;
						reroll_shop();
						stallClopenQueued = true;
			null:
				pass;
		
		


## Deselects all [ShopStall] children.
func deselect():
	for stall in get_children():
		if stall is ShopStall:
			stall.deselect();

## Clears out all stalls and resets the item pool.
func reset_shop():
	clopen_door(false);
	clear_shop_stalls(true);
	new_round(-1);

## Opens this shop up, and rerolls it once. Only run once at the start of the shop.
func open_up_shop():
	if !shopOpen:
		reroll_shop();
		clopen_door(true);
		shopOpen = true;
		stallClopenQueued = true;
## Queues a stall open/close the next time they are able to do so.
var stallClopenQueued = null;
## Opens or closes all shop stalls that are able to be closed/opened.
func clopen_stalls(open:bool):
	if open:
		for stall in stalls:
			if stall is ShopStall:
				stall.queue_clopen(true);
	else:
		for stall in stalls:
			if stall is ShopStall:
				stall.queue_clopen(false);

## Closes the shop, then sets the new wave of items.
func new_round(roundNumber:int):
	set_item_pool_waves(roundNumber);
	close_up_shop();

## Closes the door and all unfrozen stalls. Only run once at the end of the shop.
func close_up_shop():
	clopen_door(false);
	shopOpen = false;
	stallClopenQueued = false;

## Opens or closes the big door.
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

## Called when the door is decreed to be "actually closed", which is when its fancy animation is done playing as we leave the shop.
func door_closed():
	doorActuallyClosed = true;
	door_closed_sound(0.9);

## PLays the sound for the door closing.
func door_closed_sound(volume := 1.0):
	if GameState.get_in_state_of_play():
		var pitchMod = randf_range(0.7, 1.3)
		SND.play_sound_nondirectional("Shop.Door.Thump", volume, pitchMod);

## Returns true if we're not paused, we have at least one unfrozen stall, we're not too broke to reroll, and we're not already anticipating a reroll.
func can_reroll():
	print(all_stalls_frozen())
	return not GameState.is_paused() and not all_stalls_frozen() and ScrapManager.is_affordable(manager.get_reroll_price()) and not awaiting_reroll;

## Fires when the reroll button is pressed.[br]
## Checks if we can reroll, then closes the stalls and queues a reroll.
func _on_reroll_button_pressed():
	if can_reroll():
		stallClopenQueued = false;
		awaiting_reroll = true;
		Hooks.OnRerollShop();
		SND.play_sound_2D("Shop.Chaching", btn_reroll.global_position);
	pass # Replace with function body.

## Returns true if all [ShopStall] children are frozen, and false if not.
func all_stalls_frozen() -> bool:
	for stall in stalls:
		if stall is ShopStall:
			if ! stall.is_frozen():
				return false;
	return true;

## Returns false if any [ShopStall] child is not closed.
func all_stalls_closed() -> bool:
	for stall in stalls:
		if stall is ShopStall:
			if ! stall.doors_actually_closed():
				return false;
	return true;

## Returns false if any [ShopStall] child is not closed or frozen.
func all_stalls_closed_or_frozen() -> bool:
	for stall in stalls:
		if stall is ShopStall:
			if ! (stall.doors_actually_closed() or stall.is_frozen()):
				return false;
	return true;

## Returns false if any [ShopStall] child is closed.
func all_stalls_open() -> bool:
	for stall in stalls:
		if stall is ShopStall:
			if stall.doors_actually_closed():
				return false;
	return true;

## Returns false if any [ShopStall] child is closed.
func all_stalls_open_or_frozen() -> bool:
	for stall in stalls:
		if stall is ShopStall:
			if stall.is_frozen():
				pass;
			elif stall.doors_actually_closed():
				return false;
	return true;

## Clears out all [ShopStall] children.
func clear_shop_stalls(ignoreFrozen := false):
	for stall in stalls:
		if stall is ShopStall:
			clear_shop_stall(stall, ignoreFrozen);

## Clears out a specific [ShopStall].
func clear_shop_stall(stall:ShopStall, ignoreFrozen := false):
	if is_instance_valid(stall):
		stall.destroy_contents(ignoreFrozen);

## The pool of things currently available for this shop station, as a list of scenes and weights.
var partPool := {};
## The pool of things currently available for this shop station, as an [Array] of scenes, with each scene showing up- as manyh times as its weight decrees.
var partPoolCalculated := [];

## CLears out the entire pool.
func clear_shop_spawn_list():
	partPool.clear();

## Adds a part scene to the pool.
func add_part_to_spawn_list(_scene : String, weightOverride := -99, recalculate := false):
	if FileAccess.file_exists(_scene):
		var scene = load(_scene);
		var part = scene.instantiate();
		if part is Part or part is Piece:
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

## Calculates the item pool.
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

## Returns a string representing the current pool.
func translated_part_pool():
	var poolDict = {}
	var pool = partPoolCalculated.duplicate();
	var lastPart = null;
	for part in pool:
		var partInst = part.instantiate();
		var partName = ""
		if partInst is Part:
			partName = partInst.partName;
		elif partInst is Piece:
			partName = partInst.pieceName;
		if lastPart == part:
			poolDict[partName] += 1;
		else:
			poolDict[partName] = 0;
		lastPart = part;
		partInst.queue_free();
	return poolDict;

enum poolTypes {
	PARTS,
	CONSTRUCTION,
	BATTLE,
	TEST
}
@export var myPool := poolTypes.TEST;

func set_item_pool_waves(inWave:int):
	print_rich("[b]Setting item pool for wave ", inWave)
	var changed = false;
	
	if inWave == -1:
		clear_shop_spawn_list();
		inWave = 0;
	
	match myPool:
		poolTypes.PARTS:
			match inWave:
				0:
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
				3:
					##Pieces
					
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
		poolTypes.CONSTRUCTION:
			match inWave:
				0:
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_con_corner_small.tscn");
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_con_L_Block_2.tscn");
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_con_pipe_right_long.tscn");
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_con_pipe_right_short.tscn");
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_con_spacer_0.tscn");
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_con_spacer_1.tscn");
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_con_spacer_2.tscn");
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_con_T_Junction.tscn");
					
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_swivel_manual.tscn");
					#add_part_to_spawn_list();
					changed = true;
		poolTypes.BATTLE:
			match inWave:
				0:
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_cannon.tscn");
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_cannon_sniper.tscn");
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_dvd_launcher.tscn");
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_rocket.tscn");
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_shield_face.tscn");
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_horn.tscn");
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_bumper.tscn");
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_sawblade.tscn");
					
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_swivel_pointer.tscn");
		poolTypes.TEST:
			match inWave:
				0:
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_con_spacer_0.tscn");
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_cannon_peashooter.tscn");
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_con_pipe_right_long.tscn");
					add_part_to_spawn_list("res://scenes/prefabs/objects/pieces/piece_dvd_launcher.tscn");
					changed = true;
	if changed: 
		calculate_part_pool();

func return_random_part() -> PackedScene:
	var pool = partPoolCalculated.duplicate();
	var sceneReturn = pool.pick_random();
	return sceneReturn;

var stalls = []:
	get:
		var ret = []
		for stall in shopDoorWindow.get_children():
			if stall is ShopStall:
				ret.append(stall);
		return ret;

func reroll_shop():
	clear_shop(true);
	var counter = 0;
	while (next_empty_shop_stall() != null) and counter < stalls.size():
		var thing: = return_random_part();
		if is_instance_valid(thing):
			var sceneString = thing.resource_path;
			add_thing_to_shop(sceneString);
			counter += 1;

func add_thing_to_shop(_partScene:String):
	var partScene = load(_partScene);
	var part = partScene.instantiate();
	var result = false;
	if part is Part:
		result = add_part_to_shop(part)
	if part is Piece:
		result = add_piece_to_shop(part)
	
	if ! result:
		part.queue_free();

func add_part_to_shop(inPart : Part):
	var stall = next_empty_shop_stall();
	if is_instance_valid(stall):
		if stall.has_ref():
			print("No part is to be placed here!!! (", stall.name,")")
			return false
		var part:Part = inPart;
		print(stall.partRef)
		inPart.hostShopStall = stall;
		inPart.hostRobot = GameState.get_player();
		inPart.inPlayerInventory = true;
		inPart.invHolderNode = stall;
		if inPart is PartActive:
			inPart.set_equipped(false);
		stall.partRef = inPart;
		
		print(stall.partRef)
		#part.
		print("Adding ", part.partName, " to shop stall ", stall.name)
		inPart.inventory_vanity_setup();
		add_child(part);
		return true;
	return false;
	pass

func add_piece_to_shop(inPiece : Piece):
	var stall = next_empty_shop_stall();
	if is_instance_valid(stall):
		if stall.has_ref():
			print("No piece is to be placed here!!! (", stall.name,")")
			return false
		stall.add_piece(inPiece);
		
		print("Adding ", inPiece.pieceName, " to shop stall ", stall.name)
		return true;
		pass;
	return false;

## Returns the next [ShopStall] in [member stalls] which is empty.
func next_empty_shop_stall() -> ShopStall:
	for stall in stalls:
		if stall.is_empty():
			return stall;
	return null;

@export var StallA : ShopStall;
@export var StallB : ShopStall;
@export var StallC : ShopStall;

## Clears all stalls, with the option to reroll afterwards.
func clear_shop(ignoreFrozen := false, reroll := false):
	
	clear_shop_stalls(ignoreFrozen);
	
	if reroll:
		reroll_shop();

func stall_thing_selected(selectedStall : ShopStall):
	for stall in stalls:
		if stall != selectedStall:
			stall.deselect();
