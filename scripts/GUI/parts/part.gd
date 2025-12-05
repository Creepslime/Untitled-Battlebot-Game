@icon ("res://graphics/images/class_icons/part.png")
##The base class for Parts the player and enemies use.[br]
##TODO: Placed within the engines of [Piece]s.
extends StatHolderControl
class_name Part


var invPosition := Vector2i(-9,-9); ## The position in the engine this Part is.
var partBounds : Vector2i; ## The tiles this Part occupies in an Engine.
var inPlayerInventory := false; ## Set when this Part gets added to the shop, or added to the player robot.
var ownedByPlayer := false; ## Set when the player buys this Part and adds it to their pieces or stash.
var invHolderNode : Control; ## The control this is reparented to.
var thisBot : Combatant; ## @deprecated

@export_group("References (internal)")
@export var textureBase : Control;
@export var textureIcon : TextureRect;
@export var tilemaps : PartTileset;
@export var buttonsHolder : PartButtonHolder;
@export_group("References (external)")
@export var inventoryNode : Inventory; ##@deprecated
@export var hostPiece : Piece:
	set(newValue):
		if hostPiece != newValue:
			hostPiece = newValue;
			regenHostData = true;
@export var hostShopStall : ShopStall;
@export var hostRobot : Robot:
	get:
		#if hostRobot != null:
			#return hostRobot;
		#if is_instance_valid(hostPiece):
			#var _bot = hostPiece.hostRobot;
			#if is_instance_valid(_bot):
				#hostRobot = _bot;
		#elif is_instance_valid(hostShopStall):
			#var _bot = hostShopStall.player;
			#if is_instance_valid(_bot):
				#hostRobot = _bot;
		#hostRobot = null;
		return hostRobot;
	set(newValue):
		if hostRobot != newValue:
			hostRobot = newValue;
			regenHostData = true;

var selected := false;

@export_subgroup("Gameplay")
@export var weightBase := 0;

@export var dimensions : Array[Vector2i];
@export_subgroup("Shop")
var contactCooldown := 0.25; ## If this Part has an ability that applies when the Piece it's on deals contact damage, then this is how long that should run.
@export var scrapCostBase : int;
var scrapSellModifier := 1.0; ## @deprecated
var scrapSellModifierBase := (2.0/3.0);
var scrapSalvageModifierBase := (2.0/3.0);
@export var myPartType := partTypes.UNASSIGNED;
@export var myPartRarity := partRarities.COMMON;
@export var poolWeight := 1; ##This is multiplied by 5 when Rare, 10 when Uncommon, and 15 when Common.

@export_subgroup("Vanity")
@export var partName := "Part";
@export_multiline var partDescription := "No description given.";
@export var partIcon : CompressedTexture2D;
@export var partIconOffset := Vector2(0.0,0.0);
@export var invSprite : CompressedTexture2D;
@export var screwSprite : CompressedTexture2D;

enum partTypes {
	UNASSIGNED,
	PASSIVE,
	UTILITY,
	MELEE,
	RANGED,
	TRAP,
}

enum partRarities {
	COMMON,
	UNCOMMON,
	RARE,
}

func _ready():
	#dimensions = [Vector2i(0,0), Vector2i(0,1), Vector2i(1,0), Vector2i(1,1)]
	if dimensions == null:
		dimensions = [Vector2i(0,0)]
	
	get_age();
	mods_prepare_innate();
	stat_registry();
	ability_validation();
	
	##Set part type
	if myPartType == partTypes.UNASSIGNED:
		if self is PartActive:
			if self is PartActiveProjectile:
				myPartType = partTypes.RANGED;
			elif self is PartActiveMelee:
				myPartType = partTypes.MELEE;
			else:
				myPartType = partTypes.UTILITY;
		else:
			myPartType = partTypes.PASSIVE;

