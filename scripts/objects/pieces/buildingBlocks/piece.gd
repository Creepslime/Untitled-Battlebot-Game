
@icon ("res://graphics/images/class_icons/piece.png")

extends StatHolder3D

class_name Piece
## A 3D chunk of scrap electronics you found or bought and decided was a good idea to slap onto your [Robot].
## Can hold Stats (as per [StatHolder3D]) and [Part]s (TODO).

########## STANDARD GODOT PROCESSING FUNCTIONS
func _ready():
	if temporaryPreview:
		queue_free();
		return;
	
	if ! Engine.is_editor_hint():
		#if pieceName == "BodyCube":
			#print("BODYCUBE IS READYING!")
		hide();
		declare_names();
		assign_references();
		ability_validation();
		ability_registry();
		regen_namedActions(); ## Regenerates the actions list
		super(); #Stat registry.
		gather_colliders_and_meshes();
		is_ready = true;

func _physics_process(delta):
	if temporaryPreview:
		queue_free();
	
	if ! Engine.is_editor_hint():
		super(delta);
		if not is_paused():
			fix_sockets(delta);
			phys_process_collision(delta);
			phys_process_abilities(delta);

func _process(delta):
	process_draw(delta);

func stat_registry():
	## Stats regarding energy cost.
	register_stat("PassiveEnergyDraw", energyDrawPassiveBaseOverride, StatHolderManager.statIconEnergy, StatHolderManager.statTags.Battery, StatHolderManager.displayModes.ABOVE_ZERO);
	register_stat("PassiveEnergyRegeneration", 0.0, StatHolderManager.statIconEnergy, StatHolderManager.statTags.Battery, StatHolderManager.displayModes.ABOVE_ZERO);
	register_stat("PassiveCooldown", passiveCooldownTimeMultiplier, StatHolderManager.statIconCooldown, StatHolderManager.statTags.Clock);
	register_stat("ContactCooldown", contactCooldown, StatHolderManager.statIconCooldown, StatHolderManager.statTags.Clock);
	
	## Stats that only matter if the thing has abilities.
	if activeAbilitiesDistributed.size() > 0:
		register_stat("ActiveEnergyDraw", energyDrawActiveMultiplier, StatHolderManager.statIconEnergy, StatHolderManager.statTags.Battery);
		register_stat("ActiveCooldown", activeCooldownTimeMultiplier, StatHolderManager.statIconCooldown, StatHolderManager.statTags.Clock);
	
	## Stats regarding Scrap Cost.
	register_stat("ScrapCost", scrapCostBase, StatHolderManager.statIconScrap, StatHolderManager.statTags.Worth, StatHolderManager.displayModes.ALWAYS, StatHolderManager.roundingModes.Ceili);
	register_stat("ScrapSellModifier", scrapSellModifierBase, StatHolderManager.statIconScrap, StatHolderManager.statTags.Worth, StatHolderManager.displayModes.ALWAYS);
	register_stat("ScrapSalvageModifier", scrapSalvageModifierBase, StatHolderManager.statIconScrap, StatHolderManager.statTags.Worth, StatHolderManager.displayModes.NEVER);
	register_stat("Weight", weightBase, StatHolderManager.statIconWeight, StatHolderManager.statTags.Hull);
	register_stat("Integrity", 1.0, StatHolderManager.statIconHeart, StatHolderManager.statTags.Hull);
	
	## Stats regarding damage.
	register_stat("Damage", damageBase, StatHolderManager.statIconDamage, StatHolderManager.statTags.Weaponry, StatHolderManager.displayModes.ABOVE_ZERO);
	register_stat("Knockback", knockbackBase, StatHolderManager.statIconWeight, StatHolderManager.statTags.Weaponry, StatHolderManager.displayModes.ABOVE_ZERO);
	register_stat("Kickback", kickbackBase, StatHolderManager.statIconWeight, StatHolderManager.statTags.Function, StatHolderManager.displayModes.NOT_ZERO);
	
	## Stuff regarding materials and defense.
	set_up_material_group_and_damage_immunities()

##This is here for when things get out of whack and some of the export variables disconnect themselves for no good reason.
func assign_references():
	var allOK = true;
	if !is_instance_valid(placementCollisionHolder):
		if is_instance_valid($"PlacementShapes [Leave empty]"):
			placementCollisionHolder = $"PlacementShapes [Leave empty]";
			pass;
		else:
			allOK = false;
	if !is_instance_valid(hurtboxCollisionHolder):
		if is_instance_valid($"HurtboxShapes [Leave empty]"):
			hurtboxCollisionHolder = $"HurtboxShapes [Leave empty]";
			pass;
		else:
			allOK = false;
	if !is_instance_valid(hitboxCollisionHolder):
		if is_instance_valid($"HitboxShapes [Leave empty]"):
			hitboxCollisionHolder = $"HitboxShapes [Leave empty]";
			pass;
		else:
			allOK = false;
		
	if is_instance_valid(hitboxCollisionHolder):
		if not hitboxCollisionHolder.is_connected("body_shape_entered", _on_hitbox_body_shape_entered):
			hitboxCollisionHolder.connect("body_shape_entered", _on_hitbox_body_shape_entered);
		if not hitboxCollisionHolder.is_connected("area_shape_entered", _on_hitbox_shapes_area_entered):
			hitboxCollisionHolder.connect("area_shape_entered", _on_hitbox_shapes_area_entered);
			pass;
	if !is_instance_valid(meshesHolder):
		if is_instance_valid($"Meshes"):
			meshesHolder = $"Meshes";
			pass;
		else:
			allOK = false;
	if !is_instance_valid(femaleSocketHolder):
		if is_instance_valid($"FemaleSockets"):
			femaleSocketHolder = $"FemaleSockets";
			pass;
		else:
			allOK = false;
	
	if not allOK:
		#print("References for piece ", name, " were invalid. ")
		queue_free();

func destroy(removeFromSocket := true):
	select(false);
	clear_stats();
	if removeFromSocket:
		if has_host(true, false, false):
			get_host_socket().remove_occupant(true);
	queue_free();

######### SAVING/LOADING

##Creates a dictionary with data pertinent to generating a new piece.
## TODO: This will NOT currently save the contents of each Piece's Engine.[br]
##current format should be:
##[codeblock]
##{ 
##   file_path[float] : { 
##      "engine" : { TODO: Figure out engine data formatting },
##      "sockets" : { 
##         socket_index[int] : { 
##         "rotation" : float, 
##         "occupant" : null or Piece.create_startup_data() } 
##      },
##      "abilityAssignments" : { abilityName : slot }, ## Any abilities on this Piece that were assigned to an active slot.
##      "disabledAbilities" : [ abilityName, abilityName, ... ] ## Disabled abilities on this Piece.
##   } 
##} 
##[/codeblock]
func create_startup_data():
	var engineDict = {};
	##TODO: Part data goes here
	var socketDict = {};
	for socket:Socket in get_all_female_sockets():
		var index = get_index_of_socket(socket);
		var rotationVal = socket.rotation;
		var occupantResult = socket.get_occupant();
		var occupantVal;
		if occupantResult != null:
			occupantVal = occupantResult.create_startup_data();
		else:
			occupantVal = "null";
		var socketData = { "rotation" : rotationVal, "occupant" : occupantVal};
		socketDict[index] = socketData;
	
	## Abilities. If an ability has been assigned to a slot and is not passive, add its name and assigned engineSlots to the data.
	var abilityDict := {}
	var disabled := []
	for ability in get_all_abilities():
		if ! ability.isPassive:
			var slots = ability.get_assigned_slots(statHolderID);
			if ! slots.is_empty():
				abilityDict[ability.abilityName] = slots;
		else:
			if ability.is_disabled(statHolderID):
				disabled.append(ability.abilityName);
	
	var data = {
			#"engine" : engineDict,
			"sockets" : socketDict,
			"abilityAssignments" : abilityDict,
			"disabledAbilities" : disabled,
		}
	
	var dict = { filepathForThisEntity : data }
	
	return dict;

func load_startup_data(data, robot : Robot):
	print_rich("[color=pink]REALLY INIT ACTIVES:", activeAbilitiesDistributed);
	
	for socketIndex in data["sockets"].keys():
		var socketData = data["sockets"][socketIndex];
		autoassign_child_sockets_to_self();
		var socket = get_socket_at_index(socketIndex);
		if is_instance_valid(socket):
			socket.load_startup_data(socketData, robot);
	
	
	if data.keys().has("abilityAssignments"):
		for abilityName in data["abilityAssignments"].keys():
			var abilitySlots = data["abilityAssignments"][abilityName];
			var ability = get_named_action(abilityName);
			if is_instance_valid(ability):
				for slotNum in abilitySlots:
					robot.assign_ability_to_slot(slotNum, ability.get_ability_data(statHolderID));
	
	## An array of names that are disabled abilities.
	if data.keys().has("disabledAbilities"):
		for abilityName in data["disabledAbilities"]:
			var ability = get_named_action(abilityName);
			if is_instance_valid(ability):
				ability.disable(statHolderID, true);
	pass;

######################## TIMERS

##Any and all timers go here.
func phys_process_timers(delta):
	super(delta);
	##tick down hitbox timer.
	hitboxRescaleTimer -= 1;
	pass;

func phys_process_pre(delta):
	super(delta);
	##Re-assign references, if any are borked.
	assign_references();
	## Reset current energy draw.
	energyDrawCurrent = 0.0;
	## Calculate weightLoad.
	get_weight_load();
	## Refresh incoming energy for the frame.
	queue_refresh_incoming_energy();

################ PIECE MANAGEMENT

