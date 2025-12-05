extends PartActive;

class_name PartRepair

@export var scrapCost = 15;
@export var healing = 2.0;

func stat_registry():
	super();
	register_stat("HealingAmount", healing, StatHolderManager.statIconHealing, StatHolderManager.statTags.Function, StatHolderManager.displayModes.ALWAYS);

func get_healing_amount():
	return get_stat("HealingAmount");

func _process(delta):
	super(delta);
	healing = inventoryNode.get_heal_amount();
	scrapCost = inventoryNode.get_heal_price();
	ammoAmountOverride = "$"+str(scrapCost)
	if ! thisBot.at_max_health() && inventoryNode.is_affordable(scrapCost):
		ammoAmountColorOverride = "utility";
	else:
		ammoAmountColorOverride = "unaffordable";

func _activate():
	if ! thisBot.at_max_health():
		if super():
			if inventoryNode is InventoryPlayer:
				if inventoryNode.is_affordable(scrapCost):
					inventoryNode.heal_from_shop();
					fx(true)
			else:
				fx()
				thisBot.take_damage(-healing);

func can_fire():
	if ! is_instance_valid(thisBot): return false;
	if thisBot.at_max_health(): return false;
	if ! inventoryNode.is_affordable(scrapCost): return false;
	return super();

func fx(player:=false):
	var pos = thisBot.body.global_position
	var parent = GameState.get_game_board()
	if player:
		ParticleFX.play("NutsBolts", parent, pos)
		SND.play_sound_nondirectional("Shop.Chaching", 1, randf_range(0.90,1.1));
	else:
		ParticleFX.play("NutsBolts", parent, pos)
		SND.play_sound_at("Shop.Chaching", pos);