func stat_registry():
	## Stats regarding energy cost.
	register_stat("PassiveEnergyDrawMultiplier", energyDrawPassiveMultiplier, StatHolderManager.statIconEnergy, StatHolderManager.statTags.Battery, StatHolderManager.displayModes.ABOVE_ZERO_NOT_999);
	register_stat("PassiveEnergyRegeneration", energyGenerationPassiveBaseOverride, StatHolderManager.statIconEnergy, StatHolderManager.statTags.Battery, StatHolderManager.displayModes.NOT_ZERO_ABSOLUTE_VALUE);
	register_stat("PassiveCooldownMultiplier", passiveCooldownTimeMultiplier, StatHolderManager.statIconCooldown, StatHolderManager.statTags.Clock);
	register_stat("ContactCooldown", contactCooldown, StatHolderManager.statIconCooldown, StatHolderManager.statTags.Clock);
	
	## Stats that only matter if the thing has abilities.
	if activeAbilitiesDistributed.size() > 0:
		register_stat("ActiveEnergyDrawMultiplier", energyDrawActiveMultiplier, StatHolderManager.statIconEnergy, StatHolderManager.statTags.Battery);
		register_stat("ActiveCooldownMultiplier", activeCooldownTimeMultiplier, StatHolderManager.statIconCooldown, StatHolderManager.statTags.Clock);
	
	#Stats regardig Scrap Cost.
	register_stat("ScrapCost", scrapCostBase, StatHolderManager.statIconScrap, StatHolderManager.statTags.Worth, StatHolderManager.displayModes.ALWAYS, StatHolderManager.roundingModes.Ceili);
	register_stat("ScrapSellModifier", scrapSellModifierBase, StatHolderManager.statIconScrap, StatHolderManager.statTags.Worth, StatHolderManager.displayModes.IF_MODIFIED);
	register_stat("ScrapSalvageModifier", scrapSalvageModifierBase, StatHolderManager.statIconScrap, StatHolderManager.statTags.Worth, StatHolderManager.displayModes.IF_MODIFIED);
	register_stat("Weight", weightBase, StatHolderManager.statIconWeight, StatHolderManager.statTags.Hull);
	register_stat("Integrity", 1.0, StatHolderManager.statIconHeart, StatHolderManager.statTags.Hull);
	pass;

func set_age_and_name():
	ageOrdering = GameState.get_unique_part_age();
	set("name", StringName(str(partName, "_", ageOrdering)));

##Run when the part gets added to the player's inventory via InventoryPlayer.add_part_post().
func inventory_vanity_setup():
	#print("somethin' fishy....")
	textureIcon.set_deferred("texture", partIcon);
	textureIcon.set_deferred("position", (partIconOffset*48) + Vector2(10,10));
	_populate_buttons();
	tilemaps.call_deferred("set_pattern", dimensions, myPartType, myPartRarity)
	#tilemaps.set_pattern();
	textureBase.show();

##Adds the buttons that let you click the part and move it around and stuff. Should theoretically only ever run if placed into the inventory of the player.
func _populate_buttons():
	buttonsHolder.clear_buttons();
	
	for index in dimensions:
		
		var button = buttonsHolder.buttonPrefab.instantiate();
		buttonsHolder.add_child(button);
		
		button.part = self;
		button.buttonHolder = buttonsHolder;
		
		button.set_deferred("position", index * 48);
	
	buttonsHolder.regenButtons = true;

func _get_part_type() -> partTypes:
	return myPartType;

func _get_sell_price():
	var discount = (1.0) * scrapSellModifier * scrapSellModifierBase;
	
	var sellPrice = discount * scrapCostBase
	
	return roundi(max(1, (sellPrice + mod_sellPercent.add)  * ((1 + mod_sellPercent.flat) * mod_sellPercent.mult)))

func _get_buy_price(_discount := 0.0, markup:=0.0, fixedDiscount := 0, fixedMarkup := 0):
	var discount = 1.0 + _discount + markup;
	
	var sellPrice = discount * scrapCostBase;
	
	return roundi(max(1, (sellPrice + fixedDiscount + fixedMarkup + mod_scrapCost.add) * ((1 + mod_scrapCost.flat) * mod_scrapCost.mult)))