@export_category("Piece Data")
@export var pieceName : StringName = "Piece";
##If you don't want to manually type all the bbcode, you can use this to construct the description.
@export var descriptionConstructor : Array[RichTextConstructor] = [];
func declare_names():
	if not descriptionConstructor.is_empty():
		pieceDescription = TextFunc.parse_text_constructor_array(descriptionConstructor);
	pass;
@export_multiline var pieceDescription := "No Description Found.";
@export var pieceMaterial := pieceMaterials.METAL; ## Affects what noise this makes when hitting things. Could also be used for more special interactions.
#### Damage resistances
@export_range(0.0, 999.0) var defenseMultiplierGeneral := 1.0;  ## Generally affects the amount of damage you take when being struck on this piece generally. This is multiplied against incoming damage, so a [member defenseMultiplierGeneral] of 0.5 wil halve inoming damage, for example. 
@export var defenseMultipliers : Dictionary[DamageData.damageTypes, float] = {} ## Multipliers to incoming damage types. If a damage type is left out of this, then there will be no change to that type of damage except for [member damageMultiplierGeneral], which is always applied in addition to specific type defense.
enum pieceMaterials {
	METAL,
	WOOD,
	GLASS,
	PLASTIC,
	CONCRETE,
}
func set_up_material_group_and_damage_immunities():
	add_to_group("Piece")
	
	## Reset all material groups.
	remove_from_group("Metal")
	remove_from_group("Wood")
	remove_from_group("Glass")
	remove_from_group("Plastic")
	remove_from_group("Concrete")
	## Add to a material group based on pieceMaterial.
	match pieceMaterial:
		pieceMaterials.METAL:
			add_to_group("Metal")
		pieceMaterials.WOOD:
			add_to_group("Wood")
		pieceMaterials.GLASS:
			add_to_group("Glass")
		pieceMaterials.PLASTIC:
			add_to_group("Plastic")
		pieceMaterials.CONCRETE:
			add_to_group("Concrete")
	
	register_stat("General Defense", defenseMultiplierGeneral, StatHolderManager.statIconShield, StatHolderManager.statTags.Hull, StatHolderManager.displayModes.IF_MODIFIED);
	for damageTypeID in DamageData.damageTypes.values():
		var typeName = str(DamageData.damageTypes.keys()[damageTypeID]);
		register_stat(str(typeName.capitalize(), " Defense"), defenseMultipliers[damageTypeID] if defenseMultipliers.has(damageTypeID) else 1.0, StatHolderManager.statIconShield, StatHolderManager.statTags.Hull, StatHolderManager.displayModes.IF_MODIFIED)

func get_damage_type_resistance_stat_from_damageType(damageType : DamageData.damageTypes):
	var typeName = str(DamageData.damageTypes.keys()[damageType]);
	var statName = str(typeName.capitalize(), " Defense");
	return max(0, get_stat(statName));
func get_general_incoming_damage_multiplier():
	return max(0, get_stat("General Defense"));
##This function multiplies damage on an incoming 
func modify_damage_based_on_immunities(damageData : DamageData):
	var dmg = damageData.get_damage();
	for type in damageData.tags:
		var multiplier = get_damage_type_resistance_stat_from_damageType(type);
		dmg *= multiplier;
	dmg *= get_general_incoming_damage_multiplier();
	damageData.damageAmount = dmg;
	return damageData;

#### Weight
@export var weightBase := 1.0;

## How much weight this Piece is carrying, including itself.
var weightLoad := 0.0;
## If [member regenerateWeightLoad] is true, then [method get_weight_load()] is forced to regenerate [member weightLoad] the next time it is called.
var regenerateWeightLoad := true;

## Sets [member regenerateWeightLoad] to true. 
func queue_regenerate_weight_load():
	regenerateWeightLoad = true;

## Gets the base weight stat for this piece.
func get_weight():
	return get_stat("Weight");

## Gets [member Socket.weightLoad] from the specified [Socket].
func get_socket_weight_load(specifiedSocket : Socket, forceRegenerate := false):
	if is_instance_valid(specifiedSocket):
		return specifiedSocket.get_weight_load(forceRegenerate);
	return 0.0;

## Returns [member weightLoad]. Regenerates it first if [member regenerateWeightLoad] is true.
func get_weight_load():
	if regenerateWeightLoad:
		var _weight = get_weight();
		for socket in get_all_female_sockets():
			_weight += get_socket_weight_load(socket, true);
		weightLoad = _weight;
		regenerateWeightLoad = false;
	return weightLoad;

func get_regenerated_weight_load():
	queue_regenerate_weight_load();
	return get_weight_load();


@export_category("Technical Data")
@export var force_visibility := false;  
@export var temporaryPreview := false; ## When true, calls [method destroy] at the first possible opportunity.
## If this piece fulfills the requirements for being a bot's "body", this is true. You aren't allowed to exit the shop if you don't have a body piece equipped.
@export var isBody := false;
## Whether this piece is at all removable.
@export var removable := true;
## Returns true if this [Piece] is equipped, removable, and we're shopping.
func is_removable() -> bool:
	return removable and is_equipped() and (GameState.get_in_state_of_shopping() or GameState.get_in_state_of_building());
func is_sellable() -> bool:
	return removable and ! isBody;
func is_buyable() -> bool:
	return ScrapManager.is_affordable(get_buy_price()) and inShop;
var queuedBuyer : Robot = null;
func try_buy_from_shop() -> bool:
	if is_instance_valid(shopStall):
		return shopStall.try_buy_piece();
	return false;
func start_buying(buyer:Robot):
	queuedBuyer = buyer;
	start_buying_animation();
func submit_queued_buy():
	if is_instance_valid(queuedBuyer):
		inShop = false;
		shopStall.buyQueued = false;
		shopStall.pieceRef = null;
		shopStall = null;
		remove_and_add_to_robot_stash(queuedBuyer);
		queuedBuyer = null;
## Tries to sell this [Piece], then returns the result.[br]
## TODO: Determine whether selling a [Piece] should also sell any [Part]s in its engine, or stash them.
func try_sell():
	if is_sellable():
		ScrapManager.add_scrap(get_sell_price(), "Sell Piece");
		destroy();
		return true;
	return false;

@export_subgroup("Shop Data")
@export var poolWeight := 1; ##This is multiplied by 5 when Rare, 10 when Uncommon, and 15 when Common.
@export var myPartRarity := Part.partRarities.COMMON;
@export var scrapCostBase : int;
@export var scrapSellModifierBase := (2.0/3.0);
@export var scrapSalvageModifierBase := (1.0/6.0);
@export var inShop := false; ## Set by [ShopStall] when adding this piece to itself.
var shopStall : ShopStall = null;
##TODO: Scrap sell/buy/salvage functions for when this has Parts inside of it.
func get_sell_price(discountMultiplier := 1.0):
	## TODO: Write this up so it adds the combined sell price of this piece as well as all parts contained within its engine.
	return get_sell_price_piece_only(discountMultiplier);

##Gets the Scrap amount for when you sell this Piece. Does not take into account the price of any Parts inside its Engine.
##discountMultiplier is multiplied by the price.
func get_sell_price_piece_only(discountMultiplier := 1.0):
	return max(0, ceili(get_stat("ScrapCost") * get_stat("ScrapSellModifier") * discountMultiplier));

##Gets the Scrap amount for when the Robot this is attached to dies and you're awarded Scrap. Does not take into account the price of any Parts inside its Engine.
##discountMultiplier is multiplied by the price.
func get_salvage_price_piece_only(discountMultiplier := 1.0):
	return max(0, ceili(get_stat("ScrapCost") * get_stat("ScrapSalvageModifier") * discountMultiplier));

func get_buy_price(discountMultiplier := 1.0, fixedMarkup := 0):
	## TODO: Write this up so it adds the combined buy price of this piece as well as all parts contained within its engine.
	return get_buy_price_piece_only();

##Gets the Scrap amount for attempting to buy this Piece.
##discountMultiplier is multiplied by the price.
##fixedMarkup is added to the price.
func get_buy_price_piece_only(discountMultiplier := 1.0, fixedMarkup := 0):
	discountMultiplier *= ScrapManager.get_discount_for_type(ScrapManager.priceTypes.PIECE);
	var currentPrice = maxi(0, ceili(get_stat("ScrapCost") * discountMultiplier))
	return currentPrice + fixedMarkup;

####################### ABILITY AND ENERGY MANAGEMENT

@export_category("Ability")

@export_subgroup("AbilityManagers")
@export var activeAbilities : Array[AbilityManager] = [];
var activeAbilitiesDistributed : Array[AbilityManager] = [];
@export var passiveAbilities : Array[AbilityManager] = [];
var passiveAbilitiesDistributed : Array[AbilityManager] = [];

@export_subgroup("Ability Details")
@export var hurtboxAlwaysEnabled := false;

@export var input : InputEvent;
@export var energyDrawPassiveMultiplier := 1.0; ##power drawn each frame, multiplied by time delta. If this is negative, it is instead power being generated each frame.
@export var energyDrawActiveMultiplier := 1.0; ##power drawn when you use any this piece's active abilities, given that it has any.
@export var energyDrawActiveBaseOverride : float = 999;
@export var energyDrawPassiveBaseOverride : float = 999;
var energyDrawCurrent := 0.0; ##Recalculated and updated each frame.

var incomingPower := 0.0;
var hasIncomingPower := true;
var transmittingPower := true; ##While false, no power is transmitted from this piece.

