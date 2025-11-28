extends Control

class_name Shop

var inventory : InventoryPlayer;
var player : Robot_Player;

var shopDoor : TextureRect;
var shopDoorVelocity := 0.0;
var shopDoorPrevPosY := 0.0;
var doorOpen := false;
var doorActuallyClosed := true;
var doorStomps := 9;
var thumping := true;
var shopOpen := false;

var awaiting_reroll := false;

func _ready():
	inventory = GameState.get_inventory();
	player = GameState.get_player();
	shopDoor = $ShopDoor;
	reset_shop();

func deselect():
	for stall in get_children():
		if stall is ShopStall:
			stall.deselect();

func reset_shop():
	set_item_pool_waves(-1);
	rerollPriceIncrementPermanent = 0;
	rerollPriceIncrement = 0;
	healPriceIncrementPermanent = 0;
	healPriceIncrement = 0;
	close_up_shop();

func set_item_pool_waves(inWave:int):
	#print_rich("[b]Setting item pool for wave ", inWave)
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
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_sawblade.tscn", 1);
		##ranged
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_cannon.tscn", 1);
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/enemyParts/part_ranger_gun.tscn", 3);
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
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_peashooter.tscn", 1);
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_sniper.tscn", 1);
		##Utility
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_repair.tscn");
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_dash.tscn");
		add_part_to_spawn_list("res://scenes/prefabs/objects/parts/playerParts/part_jump.tscn");
		changed = true;
		
	if changed: 
		calculate_part_pool();

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

func new_round(roundNumber:int):
	set_item_pool_waves(roundNumber);
	close_up_shop();

func close_up_shop():
	clopen_door();
	shopOpen = false;
	clopen_stalls(false);

func clopen_door(open:=false):
	if open:
		doorOpen = true;
		doorActuallyClosed = false;
		doorStomps = 0;
		SND.play_sound_nondirectional("Shop.Door.Open", 1.0, 2.0)
	else:
		doorOpen = false;
		shopDoorVelocity = 0;

func _physics_process(delta):
	if is_node_ready():
		update_health_button();
		update_reroll_button();
		
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
								inventory.inventory_panel_toggle(false);
		
		shopDoor.position.y = clamp(shopDoor.position.y + shopDoorVelocity, -237, 0);
		
		
		if awaiting_reroll:
			if all_stalls_closed():
				awaiting_reroll = false;
				reroll_shop();
				if shopOpen:
					clopen_stalls(true);

func door_closed():
	reroll_shop();
	rerollPriceIncrementPermanent += 0.5;
	rerollPriceIncrement = rerollPriceIncrementPermanent;
	healPriceIncrementPermanent += 0.5;
	healPriceIncrement = healPriceIncrementPermanent;
	doorActuallyClosed = true;
	door_closed_sound(0.9);

func door_closed_sound(volume := 1.0):
	if GameState.get_in_state_of_play():
		if !inventory.inventoryUp:
			volume *= 0.5
		var pitchMod = randf_range(0.7, 1.3)
		SND.play_sound_nondirectional("Shop.Door.Thump", volume, pitchMod);

var healAmountBase := 0.5;
var healAmountModifier := 1.0;
var healPriceBase := 4.0;
var healPriceModifier := 1.0;
var healPricePressIncrement := 2.0;
var healPriceIncrement := 0.0;
var healPriceIncrementPermanent := 0.0;

func update_health_button():
	$HealButton/TextHolder/HEAL.text = "HEAL\n"+TextFunc.format_stat(get_heal_amount()) + " HP"
	$HealButton/TextHolder/Price.text = TextFunc.format_stat(get_heal_price(), 0);
	if inventory.is_affordable(get_heal_price()) && ! player.at_max_health():
		TextFunc.set_text_color($HealButton/TextHolder/Price, "scrap");
	else:
		TextFunc.set_text_color($HealButton/TextHolder/Price, "unaffordable");

func get_heal_amount():
	return (healAmountBase * healAmountModifier) * player._get_combat_handler().get_max_health();
func get_heal_price():
	return floori((healPriceBase + healPriceIncrement) * healPriceModifier);

func _on_heal_button_pressed():
	var healed = _shop_heal();
	if healed:
		SND.play_sound_nondirectional("Shop.Chaching", 1, randf_range(0.90,1.1));;
	pass # Replace with function body.

func _shop_heal():
	if inventory.is_affordable(get_heal_price()):
		if ! player.at_max_health():
			inventory.remove_scrap(get_heal_price(), "ShopHeal");
			healPriceIncrement += healPricePressIncrement;
			player.heal(get_heal_amount());
			healPriceIncrementPermanent += 0.5;
			return true;


var rerollPriceBase := 5.0;
var rerollPriceModifier := 1.0;
var rerollPricePressIncrement := 1.0;
var rerollPriceIncrement := 0.0;
var rerollPriceIncrementPermanent := 0.0;

func update_reroll_button():
	$RerollButton/TextHolder/Price.text = TextFunc.format_stat(get_reroll_price(), 0);
	if inventory.is_affordable(get_reroll_price()) and not all_stalls_frozen():
		TextFunc.set_text_color($RerollButton/TextHolder/Price, "scrap");
	else:
		TextFunc.set_text_color($RerollButton/TextHolder/Price, "unaffordable");

func get_reroll_price():
	return floori((rerollPriceBase + rerollPriceIncrement) * rerollPriceModifier);

func _on_reroll_button_pressed():
	if (inventory.is_affordable(get_reroll_price())) and not awaiting_reroll and not all_stalls_frozen():
		
		inventory.remove_scrap(get_reroll_price(), "ShopReroll");
		rerollPriceIncrement += rerollPricePressIncrement;
		clopen_stalls(false);
		awaiting_reroll = true;
		rerollPriceIncrementPermanent += 0.25;
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
	#print_rich("[color=yellow]",translated_part_pool());

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

func return_random_part() -> PackedScene:
	var pool = partPoolCalculated.duplicate();
	var sceneReturn = pool.pick_random();
	return sceneReturn;

func reroll_shop():
	inventory.clear_shop();
	var counter = 0;
	while (inventory.next_empty_shop_stall() != null) and counter < 4:
		var part: = return_random_part();
		if is_instance_valid(part):
			var sceneString = part.resource_path;
			inventory.add_part_to_shop(sceneString);
			counter += 1;