func try_buy_from_shop() -> bool:
	if is_instance_valid(hostShopStall):
		return hostShopStall.try_buy_part();
	return false;

func start_buying(robot : Robot):
	hostShopStall.buyQueued = false;
	hostShopStall.partRef = null;
	hostShopStall = null;
	hostRobot = robot;
	ownedByPlayer = true;
	SND.play_purchase_sound();
	remove_and_add_to_stash(robot);

func is_sellable():
	return inPlayerInventory and hostShopStall == null;

func try_sell():
	if is_sellable():
		ScrapManager.add_scrap(_get_sell_price(), "Sell Piece");
		destroy();
		return true;
	return false;

func remove_and_add_to_stash(robotOverride := hostRobot):
	hostRobot = robotOverride;
	if is_instance_valid(hostPiece):
		hostPiece.engine_remove_part(self, false, false, false, true);
	else:
		hostRobot.add_something_to_stash(self);

func is_equipped():
	return is_instance_valid(get_engine()) and is_instance_valid(hostPiece.get_host_robot());

## Returns [member hostPiece], as that is its engine.
func get_engine() -> Piece:
	return hostPiece;


## Returns [member hostPiece], as that is its engine.
func get_engine_hud() -> PartsHolder_Engine:
	if is_equipped():
		return hostPiece.get_host_robot().engineViewer;
	return null;

func detatch_from_engine():
	if is_equipped():
		hostPiece.engine_remove_part(self);

func _get_part_bounds() -> Vector2i:
	var highestX = 1; 
	var lowestX = 0;
	var highestY = 1;
	var lowestY = 0;
	
	for index in dimensions:
		var x = index.x + 1;
		highestX = max(x, highestX)
		lowestX = min(x, lowestX)
		var y = index.y + 1;
		highestY = max(y, highestY)
		lowestY = min(y, lowestY)
	
	var width = highestX - lowestX;
	var height = highestY - lowestY;
	
	partBounds = Vector2i(width, height);
	
	return partBounds;


func _process(delta):
	super(delta);
	if (inventoryNode is InventoryPlayer):
		textureBase.show();
		if inPlayerInventory:
			if ownedByPlayer:
				textureBase.global_position = invHolderNode.global_position + Vector2(invPosition * 48);
			else:
				textureBase.global_position = invHolderNode.global_position;
	elif is_instance_valid(hostShopStall):
		textureBase.show();
		var bot = GameState.get_player();
		if is_instance_valid(bot):
			hostRobot  = bot;
		#if inPlayerInventory:
			#if ownedByPlayer:
				#textureBase.global_position = invHolderNode.global_position + Vector2(invPosition * 48);
			#else:
		textureBase.global_position = invHolderNode.global_position;
		reparent(hostShopStall.bg_Part)
	elif is_instance_valid(hostRobot):
		if hostRobot is Robot_Player:
			reparent(hostRobot.engineViewer);
			invHolderNode = hostRobot.engineViewer;
			textureBase.global_position = invHolderNode.global_position + Vector2(invPosition * 48) + Vector2(24, 24);
			if is_instance_valid(get_engine_hud()):
				disable(! (hostPiece.get_selected() and get_engine_hud().curState == PartsHolder_Engine.doorStates.OPEN))
			else:
				disable()
			if ! is_instance_valid(hostPiece):
				visible = false;
			
	else:
		if is_instance_valid(get_parent()):
			get_parent().remove_child(self);
		textureBase.hide();
		buttonsHolder.disable();

func _physics_process(delta):
	super(delta);
	if ! is_paused():
		phys_process_timers(delta);
		phys_process_abilities(delta)

func phys_process_timers(delta):
	if ! is_paused():
		selectionCooldown -= 1;
	pass;

## Acts to actually set [member selected].
func _on_buttons_on_select(foo:bool):
	select(foo);
	pass # Replace with function body.

var selectionCooldown := 5;