##The amount of time needed between uses of this Piece's Passive Ability, after it successfully fires.
@export var passiveCooldownTimeMultiplier := 1.0;
##The amount of time needed between uses of this Piece's Active Abilities.
@export var activeCooldownTimeMultiplier := 1.0;

func set_cooldown_active(action:AbilityManager, immediate := false):
	if immediate:
		action.set_cooldown(statHolderID, get_cooldown_active(action));
	else:
		action.queue_cooldown(statHolderID, get_cooldown_active(action));

func on_cooldown_active(action : AbilityManager) -> bool:
	return action.on_cooldown(statHolderID);
func on_cooldown_active_any() -> bool:
	for ability in activeAbilitiesDistributed:
		if ability.on_cooldown(statHolderID):
			return true;
	return false;
func get_cooldown_active(action : AbilityManager) -> float:
	if is_instance_valid(action):
		return action.get_cooldown(statHolderID);
	return false;
func set_all_cooldowns():
	for action in get_all_abilities():
		set_cooldown_for_ability(action);
func set_cooldown_for_ability(action : AbilityManager):
	if is_instance_valid(action):
		if action.isPassive:
			action.queue_cooldown(statHolderID, get_stat("PassiveCooldown"));
		else:
			action.queue_cooldown(statHolderID, get_stat("ActiveCooldown"));

##Never called in base, but to be used for stuff like Bumpers needing a cooldown before they can Bump again.
func set_cooldown_passive(passiveAbility : AbilityManager, immediate := false):
	if is_instance_valid(passiveAbility):
		if immediate:
			passiveAbility.set_cooldown(statHolderID, get_cooldown_passive(passiveAbility));
		else:
			passiveAbility.queue_cooldown(statHolderID, get_cooldown_passive(passiveAbility));
func on_cooldown_passive(action : AbilityManager) -> bool:
	return get_cooldown_passive(action) > 0;
func on_cooldown_passive_any() -> bool:
	for ability in passiveAbilitiesDistributed:
		if ability.on_cooldown(statHolderID):
			return true;
	return false;
func get_cooldown_passive(passiveAbility : AbilityManager) -> float:
	if is_instance_valid(passiveAbility):
		return passiveAbility.get_cooldown(statHolderID);
	return false;
func on_cooldown_action(action : AbilityManager) -> bool:
	return action.on_cooldown(statHolderID);
func on_cooldown_named_action(actionName : String) -> bool:
	var action = get_named_action(actionName);
	if action != null:
		return on_cooldown_action(action);
	return true;

func on_cooldown():
	return on_cooldown_active_any() or on_cooldown_passive_any();

func on_contact_cooldown():
	for ability in get_all_abilities():
		if is_instance_valid(ability) and ability is AbilityManager:
			if ability.runType == AbilityManager.runTypes.OnContactDamage:
				if ability.on_cooldown(statHolderID):
					return true;
	return false;
func is_running_cooldowns():
	if is_equipped():
		var bot = get_host_robot();
		if is_instance_valid(bot):
			return bot.is_running_cooldowns();
	return false;
	
##Physics process step for abilities.
func phys_process_abilities(delta):
	##Un-disable hurtboxes.
	if hurtboxAlwaysEnabled:
		disable_hurtbox(false);
	##Run cooldown behaviors.
	cooldown_behavior();
	##Use the passive ability of this guy.
	use_looping_passives();

##Fires every physics frame when the Piece's passive or active abilities are on cooldown, via [method on_cooldown].
func cooldown_behavior(cooldown : bool = on_cooldown()):
	if on_contact_cooldown():
		if disableHitboxesWhileOnCooldown:
			hitboxCollisionHolder.scale = Vector3(0.00001,0.00001,0.00001);
	else:
		if disableHitboxesWhileOnCooldown:
			hitboxCollisionHolder.scale = Vector3.ONE;
	
	pass;

func try_sap_energy(amt:float):
	var bot = get_host_robot();
	var result = false;
	if bot != null:
		result = bot.try_sap_energy(amt);
		energyDrawCurrent += amt;
	queue_refresh_incoming_energy();
	#if result:
		##TextFunc.flyaway(true, global_position + Vector3(0,2,0), "lightgreen");
		##print_rich("[color=green]ABILITY RUN: ENERGY SAP WORKED")
	#else:
		##TextFunc.flyaway(false, global_position + Vector3(0,2,0), "lightred");
		##print("[color=red]ABILITY RUN: ENERGY SAP BORKED")
	return result;

func get_outgoing_energy():
	get_incoming_energy();
	if not is_transmitting(): return 0.0;
	return max(0.0, get_incoming_energy() - energyDrawCurrent);

func is_transmitting():
	return hasIncomingPower and transmittingPower;

## If this [Piece] is plugged into a [Socket], returns that [Socket]'s power.[br]
func get_incoming_energy():
	if refreshIncomingEnergy:
		return calc_incoming_energy();
	return incomingPower;

## If this [Piece] is plugged into a [Socket], returns that [Socket]'s power.[br]
var refreshIncomingEnergy := true;
func queue_refresh_incoming_energy():
	refreshIncomingEnergy = true;

func calc_incoming_energy():
	refreshIncomingEnergy = false;
	if get_host_socket() != null:
		#print(get_host_socket().get_energy_transmitted())
		var powerTransmitted = get_host_socket().get_energy_transmitted();
		#print_if_true(get_host_socket(), self is Piece_Sawblade)
		if powerTransmitted <= 0.0: 
			hasIncomingPower = false;
		else: 
			hasIncomingPower = true;
		incomingPower = powerTransmitted;
		return incomingPower;
	else:
		if is_instance_valid(hostRobot):
			#print("No host socket, yes power: ", hostRobot.get_available_energy())
			hasIncomingPower = true;
			incomingPower = hostRobot.get_available_energy();
			return incomingPower;
	incomingPower = 0.0;
	hasIncomingPower = false;
	return incomingPower;

func get_current_energy_draw():
	return energyDrawCurrent;

func get_active_energy_cost(ability : AbilityManager):
	##TODO: Bonuses
	var override = null;
	if energyDrawActiveBaseOverride != 999:
		override = energyDrawActiveBaseOverride;
	return ( ability.get_energy_cost_base(override) * get_stat("ActiveEnergyDraw") );

func get_passive_energy_cost(passiveAbility : AbilityManager):
	var stat = get_stat("PassiveEnergyDraw");
	if is_instance_valid(passiveAbility):
		var override = null;
		if energyDrawPassiveBaseOverride != 999:
			override = energyDrawPassiveBaseOverride;
		stat *= passiveAbility.get_energy_cost_base(override);
	##TODO: Bonuses
	return ( stat * get_physics_process_delta_time() );

func get_energy_cost(action):
	if action.isPassive:
		return get_passive_energy_cost(action);
	else:
		return get_active_energy_cost(action);

## Returns true if there would be enough energy in the system to support the input energy amount.
func test_energy_available(energyAmount) -> bool:
	return (get_current_energy_draw() + energyAmount) <= get_incoming_energy()

## Standard checks shared by [method can_use_active] and [method can_use_passive] that must be passed.
func standard_ability_checks(action : AbilityManager):
	## Check that the thing is the correct type.
	if not (action is AbilityManager):
		return false;
	## Check if the Piece is paused.
	if is_paused():
		return false;
	## Check that the ability is owned by this piece.
	if get_local_ability(action) == null:
		return false;
	## Check if it's disabled.
	if action.is_disabled(statHolderID):
		return false;
	## Check the bot, and also check aliveness.
	var bot = get_host_robot();
	if bot == null:
		return false;
	else:
		if !bot.is_conscious():
			return false;
	## Check that it's not on cooldown.
	if on_cooldown_action(action):
		return false;
	## Passed. Moving on...
	return true;

## Checks if you can use a given passive ability.
func can_use_active(action : AbilityManager): 
	## Check that the thing is valid. If not, get the first ability in the relevant list.
	if ! is_instance_valid(action):
		if activeAbilitiesDistributed.size() > 0:
			action = activeAbilitiesDistributed.front();
		else:
			return false
	## Check all the checks passives and actives share.
	if not standard_ability_checks(action):
		return false;
	## Check that there's enough energy to run this active.
	if not test_energy_available(get_active_energy_cost(action)):
		return false;
	## You passed!
	return true;

## Checks if you can use a given passive ability.
func can_use_passive(passiveAbility : AbilityManager):
	GameState.profiler_ping_create("Can Use Passive");
	## Check that the thing is valid. If not, get the first ability in the relevant list.
	if ! is_instance_valid(passiveAbility):
		if passiveAbilitiesDistributed.size() > 0:
			passiveAbility = passiveAbilitiesDistributed.front();
		else:
			return false
	## Check all the checks passives and actives share.
	if not standard_ability_checks(passiveAbility):
		return false;
	## Check that there's enough energy to run this passive.
	if (get_passive_energy_cost(passiveAbility) > 0.0):
		if ! test_energy_available(get_passive_energy_cost(passiveAbility)):
			return false;
	## You passed!
	return true;
func can_use_passive_any() -> bool:
	for passiveAbility in passiveAbilitiesDistributed:
		if can_use_passive(passiveAbility) : return true;
	return false;

var namedActions : Dictionary[String,AbilityManager] = {};
func regen_namedActions():
	namedActions.clear();
	for action in activeAbilitiesDistributed:
		if is_instance_valid(action) and action is AbilityManager:
			namedActions["A_"+action.abilityName] = action;
	for action in passiveAbilitiesDistributed:
		if is_instance_valid(action) and action is AbilityManager:
			namedActions["P_"+action.abilityName] = action;