func select(foo:bool):
	#prints(partName,"selecting: ", foo)
	
	if ! selected == foo: 
		## Unset move mode.
		robot_move_mode(false);
		
		## Check if we're on selection cooldown. TESTING: Only proceed if we're unselecting.
		if foo:
			if selectionCooldown > 0: return;
		elif !foo:
			if selectionCooldown > 0: pass;
		
		## Set the selection cooldown, and log the old one.
		var selectionCooldownPre = selectionCooldown;
		selectionCooldown = 3;
		
		## Set selected to the new value.
		selected = foo;
		
		if is_instance_valid(hostRobot):
			if foo:
				if hostRobot.selectedPart != self:
					#print("Selecting part from hostRobot in Part.select")
					hostRobot.select_part(self, foo);
			else:
				hostRobot.deselect_all_parts();
		## 
		if is_equipped():
			if foo:
				if !hostPiece.get_selected():
					hostPiece.select();
					hostPiece.select_part(self);
		
		## Set the pressed state of the buttons after we are certain of our selected status.
		call_deferred("buttons_gfx_update")

## COnvenience function. Equivalent to [code]select(false)[/code].
func deselect():
	select(false);

func buttons_gfx_update():
	#print("buttons_gfx_update with current selected status:", selected)
	buttonsHolder.call_deferred("set_pressed", selected, false)

func move_mode(enable:bool):
	buttonsHolder.move_mode_enable(enable);

func robot_move_mode(enable:bool):
	if is_instance_valid(hostRobot):
		hostRobot.part_move_mode_enable(self, enable);

func robot_is_in_move_mode_with_me() -> bool:
	if is_instance_valid(hostRobot):
		return is_instance_valid(hostRobot.partMovementPipette) and hostRobot.partMovementPipette == self;
	return false;

func is_moveable() -> bool:
	return inPlayerInventory and !is_instance_valid(hostShopStall);

func destroy():
	select(false);
	queue_free();

func disable(_disabled:=true):
	buttonsHolder.disable(_disabled);

####### Hooks-adjacent stuff.

##Fired at the start of a round.
func new_round():
	pass

##Fired at the end of a round.
func end_round():
	pass

##Fired when the player takes damage.
func take_damage(damage:float):
	pass

##Fired when this part is sold.
func on_sold():
	pass;

##Fired when this part is bought.
func on_bought():
	pass;

####### Modifier functions.

@export_group("Modifiers")
##Shouldn't be modified outside of when the part is initialized. Acts as an ID for effect tiebreaking.
var ageOrdering := 0;
##Adjusts the ordering of when this part's effects get distributed. The lower the number, the earlier it'll fire.
@export var effectPriority := 0;
var incomingModifiers : Array[PartModifier];
@export var outgoingModifiers : Array[PartModifier];
var outgoingModifiersRef : Array[PartModifier]; ##Saves a backup of the modifiers.
var appliedModsAlready := false;
var appliedModsAlready_recursion := false;
var distributedModsAlready := false;

##The below variables are for modifier purposes.

##The base dict for modifiers to copy from.
const mod_resetValue = {"add": 0.0, "flat" : 0.0, "mult" : 1.0};
##Modifies the scrap cost. Uses the Mods system.
var mod_scrapCost := mod_resetValue.duplicate();
##Modifies the percentage of scrap you get back from selling. Uses the Mods system.
var mod_sellPercent := mod_resetValue.duplicate();


##Should only be called once at Part._ready(); Prepares all modifiers to amke them unique and have a unique name.
func mods_prepare_innate():
	for mod in outgoingModifiers:
		var newMod = mod.duplicate(true);
		newMod.owner = mod.owner;
		newMod.inventoryNode = inventoryNode;
		var newModName = mod.modName + "_" + str(name);
		newMod.modName = newModName;
		#print_rich("[color=blue]", partName, " adding ", newModName)
		outgoingModifiersRef.append(newMod);
	outgoingModifiers = outgoingModifiersRef.duplicate(true);

##Resets all modified values back to 0. Extend with mods that are added in later derivative classes.
func mods_reset(resetArrays := false):
	#print_debug("Resetting Modifiers for ", partName)
	if resetArrays:
		distributedModsAlready = false;
		incomingModifiers.clear();
		outgoingModifiers.clear();
		outgoingModifiers = outgoingModifiersRef.duplicate(true);
		#print_debug("Full Reset");
	appliedModsAlready = false;
	appliedModsAlready_recursion = false;
	mod_scrapCost = mod_resetValue.duplicate();
	mod_sellPercent = mod_resetValue.duplicate();
	
	reset_modifiers();
	pass;

func mods_create_modifier(_name : StringName, _modType : PartModifier.modifierType, _offset : Vector2i, _priority, _valueAdd := 0.0, _valueMult := 1.0, _enabledAtStart := true, ):
	var existingMod = mods_check_outModifier_exists(_name);
	if existingMod != null:
		existingMod.create_modifier(self, inventoryNode, _name, _modType, _offset, _priority, _valueAdd, _valueMult, _enabledAtStart);
	else:
		var newMod = PartModifier.new();
		outgoingModifiers.append(newMod);
		newMod.create_modifier(self, inventoryNode, _name, _modType, _offset, _priority, _valueAdd, _valueMult, _enabledAtStart);

func mods_check_outModifier_exists(modName : StringName) -> PartModifier:
	for mod in outgoingModifiers:
		if mod.modName == modName:
			return mod;
	return null;

func mods_check_inModifier_exists(modName : StringName) -> PartModifier:
	for mod in incomingModifiers:
		if mod.modName == modName:
			return mod;
	return null;

##Tries to fetch and then disable a modifier.
func mods_disable_outMod(modName : StringName, _enabled := false):
	var existingMod = mods_check_outModifier_exists(modName);
	if existingMod != null:
		existingMod.disable(_enabled);

##Distributes all outgoing modifiers.
func mods_distribute():
	#print_debug(partName, " Distributing mods")
	mods_validate();
	mods_conditional();
	if not distributedModsAlready:
		if not appliedModsAlready_recursion:
			mods_apply_all();
		var outMods = outgoingModifiers;
		for mod : PartModifier in outMods:
			mod.distribute_modifier();
			pass;
		distributedModsAlready = true;

##This function is run before the mods distribution process. Does nothing at base, must be overwritten to do anything.
func mods_conditional():
	#Add stuff in here
	pass;

##This function is run after the mods distribution process. Does nothing at base, must be overwritten to do anything.
func mods_conditional_post():
	#Add stuff in here
	pass;

##Returns an array of modifiers that fit the given ID.
func mods_get_all_with_tag(modTag : String, outgoing := true, incoming:=false) -> Array[PartModifier]:
	var allModifiers : Array[PartModifier] = [];
	if (outgoing):
		allModifiers.append_array(outgoingModifiers)
	if incoming:
		allModifiers.append_array(incomingModifiers)
	var mods : Array[PartModifier] = [];
	for mod in allModifiers:
		if mod.modTags.has(modTag):
			mods.append(mod);
	return mods;

##Adds a modifier to the part. Called from the modifier.[br]
##Will try to call the distribution script.
func mods_recieve(inMod : PartModifier):
	#var newMod = inMod.duplicate();
	#newMod.owner = inMod.get_owner();
	#newMod.inventoryNode = inventoryNode;
	#incomingModifiers.append(newMod);
	if mods_check_inModifier_exists(inMod.modName):
		#print(partName, " already has ",  inMod.modName)
		pass;
	else:
		incomingModifiers.append(inMod);
		#print_debug(partName, " Recieving mod ", inMod.modName)
	pass

##Applies a given modifier to itself.
func mods_apply(propertyName : String, add:= 0.0, flat := 0.0, mult := 0.0):
	#print_debug(partName, " applying mod for ", propertyName)
	var property = get(propertyName)
	if property:
		#print(property)
		if property.has("add"):
			property["add"] += add;
		else:
			property["add"] = add;
		
		if property.has("flat"):
			property["flat"] += flat;
		else:
			property["flat"] = flat;
		
		if property.has("mult"):
			property["mult"] *= mult;
		else:
			property["mult"] = mult;
		print(property)
		
		return true;
		
	return false;