func get_named_action(actionName : String) -> AbilityManager:
	if namedActions.is_empty(): regen_namedActions();
	var activeTest = "A_"+actionName;
	if namedActions.keys().has(activeTest): return namedActions[activeTest];
	var passiveTest = "P_"+actionName;
	if namedActions.keys().has(passiveTest): return namedActions[passiveTest];
	return null;
func get_named_passive(actionName : String) -> AbilityManager:
	if namedActions.is_empty(): regen_namedActions();
	var passiveTest = "P_"+actionName;
	if namedActions.keys().has(passiveTest): return namedActions[passiveTest];
	return null;
func get_named_active(actionName : String) -> AbilityManager:
	if namedActions.is_empty(): regen_namedActions();
	var activeTest = "A_"+actionName;
	if namedActions.keys().has(activeTest): return namedActions[activeTest];
	return null;
func can_use_named_ability(actionName : String) -> bool:
	var act = get_named_action(actionName);
	if act != null:
		return can_use_ability(act);
	return false;

func can_use_ability(action):
	if action.isPassive:
		return can_use_passive(action);
	else:
		return can_use_active(action);

func use_looping_passives():
	var passiveNamesUsed = [];
	for passiveAbility in passiveAbilitiesDistributed:
		if ! passiveNamesUsed.has(passiveAbility.abilityName):
			if passiveAbility.runType == AbilityManager.runTypes.Default or passiveAbility.runType == AbilityManager.runTypes.LoopingCooldown:
				passiveNamesUsed.append(passiveAbility.abilityName);
				use_passive(passiveAbility);
func use_contact_passives():
	var passiveNamesUsed = [];
	for passiveAbility in passiveAbilitiesDistributed:
		if ! passiveNamesUsed.has(passiveAbility.abilityName):
			if passiveAbility.runType == AbilityManager.runTypes.OnContactDamage:
				passiveNamesUsed.append(passiveAbility.abilityName);
				use_passive(passiveAbility);
func use_passive(passiveAbility:AbilityManager):
	if can_use_passive(passiveAbility):
		use_ability(passiveAbility);
		return true;
	return false;

## Where any and all [method register_active_ability()] or related calls should go. Runs at _ready().
## IDEALLY, this should be done thru the export instead of thru code, but it can be done here.
func ability_registry():
	pass;

## This runs directly before [method ability_registry] and cleans up all the abilities set up in the editor, as well as the passive ability.[br]
## Checks to see if they were initialized with [method register_active_ability]. If not, then it fills its references out, as it assumes it was made with the editor.
func ability_validation():
	## Duplicate the resources so the ability doesn't get joint custody with another piece of the same type.
	## Construct the description FIRST, because the constructor array is not going to get copied over.
	AbilityDistributor.distribute_all_abilities_to_piece(self);
	print_rich("[color=pink]INIT ACTIVES:", activeAbilitiesDistributed);
	pass;

func clear_abilities():
	pass;

## returns an array of all abilities, active and passive.
func get_all_abilities(passiveFirst := false) -> Array[AbilityManager]:
	var abilitiesToCheck : Array[AbilityManager] = [];
	if passiveFirst:
		Utils.append_array_unique(abilitiesToCheck, passiveAbilitiesDistributed);
		Utils.append_array_unique(abilitiesToCheck, activeAbilitiesDistributed);
	else:
		Utils.append_array_unique(abilitiesToCheck, activeAbilitiesDistributed);
		Utils.append_array_unique(abilitiesToCheck, passiveAbilitiesDistributed);
	return abilitiesToCheck;

## This should be run in ability_registry() only.
## abilityName = name of ability.
## abilityDescription = name of ability.
## functionWhenUsed = the function that gets called when this ability is called for.
## statsUsed = an Array of strings. This should hold any and all stats you want to have displayed on this ability's card.
## slotOverride is if you want to have this ability use a specific numbered slot.
func register_active_ability(abilityName : String = "Active Ability", abilityDescription : String = "No Description Found.", functionWhenUsed : Callable = func(): pass, statsUsed : Array[String] = []):
	var newAbility = AbilityManager.new();
	newAbility.register(self, abilityName, abilityDescription, functionWhenUsed, statsUsed);
	activeAbilitiesDistributed.append(newAbility);
	newAbility.initialized = true;
	pass;

func get_local_ability(action : AbilityManager) -> AbilityManager:
	if get_all_abilities().has(action):
		return action;
	return null;

##Calls the ability in the given slot if it's able to do so.
func use_ability(action : AbilityManager) -> bool:
	if can_use_ability(action):
		#print("ABILITY ",action.abilityName," CAN BE USED...");
		try_sap_energy(get_energy_cost(action));
		set_cooldown_for_ability(action);
		var activeAbility = get_local_ability(action);
		if activeAbility == null: 
			return false;
		var functionNameWhenUsed = activeAbility.functionNameWhenUsed;
		if functionNameWhenUsed != null and functionNameWhenUsed != "":
			if has_method(functionNameWhenUsed):
				#print("ABILITY ",activeAbility.abilityName," CALLED BY STRING NAME: ", get(functionNameWhenUsed))
				get(functionNameWhenUsed).call()
			else:
				#print_rich("[b][color=red]ABILITY REFERENCES INVALID FUNCTION NAME: ", functionNameWhenUsed)
				#TextFunc.flyaway(action.abilityName, global_position, "lightred");
				return false;
		else:
			#print("ABILITY ",activeAbility.abilityName," CALLED ITS FUNCTION.")
			var _call = activeAbility.functionWhenUsed;
			if _call != null and _call is Callable and is_instance_valid(_call):
				_call.call();
		pass;
		#TextFunc.flyaway(action.abilityName, global_position, "lightgreen");
		return true;
	#TextFunc.flyaway(action.abilityName, global_position, "lightblue");
	return false;

#################### VISUALS AND TRANSFORM


var placingAnimationTimer = -1;
var placingAnimationStart = 15;
var buyingAnimationTimer = -1;
var buyingAnimationStart = 15;

func start_placing_animation():
	placingAnimationTimer = placingAnimationStart;
	pass;
func start_buying_animation():
	buyingAnimationTimer = buyingAnimationStart;
	pass;

func process_draw(delta):
	#return;
	#print(hurtboxCollisionHolder.get_collision_layer())
	if inShop:
		for mesh in get_all_meshes():
			mesh.set_layer_mask_value(1, false)
			mesh.set_layer_mask_value(2, true)
	else:
		for mesh in get_all_meshes():
			mesh.set_layer_mask_value(1, true)
			mesh.set_layer_mask_value(2, false)
	
	if not has_host(true, false, false) and not force_visibility:
		placingAnimationTimer = -1;
		buyingAnimationTimer = -1;
		if visible: hide()
	else:
		if not visible: show()
		
		
		##Hide/show the male socket based on plugged-in status.
		if is_instance_valid(maleSocketMesh):
			if has_host(true, false, false): ##If you're on a socket:
				if not selected: set_selection_mode(selectionModes.NOT_SELECTED);
				if maleSocketMesh.visible:
					maleSocketMesh.hide();
			else:
				if !maleSocketMesh.visible:
					maleSocketMesh.show();
		
		var socket = get_host_socket();
		if socket != null:
			if placingAnimationTimer >= 0:
				placingAnimationTimer -= 1;
				position.y = 0.015 * placingAnimationTimer;
				pass;
			if placingAnimationTimer == 0:
				ParticleFX.play("Sparks", socket, socket.global_position);
				var randomSpeed_1 = randf_range(0.85, 1.1);
				SND.play_sound_at("Part.Place", socket.global_position, socket, 0.7, randomSpeed_1);
				var randomSpeed_2 = randf_range(0.85, 1.1);
				SND.play_sound_at("Zap.Short", socket.global_position, socket, 0.7, randomSpeed_2);
				position.y = 0;
				pass;
			
			if buyingAnimationTimer >= 0:
				buyingAnimationTimer -= 1;
				position.y = (buyingAnimationStart - buyingAnimationTimer) * 0.03 * (buyingAnimationStart - buyingAnimationTimer);
				pass;
			if buyingAnimationTimer == buyingAnimationStart:
				var sparks = ParticleFX.play("Sparks", socket, socket.global_position);
				sparks.set_visibility_layer(2);
				SND.play_purchase_sound();
				var randomSpeed_2 = randf_range(0.85, 1.1);
				SND.play_sound_nondirectional("Zap.Short", 0.7, randomSpeed_2);
				position.y = 0;
				pass;
			elif buyingAnimationTimer == 0:
				submit_queued_buy();
				SND.play_purchase_sound();
				var randomSpeed_2 = randf_range(0.85, 1.1);
				SND.play_sound_at("Zap.Short", socket.global_position, socket, 0.7, randomSpeed_2);
				position.y = 0;
				pass;
		else:
			placingAnimationTimer = -1;
			buyingAnimationTimer = -1;

enum selectionModes {
	NOT_SELECTED,
	SELECTED,
	PLACEABLE,
	NOT_PLACEABLE,
}
var selectionModeMaterials = {
	selectionModes.NOT_SELECTED : null,
	selectionModes.SELECTED : preload("res://graphics/materials/glow_selected_fx.tres"),
	selectionModes.PLACEABLE : preload("res://graphics/materials/CanPlace.tres"),
	selectionModes.NOT_PLACEABLE : preload("res://graphics/materials/cannot_be_placed.tres"),
}
var selectionMode := selectionModes.NOT_SELECTED;
func set_selection_mode(newMode : selectionModes = selectionModes.NOT_SELECTED):
	if selectionMode == newMode: return;
	if !assignedToSocket and newMode == selectionModes.SELECTED: return;
	selectionMode = newMode;
	if newMode == selectionModes.NOT_SELECTED:
		for mesh in get_all_meshes():
			mesh.set_surface_override_material(0, meshMaterials[mesh]);
	else:
		for mesh in get_all_meshes():
			mesh.set_surface_override_material(0, selectionModeMaterials[newMode]);
	pass;