## Runs [method mods_reset], then [method mods_apply_all].
func mods_reset_and_apply_all():
	#print_debug(partName, " resetting all mods and applying them")
	mods_reset();
	mods_apply_all();

## Applies all of the modifiers in priority order gathered from [method Part.prioritized_mods].
func mods_apply_all():
	mods_validate();
	#print(partName, " incoming modifiers: ",incomingModifiers)
	var inMods = prioritized_mods(incomingModifiers);
	for mod in incomingModifiers:
		mod.apply_modifier();
	appliedModsAlready_recursion = true;
	mods_distribute();
	appliedModsAlready = true;
	mods_validate();

func mods_validate():
	#print(partName, " validating mods")
	for mod in outgoingModifiers:
		if mod is PartModifier:
			if mod.inventoryNode == null:
				mod.inventoryNode = inventoryNode;
			if mod.owner == null:
				mod.owner = self;

##Organizes a given list by the order in which they should be prioritized.[br]
##Mod priorty is first priority, then owner index, then owner age, then finally whatever method the engine is choosing to order arrays.
func prioritized_mods(modsArray : Array[PartModifier]) -> Array:
	var modPrio = {};
	##Should end up as this dict: {mod.priority : {modOwnerIDX : {modOwnerAge : [mod, mod]}}
	for mod in modsArray:
		if mod.is_applicable():
			var modOwnerIDX = mod.get_owner_index();
			var modOwnerAge = mod.get_owner_age();
			
			if modPrio.has(mod.priority):
				var lv1 : Dictionary = modPrio[mod.priority]
				if lv1.has(modOwnerIDX):
					var lv2 : Dictionary = lv1[modOwnerIDX];
					if lv2.has(modOwnerAge):
						var lv3 : Array = lv2[modOwnerAge]
						#pass
						lv3.append(mod);
					else:
						lv2[modOwnerAge] = [mod];
				else:
					lv1[modOwnerIDX] = {modOwnerAge : [mod]};
			else:
				modPrio[mod.priority] = {modOwnerIDX : {modOwnerAge : [mod]}}
	
	var returnArray = [];
	
	for lv1 in modPrio.keys(): ## looping thru mod priority
		var lv1Dict = modPrio[lv1]
		for lv2 in lv1Dict.keys(): ##looping thru index
			var lv2Dict = lv1Dict[lv2]
			for lv3 in lv2Dict.keys(): ##looping thru age
				var lv3Array = lv2Dict[lv3]
				returnArray.append_array(lv3Array); ##Appends the 3rd level to the array
	
	return returnArray;

##Returns the value for inventory slot priority based on [Part.slotsDict].
func get_inventory_slot_priority():
	if slotsDict.has(invPosition):
		return slotsDict[invPosition];
	return 0;

##A dictionary whose sole purpose is as reference for [Part.get_inventory_slot_priority].
const slotsDict := {
	## Row 0
	Vector2i(0,0) : 0,
	Vector2i(1,0) : 1,
	Vector2i(2,0) : 2,
	Vector2i(3,0) : 3,
	Vector2i(4,0) : 4,
	## Row 1
	Vector2i(0,1) : 5,
	Vector2i(1,1) : 6,
	Vector2i(2,1) : 7,
	Vector2i(3,1) : 8,
	Vector2i(4,1) : 9,
	## Row 2
	Vector2i(0,2) : 10,
	Vector2i(1,2) : 11,
	Vector2i(2,2) : 12,
	Vector2i(3,2) : 13,
	Vector2i(4,2) : 14,
	## Row 3
	Vector2i(0,3) : 15,
	Vector2i(1,3) : 16,
	Vector2i(2,3) : 17,
	Vector2i(3,3) : 18,
	Vector2i(4,3) : 19,
	## Row 4
	Vector2i(0,4) : 20,
	Vector2i(1,4) : 21,
	Vector2i(2,4) : 22,
	Vector2i(3,4) : 23,
	Vector2i(4,4) : 24,
}

##Returns [Part.ageOrdering].
func get_age():
	return ageOrdering;