var meshMaterials = {};
#var meshMaterials = Dictionary[MeshInstance3D, StandardMaterial3D] = {};
func get_all_mesh_init_materials():
	for mesh in get_all_meshes():
		meshMaterials[mesh] = mesh.get_active_material(0);
func get_all_meshes() -> Array:
	var meshes = Utils.get_all_children_of_type(self, MeshInstance3D, self);
	return meshes;



########################## MELEE & DAMAGE

@export_subgroup("Attack Stuff")
@export var damageBase := 0.0;
@export var knockbackBase := 0.0; ## For context on how big this should be, the Bumper Piece has a value of 70 here.
@export var kickbackBase := 0.0;
@export var damageTypes : Array[DamageData.damageTypes] = [];
@export var disableHitboxesWhileOnCooldown := true;
@export var contactCooldown := 0.0;
## When true, damage run through [method contact_damage] will be averaged with a compared-velocity multiplier provided by the [PieceCollisionBox]es.[br]
## In practice, this makes contact damage deal more damage depending on how fast this piece is going compared to the target.[br][br]For example, a charging [Robot_Pokey] will be dealing much less damage with its Horn pieces when you're both goig the same speed, but will absolutely skewer you if you're running towards it.
@export var contactDamageBasedOnComparedVelocities := true; 
## A [float] scale from 1 to 0. When 1, velocity will have bias. When 0, base damage will have bias. Does nothing if [member contactDamageBasedOnComparedVelocities] is true.
@export_range(0.0, 1.0, 0.05) var contactDamageComparedVelocitiesBias := 1.0; 
var damageModifier := 1.0; ##This variable can be used to modify damage on the fly without needing to go thru set/get stat.

func get_damage() -> float:
	return get_stat("Damage") * damageModifier;

func get_contact_damage(colliderThis : PieceCollisionBox, colliderThat : PieceCollisionBox) -> float:
	var damageBase = get_damage();
	if ! contactDamageBasedOnComparedVelocities:
		return damageBase;
	var velocityMult = contactDamageComparedVelocitiesBias * colliderThis.compared_projected_position(colliderThat);
	var baseMult = 1.0 - contactDamageComparedVelocitiesBias;
	var comparedMultiplier = velocityMult + baseMult;
	
	return comparedMultiplier * damageBase;

func get_knockback_force() -> float:
	return get_stat("Knockback");

func get_impact_direction(positionOfTarget : Vector3, factorBodyVelocity := true) -> Vector3:
	var factor = (positionOfTarget - global_position).normalized();
	if factorBodyVelocity:
		var bodVel = get_host_robot().body.linear_velocity;
		factor += bodVel;
	return factor;

## Returns a Vector3 taking into account this Piece's Knockback force stat, as well as this bot's velocity.
func get_knockback(positionOfTarget : Vector3, factorBodyVelocity := true) -> Vector3:
	var knockbackVal = get_knockback_force();
	var knockbackFactor = get_impact_direction(positionOfTarget, factorBodyVelocity);
	var knockbackVector = knockbackVal * knockbackFactor;
	return knockbackVector;

func get_kickback_force() -> float:
	return get_stat("Kickback");

func get_kickback_direction(positionOfTarget : Vector3, factorBodyVelocity := true) -> Vector3:
	var factor = global_position - positionOfTarget;
	print("FACTOR", factor)
	factor = factor.normalized();
	if factorBodyVelocity:
		var bodVel = get_host_robot().body.linear_velocity;
		factor += bodVel;
	
	#factor = factor.rotated(Vector3(0,1,0), deg_to_rad(180));
	factor -= global_position;
	return factor;

func get_damage_types() -> Array[DamageData.damageTypes]:
	##TODO: Part stuff that adds damage types.
	return damageTypes;

## Creates a brand new [DamageData] based on your current stats.
func get_damage_data(targetPosition := global_position, _damageAmount := get_damage(), _knockbackForce := get_knockback_force(), _direction := Vector3(0,0,0), _damageTypes := get_damage_types()) -> DamageData:
	var DD = DamageData.new();
	DD.attackerRobot = get_host_robot();
	DD.create(_damageAmount, _knockbackForce, _direction, _damageTypes);
	DD.calc_damage_direction_based_on_targets(global_position, targetPosition, false);
	return DD;

## Creates a brand new [DamageData] based on your current stats.
func get_kickback_damage_data(targetPosition := global_position, _damageAmount := 0.0, _knockbackForce := get_kickback_force(), _direction := Vector3(0,0,0), _damageTypes :Array[DamageData.damageTypes]= []):
	var DD = DamageData.new();
	DD.create(_damageAmount, _knockbackForce, _direction, _damageTypes);
	DD.attackerRobot = get_host_robot();
	prints(targetPosition, global_position)
	print(DD.calc_damage_direction_based_on_targets(global_position, targetPosition, true));
	DD.calc_damage_direction_based_on_targets(global_position, targetPosition, true);
	print(DD.damageDirection)
	return DD;


##Fired AFTER a hitbox hits an enemy's hurtbox, via [method _on_hitbox_shape_entered]. Calculates the damage and knockback.
func contact_damage(otherPiece : Piece, otherPieceCollider : PieceCollisionBox, thisPieceCollider : PieceCollisionBox):
	#print (self, otherPiece)
	#print("COntactdamage function.")
	if otherPiece != self and otherPiece.is_inside_tree() and is_inside_tree():
		#print("Target was not self.")
		##Handle damaging the opposition.
		var DD = get_damage_data();
		var contactDamage = get_contact_damage(thisPieceCollider, otherPieceCollider);
		DD.damageAmount = contactDamage;
		var otherPieceGlobalPos = otherPiece.global_position
		#DD.damageDirection = KB;
		otherPiece.hurtbox_collision_from_piece(self, DD);
		
		##Handle kickback.
		initiate_kickback(otherPieceGlobalPos);
		
		use_contact_passives();
		return true;
	#print_rich("[color=orange]Target was self.")
	return false;

func initiate_kickback(awayPos : Vector3):
	var kb = get_kickback_damage_data(awayPos);
	prints(awayPos, global_position)
	hurtbox_collision_from_piece(self, kb);

func move_robot_with_force(direction):
	var bot = get_host_robot();
	if is_instance_valid(bot):
		bot.apply_force(direction);

## Fired when an enemy Piece hitbox hurts this.
func hurtbox_collision_from_piece(otherPiece : Piece, damageData : DamageData):
	take_damage_from_damageData(damageData);
	pass;

## Fired when an enemy Projectile hitbox hurts this.
func hurtbox_collision_from_projectile(projectile : Bullet, damageData : DamageData):
	take_damage_from_damageData(damageData);
	pass;

## Gives DamageData to the player to chew through. Runs [method modify_incoming_damage_data] before actually sending it through.
func take_damage_from_damageData(damageData : DamageData):
	if get_host_robot() != null and is_instance_valid(damageData):
		var resultingDamage = modify_incoming_damage_data(damageData);
		get_host_robot().take_damage_from_damageData(resultingDamage);

## Extend this function with any modifications you want to do to the incoming DamageData when this Piece gets hit.[br]
## This is potentially useful for things like a Shield, for example, which might nullify most of the damage from incoming Piercing-tagged attacks.
func modify_incoming_damage_data(damageData : DamageData) -> DamageData:
	return damageData;

## Fires when a Hitbox hits another robot. The prelude to [method contact_damage].
func _on_hitbox_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	#print("please.")
	if not on_contact_cooldown():
		if body is RobotBody and body.get_parent() != get_host_robot():
			#print("tis a robot. from ", pieceName)
			var other_shape_owner = body.shape_find_owner(body_shape_index)
			var other_shape_node = body.shape_owner_get_owner(other_shape_owner)
			if other_shape_node is not PieceCollisionBox: return;
			
			var local_shape_owner = hitboxCollisionHolder.shape_find_owner(local_shape_index)
			var local_shape_node =  hitboxCollisionHolder.shape_owner_get_owner(local_shape_owner)
			if local_shape_node is not PieceCollisionBox: return;
			
			var otherPiece : Piece = other_shape_node.get_piece();
			#print("Other Piece in hitbox collision: ", otherPiece)
			if ! is_instance_valid(otherPiece): return;
			if is_instance_valid(otherPiece) and is_instance_valid(other_shape_node) and is_instance_valid(local_shape_node):
				#print("Contact damage commencing:")
				contact_damage(otherPiece, other_shape_node, local_shape_node)
	pass # Replace with function body.

## Fires when an area hits this Piece's Hitboxes. Mostly used for reflecting Bullets.
func _on_hitbox_shapes_area_entered(area_rid, area, area_shape_index, local_shape_index):
	var parent = area.get_parent();
	if parent is Bullet:
		bullet_hit_hitbox(parent);
	pass # Replace with function body.

## Fires when a bulelt hits this robot's HITBOX.
func bullet_hit_hitbox(bullet : Bullet):
	pass;


################### COLLISION
@export_category("Node refs")
@export_subgroup("Meshes")
@export var meshesHolder : Node3D;
@export var maleSocketMesh : Node3D;
@export_subgroup("Collision")
@export var hitboxCollisionHolder : HitboxHolder;
@export var hurtboxCollisionHolder : HurtboxHolder;
@export var placementCollisionHolder : PlacementShapecastHolder;
#var bodyMeshes : Dictionary[StringName, MeshInstance3D] = {};

##Frame timer that updates scale of hitboxes every 3 frames.
var hitboxRescaleTimer := 1;
func phys_process_collision(delta):
	if hitboxRescaleTimer <= 0:
		if has_host(true, true, true):
			hitboxRescaleTimer = 3;
			hurtboxCollisionHolder.collision_layer = 8 + 64; #Hurtbox layer and placed layer.
		else:
			hurtboxCollisionHolder.collision_layer = 8; #Hurtbox layer and hover layer.

##Assign all sockets with this as their host piece.
func autoassign_child_sockets_to_self():
	for child in get_all_female_sockets():
		child.hostRobot = get_host_robot();
		child.hostPiece = self;

func fix_sockets(delta):
	if is_inside_tree():
		#autoassign_child_sockets_to_self();
		if get_selected():
			#print(assignedToSocket, hostSocket, StatHolderManager.get_stat_holder_by_id(statHolderID).assignedToSocket)
			#print(activeAbilitiesDistributed.front().get_ability_data(statHolderID) if ! activeAbilitiesDistributed.is_empty() else "ActiveAbilities is empty")
		#if ! assignedToSocket:
			#var parent =  get_parent();
			#if parent is Socket:
				#if ! parent.preview == self:
					#parent.add_occupant(self, true);
			pass;
		pass;

##This function assigns socket data and generates all hitboxes. Should only ever be run once at [method _ready()].
func gather_colliders_and_meshes():
	get_all_female_sockets();
	get_all_mesh_init_materials();
	autoassign_child_sockets_to_self();
	refresh_and_gather_collision_helpers();
	print_rich("[color=orange]GATHERING COLLIDERS AND MESHES ON PIECE ", self);

##This function regenerates all collision boxes. Should in theory only ever be run at [method _ready()], but the Piece Helper tool scene uses it also.
func refresh_and_gather_collision_helpers():
	#Clear out all copies.
	reset_collision_helpers();
	if ! is_inside_tree(): return;
	
	#Clear all colliders from their respective areas, given that the resets didn't work.
	for child in placementCollisionHolder.get_children():
		child.queue_free();
	for child in hurtboxCollisionHolder.get_children():
		child.queue_free();
	for child in hitboxCollisionHolder.get_children():
		child.queue_free();
	
	#hurtboxCollisionHolder.scale = Vector3.ONE * 0.95;
	#placementCollisionHolder.scale = Vector3.ONE * 0.95;
	
	var identifyingNum = 0;
	for child in get_children():
		if child is PieceCollisionBox:
			child.originalHost = self;
			if child.isOriginal and not child.copied:
				child.reset();
				child.originalOffset = child.global_position - global_position;
				child.originalRotation = child.global_rotation - global_rotation;
				if child.identifier == null:
					child.identifier = str(identifyingNum)
					identifyingNum += 1;
				if is_instance_valid(child.shape):
					##if the PieceCollisionBox is of type PlACEMENT then it should spawn a shapecast proxy with an identical shape.
					if child.isPlacementBox:
						var shapeCastNew = child.make_shapecast();
						shapeCastNew.reparent(placementCollisionHolder, true);
						shapeCastNew.add_exception(hitboxCollisionHolder);
						shapeCastNew.add_exception(hurtboxCollisionHolder);
						
						#shapeCastNew.rotation = child.originalRotation;
					##if the PieceCollisionBox is of type HITBOX or HURTBOX then it should copy itself into those.
					if child.isHurtbox:
						var dupe = child.make_copy();
						dupe.disabled = false;
						hurtboxCollisionHolder.add_child(dupe);
						dupe.debug_color = Color("0099b36b");
						
						##Disable the other types the copy box isn't.
						dupe.isPlacementBox = false;
						dupe.isHurtbox = true;
						dupe.isHitbox = false;
						
					if child.isHitbox:
						var dupe = child.make_copy();
						dupe.disabled = false;
						hitboxCollisionHolder.add_child(dupe);
						dupe.debug_color = Color("f6007f6b");
						
						##Disable the other types the copy box isn't.
						dupe.isPlacementBox = false;
						dupe.isHurtbox = false;
						dupe.isHitbox = true;
						
	#print(placementCollisionHolder)
	pass;

##Runs the Reset function on all collision helpers.
func reset_collision_helpers():
	for child in get_children():
		if child is PieceCollisionBox and child.isOriginal:
			child.reset();
	allSockets.clear();

##Should ping all of the placement hitboxes and return TRUE if it collides with a Piece, of FALSE if it doesn't.
func ping_placement_validation():
	var exceptionsToAddThenRemove = [];
	if is_node_ready() and is_visible_in_tree() and is_instance_valid(get_parent()):
		var collided := false;
		#print(get_children())
		var shapecasts = []
		for child in placementCollisionHolder.get_children():
			#print("Hi 1")
			#print(placementCollisionHolder.get_children())
			if not collided:
				#print("Hi 2")
				if child is ShapeCast3D:
					#print("Hi 3")
					#child.reparent(self, true);
					#shapecasts.append(child);
					child.force_shapecast_update();
					if child.is_colliding(): 
						for colliderIDX in child.get_collision_count():
							var collider = child.get_collider(colliderIDX);
							#var colShape = child.get_collider_shape(colliderIDX);
							if collider is HurtboxHolder:
								if self != collider.get_piece():
									collided = true;
									print("collided with another HURTbox... ", collider.get_piece())
							#if collider is RobotBody:
								#if colShape is PieceCollisionBox:
									#if self != collider.get_piece():
										#collided = true;
										#print("collided with another box... ", collider.get_piece())
							elif collider is StaticBody3D:
								collided = true;
							else:
								#print("what")
								#print(collider)
								pass;
	
	##Put all the shapecasts back.
	#for cast in shapecasts:
		#cast.reparent(placementCollisionHolder, true);
	
		#print(collided)
		if collided: set_selection_mode(selectionModes.NOT_PLACEABLE);
		else: set_selection_mode(selectionModes.PLACEABLE);
		return collided;
	return true;

func get_all_hitboxes():
	var ret = [];
	for child in hitboxCollisionHolder.get_children():
		child.originalHost = self;
		ret.append(child);
	return ret;

func get_all_hurtboxes():
	var ret = [];
	for child in hurtboxCollisionHolder.get_children():
		child.originalHost = self;
		ret.append(child);
	return ret;

var hitboxEnabled = null;
func disable_hurtbox(foo:bool):
	if hitboxEnabled != foo:
		hitboxEnabled = foo;
		for child in hurtboxCollisionHolder.get_children():
			if child is PieceCollisionBox:
				child.disabled = foo;

func get_facing_direction(front := Vector3(0,0,1), addPosition := false):
	front = front.rotated(Vector3(1,0,0), global_rotation.x);
	front = front.rotated(Vector3(0,1,0), global_rotation.y);
	front = front.rotated(Vector3(0,0,1), global_rotation.z);
	
	if addPosition:
		front += global_position;
	
	return front;

##Fired whent he camera finds this piece.
##TODO: Fancy stuff. 
var selected := false;
func get_selected() -> bool:
	if selected: set_selection_mode(selectionModes.SELECTED);
	else:
		if is_assigned():
			set_selection_mode(selectionModes.NOT_SELECTED);
	return selected;

var isPreview := false;
func is_preview():
	if get_parent() == null: return false;
	if assignedToSocket: return false;
	return isPreview;
func select(foo : bool = not get_selected()):
	if foo == selected: return foo;
	if foo: deselect_other_pieces(self);
	else: 
		if selected:
			deselect_other_pieces(); ##This hopefully prevents recursion.
		else:
			deselect_other_pieces(self);
	if is_preview() and ! assignedToSocket:
		return false;
	selected = foo;
	var bot = get_host_robot()
	if selected: 
		if bot: bot.selectedPiece = self;
		if selectionMode == selectionModes.NOT_SELECTED:
			set_selection_mode(selectionModes.SELECTED);
	else: 
		set_selection_mode(selectionModes.NOT_SELECTED);
	print(pieceName)
	return selected;
	pass;

func select_via_robot(robotOverride := get_host_robot(), forcedValue = null):
	var bot = null;
	if is_instance_valid(robotOverride):
		bot = robotOverride;
		bot.select_piece(self, forcedValue);

func deselect():
	if selected:
		deselect_all_sockets();
	select(false);

func deselect_other_pieces(filterPiece := self):
	if has_host(false, true, false):
		var bot = get_host_robot();
		bot.deselect_all_pieces(filterPiece);

##Need to have support for a main 3D model. Sub-models will need to come later.
##Position should NEVER be changed from 0,0,0. 0,0,0 Origin is where this thing plugs in.

####################### CHAIN MANAGEMENT
##Needs ways of pinging 3D space when trying to place it with its collision to check where it can be placed.
##

##TODO: Functions for assigning the host robot and host piece.
##When the piece is assigned to a socket or robot, it should reparent itself to it.
@export_category("Chain Management")
@export var hostPiece : Piece;
@export var hostRobot : Robot;

@export var femaleSocketHolder : Node3D;
@export var hostSocket : Socket;
@export var assignedToSocket := false;
var allSockets : Array[Socket] = []

func get_index_of_socket(inSocket : Socket) -> int:
	return get_all_female_sockets().find(inSocket);
func get_socket_at_index(socketIndex : int) -> Socket:
	var all = get_all_female_sockets();
	if socketIndex >= 0 and socketIndex < all.size():
		return all[socketIndex];
	return null;