##Returns [Part.effectPriority].
func get_effect_priority():
	return effectPriority;

################## HOST DATA

var hasHostPiece := false:
	get:
		regen_host_data();
		return hasHostPiece;
var hasHostRobot := false:
	get:
		regen_host_data();
		return hasHostRobot;
var hostRobotIsPlayer := false:
	get:
		regen_host_data();
		return hostRobotIsPlayer;
var hostRobotIsEnemy := false:
	get:
		regen_host_data();
		return hostRobotIsPlayer;
var equippedByRobot := false:
	get:
		regen_host_data();
		return equippedByRobot;
var equippedByPlayer := false:
	get:
		regen_host_data();
		return equippedByPlayer;
var equippedByEnemy := false:
	get:
		regen_host_data();
		return equippedByPlayer;

## Regenerates a large number of "host" variables when [code]true[/code]. See [method regen_host_data].
var regenHostData := true; 
## Regenerates a large number of "host" variables.
## Called whenever a "host" variable is called, but returns immediately if [member regenHostData] is [code]not true[/code], unless [param force] IS [code]true[/code].[br]
## Regenerates:[br]- [member hasHostSocket][br]- [member hasHostPiece][br]- [member hostPiece][br]- [member hasHostRobot][br]- [member hostRobotIsPlayer][br]- [member hostRobotIsEnemy][br]- [member equippedByRobot][br]- [member equippedByPlayer][br]- [member equippedByEnemy][br]- (more to come, probably)
func regen_host_data(force := false):
	if ! regenHostData and ! force: return;
	GameState.profiler_ping_create("Regenerating Host Data for Part");
	regenHostData = false; ## Set this to false now so we don't get recursion funnies.
	
	## Host piece requires us to be assigned to a socket, otherwise things like previews break.
	hasHostPiece = false;
	if is_instance_valid(get_engine()):
		hasHostPiece = true;
	
	## Host robot data is almost guaranteed if we have a host piece and socket, but we need to check anyway.
	hasHostRobot = false;
	hostRobotIsPlayer = false;
	hostRobotIsEnemy = false
	if is_instance_valid(hostRobot):
		hasHostRobot = true;
		
		if hostRobot is Robot_Enemy:
			hostRobotIsEnemy = true;
		elif hostRobot is Robot_Player:
			hostRobotIsPlayer = true;
	
	equippedByRobot = hasHostRobot and hasHostPiece;
	equippedByPlayer = equippedByRobot and hostRobotIsPlayer;
	equippedByEnemy = equippedByRobot and hostRobotIsEnemy;

####################### ABILITY AND ENERGY MANAGEMENT

@export_category("Ability")

@export_subgroup("AbilityManagers")
@export var activeAbilities : Array[AbilityManager] = [];
var activeAbilitiesDistributed : Array[AbilityManager] = [];
@export var passiveAbilities : Array[AbilityManager] = [];
var passiveAbilitiesDistributed : Array[AbilityManager] = [];

@export_subgroup("Ability Details")
@export var energyDrawPassiveMultiplier := 1.0; ##power drawn each frame, multiplied by time delta. If this is negative, it is instead power being generated each frame.
@export var energyDrawActiveMultiplier := 1.0; ##power drawn when you use any this piece's active abilities, given that it has any.
@export var energyDrawActiveBaseOverride : float = 999;
@export var energyDrawPassiveBaseOverride : float = 999;
@export var energyGenerationPassiveBaseOverride : float = 0.0;
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
			action.queue_cooldown(statHolderID, get_stat("PassiveCooldownMultiplier"));
		else:
			action.queue_cooldown(statHolderID, get_stat("ActiveCooldownMultiplier"));

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
	if equippedByRobot:
		return hostRobot.is_running_cooldowns();
	return false;
	
##Physics process step for abilities.
func phys_process_abilities(delta):
	##Run cooldown behaviors.
	#GameState.profiler_time_usec_start()
	cooldown_behavior();
	#GameState.profiler_time_usec_end("phys_process_abilities cooldown_behavior check (ID %s)" % [statHolderID])
	##Use the passive ability of this guy.
	use_looping_passives();