func autograb_sockets():
	var sockets = Utils.get_all_children_of_type(self, Socket, self);
	#print(sockets);
	allSockets = [];
	for socket : Socket in sockets:
		Utils.append_unique(allSockets, socket);
		socket.set_host_piece(self);
		socket.set_host_robot(get_host_robot());
	return allSockets;

##Returns a list of all sockets on this part.
func get_all_female_sockets() -> Array[Socket]:
	if allSockets.is_empty():
		allSockets = autograb_sockets();
	return allSockets;

func register_socket(socket : Socket):
	Utils.append_unique(allSockets, socket);

##Assigns this [Piece] to a given [Socket]. This essentially places the thing onto the [Robot] the [Socket] has as its host.
func assign_socket(socket:Socket):
	print("ASSIGNING TO SOCKET")
	#print("Children", get_children())
	socket.add_occupant(self);
	assign_socket_post(socket);
	start_placing_animation();
	pass;

##Assigns this [Piece] to a given [Socket]. This portion is separated so it can act as an entry point for manual assignment.
func assign_socket_post(socket:Socket):
	isPreview = false;
	assignedToSocket = true;
	if has_robot_host():
		hostRobot.on_add_piece(self);
	hurtboxCollisionHolder.set_collision_mask_value(8, false);
	hostSocket = socket;
	set_selection_mode(selectionModes.NOT_SELECTED);
	print("ASSIGNED TO SOCKET? ")

func is_assigned() -> bool:
	return assignedToSocket;

##Removes this piece from its assigned Socket. Essentially removes it from the [Robot], too.
func remove_from_socket():
	print("REMOVING FROM SOCKET.")
	if assignedToSocket and is_instance_valid(hostRobot):
		hostRobot.on_remove_piece(self);
	disconnect_from_host_socket();
	hostSocket = null;
	hostRobot = null;
	assignedToSocket = false;
	if is_instance_valid(get_parent()):
		get_parent().remove_child(self);
	#ping the
	pass;

func get_specific_female_socket(index):
	return femaleSocketHolder.get_child(index);

##Calls [method Socket.remove_occupant()] on this Piece's host [Socket], if it has one.
func disconnect_from_host_socket():
	if is_instance_valid(hostSocket):
		hostSocket.remove_occupant();
	hostSocket = null;

func get_host_socket() -> Socket: 
	if is_instance_valid(hostSocket):
		return hostSocket;
	else:
		return null;

func get_host_piece() -> Piece:
	if get_host_socket() == null:
		return null;
	else:
		return get_host_socket().get_host_piece();

func get_host_robot(forceReturnRobot := false) -> Robot:
	if forceReturnRobot: return hostRobot;
	
	if get_host_socket() == null:
		return null;
	else:
		return hostRobot;


func has_socket_host():
	return is_instance_valid(get_host_socket());
func is_assigned_to_socket():
	return has_socket_host() and assignedToSocket;
func has_robot_host():
	return is_instance_valid(get_host_robot());
func host_is_player() -> bool:
	return has_robot_host() and (get_host_robot() is Robot_Player);
func host_is_enemy() -> bool:
	return has_robot_host() and (get_host_robot() is Robot_Enemy);
func is_equipped():
	return is_assigned_to_socket() and has_robot_host();
func is_equipped_by_player():
	return is_assigned_to_socket() and host_is_player();

##Returns true if the part has both a host socket and a host robot.
func has_host(getSocket := true, getRobot := true, getSocketAssigned := true):
	if getSocketAssigned and (not is_assigned_to_socket()):
		return false;
	if getSocket and (not has_socket_host()):
		return false;
	if getRobot and (not has_robot_host()):
		return false;
	return true;

var selectedSocket : Socket;
func assign_selected_socket(socket):
	deselect_all_sockets();
	socket.select();
	selectedSocket = socket;
	##TODO: Hook this into giving that socket a new Piece.

func deselect_all_sockets():
	for socket in get_all_female_sockets():
		socket.select(false);

var allPieces : Array[Piece] = [];
func get_all_pieces() -> Array[Piece]:
	if allPieces.is_empty():
		return get_all_pieces_regenerate();
	return allPieces;

var allPiecesLoops := 0;
func get_all_pieces_regenerate() -> Array[Piece]:
	var ret : Array[Piece] = []
	prints("ALL FEMALE SOCKETS ON ",pieceName,": ", get_all_female_sockets())
	for socket : Socket in get_all_female_sockets():
		allPiecesLoops += 1;
		#print("ALL PIECES LOOOPS: ", allPiecesLoops);
		var occupant = socket.get_occupant();
		if occupant != null:
			#print("ALL PIECES OCCUPANT :", occupant, " SELF : ", self)
			if occupant != self:
				ret.append(occupant);
	#print("ALL PIECES REGENRATED: ", ret)
	return ret;

func get_all_pieces_recursive() -> Array[Piece]:
	var ret : Array[Piece] = [self];
	if is_ready:
		for socket in get_all_female_sockets():
			if is_instance_valid(socket):
				var occupant = socket.get_occupant();
				if is_instance_valid(occupant):
					Utils.append_array_unique(ret, occupant.get_all_pieces_recursive())
	
	return ret;

####################### INVENTORY STUFF
@export_category("Stash and Ability Slots")

## Calls [method remove_and_add_to_robot_stash] after a short removal animation plays.
func fancy_remove(botOverride : Robot = get_host_robot(true)):
	remove_and_add_to_robot_stash(botOverride);

## Removes this Piece and any Pieces below it, then adds them to the stash of the robot they're on, if there is one. Calls [method remove_from_socket], then [method Robot.add_something_to_stash], then [method Robot_Player.queue_close_engine].
func remove_and_add_to_robot_stash(botOverride : Robot = get_host_robot(true), fancy := false, silentFancy := false):
	if fancy:
		var socket = get_host_socket();
		if socket != null:
			var sparks = ParticleFX.play("Sparks", socket, socket.global_position);
			if !silentFancy:
				var randomSpeed_2 = randf_range(0.85, 1.1);
				SND.play_sound_nondirectional("Zap.Short", 0.7, randomSpeed_2);
	
	deselect();
	##Stash everything below this.
	for subPiece in get_all_pieces_regenerate():
		subPiece.remove_and_add_to_robot_stash(botOverride, fancy, true);
	
	remove_from_socket();
	var bot = botOverride;
	if is_instance_valid(bot):
		bot.add_something_to_stash(self);
		if bot is Robot_Player:
			bot.queue_update_engine_with_selected_or_pipette();

func get_stash_button_name(showTree := false, prelude := "") -> String:
	var ret = prelude + pieceName;
	if showTree:
		for piece in get_all_pieces():
			ret += "\n" + prelude + "-" + piece.get_stash_button_name(true, prelude + "-");
	return ret;

func get_ability_slot_data(action : AbilityManager):
	return {
		"incomingPower" : get_incoming_energy(),
		"usable" : can_use_ability(action),
	};
	pass;

@export_category("Engine")
#var pieceBonusOut : Array[PartModifier] = [] ##TODO: MAKE A PIECE BONUS THING

##TODO:
##Copy from the original 2D inventories. 
##Needs ways of transmitting bonus data to the main body.
##Needs ways of storing bonus data in a concise way.

@export var engineSlots := {
	## Row 0
	Vector2i(0,0) : null,
	Vector2i(1,0) : null,
	Vector2i(2,0) : null,
	Vector2i(3,0) : null,
	Vector2i(4,0) : null,
	## Row 1
	Vector2i(0,1) : null,
	Vector2i(1,1) : null,
	Vector2i(2,1) : null,
	Vector2i(3,1) : null,
	Vector2i(4,1) : null,
	## Row 2
	Vector2i(0,2) : null,
	Vector2i(1,2) : null,
	Vector2i(2,2) : null, 
	Vector2i(3,2) : null,
	Vector2i(4,2) : null,
	## Row 3
	Vector2i(0,3) : null,
	Vector2i(1,3) : null,
	Vector2i(2,3) : null,
	Vector2i(3,3) : null,
	Vector2i(4,3) : null,
	## Row 4
	Vector2i(0,4) : null,
	Vector2i(1,4) : null,
	Vector2i(2,4) : null,
	Vector2i(3,4) : null,
	Vector2i(4,4) : null,
}
## Set to [code]true[/code] to regenerate [member listOfParts] using [method get_all_parts] the next time it is gotten.
var regeneratePartList := true; 
## The total list of all [Part]s within [member engineSlots].
var listOfParts : Array[Part] = []:
	get:
		if regeneratePartList:
			regeneratePartList = false;
			listOfParts = engine_get_all_parts();
		return listOfParts;
var selectedPart : Part;

## Returns a list of all the [Part]s inside the [member engineSlots]. Utilizes [method Utils.append_unique] so each [Part] is only added once to the resulting [Array].
func engine_get_all_parts() -> Array[Part]:
	var gatheredParts : Array[Part] = [];
	for slot in engineSlots.keys():
		var slotContents = engineSlots[slot];
		if slotContents != null:
			if slotContents is Part:
				if slotContents.get_engine() == self:
					Utils.append_unique(gatheredParts, slotContents);
	listOfParts = gatheredParts;
	return gatheredParts;

## Erases a single slot at the given index in [member engineSlots].
func engine_clear_slot_at(x: int, y: int):
	var index = Vector2i(x, y);
	if index in engineSlots.keys():
		engineSlots[index] = null;
	regeneratePartList = true; 

## Gets the [Part] or [code]null[/code] at the given index in [member engineSlots].
func engine_get_slot_at(x: int, y: int):
	var index = Vector2i(x, y);
	var pointer = null;
	
	if index in engineSlots.keys():
		pointer = engineSlots[index];
	
	return pointer

## Returns true if the slot at the given index in [member engineSlots] is free ([code]null[/code] or holds [param filterPart].
func engine_is_slot_free(x: int, y: int, filterPart:Part) -> bool:
	var index = Vector2i(x, y);
	
	if index in engineSlots.keys():
		var slotAt = engine_get_slot_at(x, y)
		if slotAt == null:
			return true;
		else:
			if is_instance_valid(filterPart):
				if slotAt == filterPart:
					return true;
	return false;

## Returns true if [member engineSlots] has a slot at the given index.
func engine_is_slot_in_bounds(x: int, y: int):
	var index = Vector2i(x, y);
	if index in engineSlots.keys():
		return true;
	return false;

## Returns the combined results of [method is_slot_free] and [method is_slot_in_bounds], then optionally returns it as a [Dictionary] if [param separateIntoDict] is [code]true[/code]. EX. below:[br][br]
## [codeblock]
## ## Assuming the slot at 1,1 exists and is in bounds...
## is_slot_free_and_in_bounds(1, 1, null, false); ## Returns true
## is_slot_free_and_in_bounds(1, 1, null, false); ## Returns {"free" : true, "inBounds" : true}
## [/codeblock]
func engine_is_slot_free_and_in_bounds(x: int, y: int, filterPart:Part, separateIntoDict := false):
	var free = engine_is_slot_free(x, y, filterPart);
	var inBounds = engine_is_slot_in_bounds(x, y);
	if separateIntoDict:
		return {"free" : free, "inBounds" : inBounds}
	else:
		return (free and inBounds);

func engine_get_modified_part_dimensions(part: Part, modifier: Vector2i):
	var dimensions = part.dimensions;
	var coords = [];
	for index in dimensions:
		var newCoord = index + modifier;
		coords.append(newCoord);
	
	return coords

func engine_check_coordinate_table_is_free(coords:Array, filterPart:Part):
	for index in coords:
		if engine_is_slot_free(index.x, index.y,filterPart):
			pass
		else:
			return false
	return true

func is_there_space_for_part(part:Part, invPosition : Vector2i) -> bool:
	if is_instance_valid(part):
		var partCoords = engine_get_modified_part_dimensions(part, invPosition)
		if engine_check_coordinate_table_is_free(partCoords, part):
			return true;
	return false;

func add_part(part: Part, invPosition : Vector2i, noisy := false):
	var coordsToCheck = engine_get_modified_part_dimensions(part, invPosition);
	
	if engine_check_coordinate_table_is_free(coordsToCheck, part):
		#print("Coord table is free... somehow ", coordsToCheck)
		for index in coordsToCheck:
			engine_set_slot_at(index.x, index.y, part);
		listOfParts.append(part);
		part.invPosition = invPosition;
		part.hostPiece = self;
		##TODO: Decide whether PartActive is gonna persist.
		#if part is PartActive:
			#part.positionNode = battleBotBody;
			#part.meshNode.reparent(battleBotBody); 
		engine_add_part_post(part, noisy);
	else:
		pass 
	pass

func engine_add_part_post(part:Part, noisy:=false):
	regeneratePartList = true; 
	partMods_deploy();
	pass;

func remove_part(part: Part, destroy:=false, beingSold := false, beingBought := false, stash := false):
	var coordsToRemove = engine_get_modified_part_dimensions(part, part.invPosition);
	part.invPosition = Vector2i(0,0);
	if part is PartActive:
		part.positionNode = null;
		part.meshNode.reparent(part);
	
	if is_equipped_by_player():
		part.inPlayerInventory = false;
	
	for coord : Vector2i in coordsToRemove:
		engine_clear_slot_at(coord.x, coord.y);
	
	while listOfParts.find(part) != -1:
		listOfParts.remove_at(listOfParts.find(part));
	
	part.invHolderNode = null;
	part.hostPiece = null;
	
	if destroy:
		part.destroy();
	elif has_robot_host():
		if stash:
			hostRobot.add_something_to_stash(part);
	
	##This is for the shop
	engine_remove_part_post(part, beingSold, beingBought);

## A step two for removing a [Part]. Used for interactions with the shop, according to old comments.
func engine_remove_part_post(part:Part, beingSold := false, beingBought := false):
	regeneratePartList = true;
	pass;

## Removes and then moves a Part.
func engine_move_part(part:Part, invPosition : Vector2i):
	if is_there_space_for_part(part, invPosition):
		var beingBought = false;
		if part.invHolderNode is ShopStall:
			beingBought = true;
		remove_part(part, TYPE_NIL,TYPE_NIL, beingBought);
		add_part(part, invPosition);
		#deselect_part();
		select_part(part);
	pass

func engine_set_slot_at(x: int, y: int, part: Part):
	if engine_is_slot_free(x, y, part):
		var index = Vector2i(x, y);
		engineSlots[index] = part;

func add_part_from_scene(x: int, y:int, _partScene:String, activeSlot = null):
	if engine_is_slot_free(x,y, null):
		var partScene = load(_partScene);
		var part = partScene.instantiate();
		if part is PartActive && activeSlot is int && activeSlot != null:
			add_child(part);
			add_part(part, Vector2i(x,y), false);
			part.set_equipped(true);
			return
		else:
			print("Adding ", part.name)
			add_child(part);
			add_part(part, Vector2i(x,y), false);
			return
		part.queue_free();


##This is in here for parts like Repair to look at; Returns a fixed 0 here, but the player's version ([InventoryPlayer]) returns a different value based on the shop.
func get_heal_price():
	return 0;
##This is in here for parts like Repair to look at; Returns a fixed 1 here, but the player's version ([InventoryPlayer]) returns a different value based on the shop.
func get_heal_amount():
	return 1;

## Selects the given [Part] through this [Piece]'s [member hostRobot] (or the player if we're in the shop), then returns it.
func select_part(part:Part, foo:bool = !part.selected if is_instance_valid(part) else TYPE_NIL):
	if is_instance_valid(part):
		if has_robot_host():
			selectedPart = hostRobot.select_part(part, foo);
		elif inShop:
			var player = GameState.get_player();
			if is_instance_valid(player):
				selectedPart = player.select_part(part, foo);
	return selectedPart;

## Deselects [member selectedPart] if it exists.
func deselect_part():
	if is_instance_valid(selectedPart):
		select_part(selectedPart, false);
	else:
		selectedPart = null;

## Gets [member selectedPart] or null.
func get_selected_part():
	if is_instance_valid(selectedPart):
		if ! selectedPart.selected:
			select_part(selectedPart, true)
		return selectedPart;
	return null;

## Deletes all [Part]s contained within [member engineSlots]. Optionally [param destroy]s or [param stash]es the [Part] to the host robot.
func engine_clear(destroy := true, stash := true):
	regeneratePartList = true;
	while listOfParts.size() > 0:
		for part in listOfParts:
			remove_part(part, destroy, TYPE_NIL, TYPE_NIL, stash);
	regeneratePartList = true;

@export_category("Modifier Management")

## Clears all modifiers.
func partMods_clear_all():
	for part in listOfParts:
		if part is Part:
			part.mods_reset(true);
	pass

## Deploys all modifiers. [b]VERY[/b] HEFTY.
func partMods_deploy():
	##All bonuses cleared.
	partMods_clear_all();
	##Organizes all parts.
	var parts = prioritized_parts();
	for part in parts:
		if part is Part:
			part.mods_distribute();
	##Applies all modifiers after the fact.
	for part in listOfParts:
		if part is Part:
			part.mods_apply_all();
	##Runs mods_conditional_post().
	for part in listOfParts:
		if part is Part:
			part.mods_conditional_post();
	##Prints the modifiers of the parts as a debug.
	for part in listOfParts:
		if part is Part:
			print_rich("[color=green]", part.partName, " ", part.incomingModifiers)
			if part is PartActive:
				print_rich(part.mod_energyCost);
				print_rich(part.energyCost);
				print_rich(part.get_energy_cost());
	pass

## Organizes a given list of parts (default [member listOfPieces]) by the order in which they should be prioritized.[br]
## Part priorty is first priority, then index, then age, then finally the internal ordering of the engine array.
func prioritized_parts(partsArray : Array[Part] = listOfParts) -> Array:
	var partPrio = {};
	##Should end up as this dict: {part.get_effect_priority() : {part.get_inventory_slot_priority() : {part.get_age() : [mod, mod, ...]}}
	for part in partsArray:
		if is_instance_valid(part):
			print(part.partName, " ", part.outgoingModifiers.size())
			if part.outgoingModifiers.size() > 0:
				var prio = part.get_effect_priority();
				var IDX = part.get_inventory_slot_priority();
				var age = part.get_age();
				print(prio, IDX, age)
				
				if partPrio.has(prio):
					if partPrio[prio].has(IDX):
						if partPrio[prio][IDX].has(age):
							partPrio[prio][IDX][age].append(part);
						else:
							partPrio[prio][IDX][age] = [part];
					else:
						partPrio[prio][IDX] = {age : [part]};
				else:
					partPrio[prio] = {IDX : {age : [part]}}
	
	print(partPrio)
	
	var returnArray = [];
	
	for lv1 in partPrio.keys(): ## looping thru part priority
		var lv1Dict = partPrio[lv1]
		for lv2 in lv1Dict.keys(): ##looping thru index
			var lv2Dict = lv1Dict[lv2]
			for lv3 in lv2Dict.keys(): ##looping thru age
				var lv3Array = lv2Dict[lv3]
				returnArray.append_array(lv3Array); ##Appends the 3rd level to the array
	print(returnArray)
	return returnArray;