##Fires every physics frame when the Piece's passive or active abilities are on cooldown, via [method on_cooldown].
func cooldown_behavior(cooldown : bool = on_cooldown()):
	if on_contact_cooldown():
		pass;
	else:
		pass;
	pass;

func try_sap_energy(amt:float):
	if ! equippedByRobot: return;
	var bot = hostRobot;
	var result = hostPiece.try_sap_energy(amt);
	energyDrawCurrent += amt;
	queue_refresh_incoming_energy();
	#if result:
		##TextFunc.flyaway(true, global_position + Vector3(0,2,0), "lightgreen");
		##print_rich("[color=green]ABILITY RUN: ENERGY SAP WORKED")
	#else:
		##TextFunc.flyaway(false, global_position + Vector3(0,2,0), "lightred");
		##print("[color=red]ABILITY RUN: ENERGY SAP BORKED")
	return result;

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
	hostPiece.refreshIncomingEnergy = true;
	refreshIncomingEnergy = true;

func calc_incoming_energy():
	if ! refreshIncomingEnergy: return incomingPower;
	refreshIncomingEnergy = false;
	if equippedByRobot != null:
		#print(get_host_socket().get_energy_transmitted())
		var powerTransmitted = hostPiece.get_outgoing_energy();
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
	if ! is_equal_approx(energyDrawActiveBaseOverride, 999):
		override = energyDrawActiveBaseOverride;
	if ability.energyCostStatName != null and ability.energyCostStatName != "":
		if has_stat(ability.energyCostStatName):
			override = get_stat(ability.energyCostStatName);
	return ( ability.get_energy_cost_base(override) * get_stat("ActiveEnergyDrawMultiplier") );

func get_passive_energy_cost(passiveAbility : AbilityManager):
	var stat = get_stat("PassiveEnergyDrawMultiplier");
	var override = null;
	if ! is_equal_approx(energyDrawPassiveBaseOverride, 999):
		override = energyDrawPassiveBaseOverride;
	if passiveAbility.energyCostStatName != null and passiveAbility.energyCostStatName != "":
		if has_stat(passiveAbility.energyCostStatName):
			override = get_stat(passiveAbility.energyCostStatName);
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
	## Fix host data, if a fix is queued.
	regen_host_data();
	## Check if we are equipped.
	if ! equippedByRobot:
		#print("not equipped to a robot")
		return false;
	## Check if the Piece is paused.
	if is_paused():
		#print("paused")
		return false;
	## Check that the ability is owned by this piece.
	if get_local_ability(action) == null:
		#print("local ability is null")
		return false;
	## Check if it's disabled.
	if action.is_disabled(statHolderID):
		#print("ability is disabled")
		return false;
	## Check the bot, and also check aliveness.
	if !hostRobot.is_conscious():
		#print("host robot is unconscious")
		return false;
	## Check that it's not on cooldown.
	if on_cooldown_action(action):
		#print("action is on cooldown")
		return false;
	## Passed. Moving on...
	return true;

## Checks if you can use a given ACTIVE ability.
func can_use_active(action : AbilityManager): 
	## Check that the thing is valid. If not, get the first ability in the relevant list.
	if ! is_instance_valid(action):
		if activeAbilitiesDistributed.size() > 0:
			action = activeAbilitiesDistributed.front();
		else:
			return false
	## Check all the checks passives and actives share.
	if not standard_ability_checks(action):
		#print("Failed something standard")
		return false;
	## Check that there's enough energy to run this active.
	if not test_energy_available(get_active_energy_cost(action)):
		return false;
	## You passed!
	return true;

## Checks if you can use a given PASSIVE ability.
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
	if passiveAbilitiesDistributed.is_empty(): return true;
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
		#print(passiveAbility)
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
	AbilityDistributor.distribute_all_abilities_to_part(self);
	print_rich("[color=pink]INIT ACTIVES:", activeAbilitiesDistributed);
	
	regen_namedActions(); ## Regenerates the actions list
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

## Checks if the ability given is inside of this Piece.
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
