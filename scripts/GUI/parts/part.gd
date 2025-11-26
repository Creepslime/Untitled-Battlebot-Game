@icon ("res://graphics/images/class_icons/part.png")
##The base class for Parts the player and enemies use.[br]
##TODO: Placed within the engines of [Piece]s.
extends StatHolderControl
class_name Part


var invPosition := Vector2i(-9,-9);
var partBounds : Vector2i;
var inPlayerInventory := false;
var ownedByPlayer := false;
var invHolderNode : Control;
var thisBot : Combatant;

@export_group("References")
@export var textureBase : Control;
@export var textureIcon : TextureRect;
@export var tilemaps : PartTileset;
@export var inventoryNode : Inventory; ##@deprecated
@export var hostPiece : Piece;
@export var hostShopStall : ShopStall;
@export var hostRobot : Robot:
	get:
		if is_instance_valid(hostPiece):
			var _bot = hostPiece.get_host_robot();
			if is_instance_valid(_bot):
				hostRobot = _bot;
		elif is_instance_valid(hostShopStall):
			var _bot = hostShopStall.player;
			if is_instance_valid(_bot):
				hostRobot = _bot;
		return hostRobot;

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
	register_stat("ContactCooldown", contactCooldown, StatHolderManager.statIconCooldown, StatHolderManager.statTags.Clock);
	
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
	for index in dimensions:
		var button = %Buttons.buttonPrefab.instantiate();
		%Buttons.add_child(button);
		
		button.part = self;
		button.buttonHolder = %Buttons;
		
		button.set_deferred("position", index * 48);

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
	SND.play_purchase_sound();
	remove_and_add_to_stash(robot);

func remove_and_add_to_stash(robotOverride := hostRobot):
	hostRobot = robotOverride;
	if is_instance_valid(hostPiece):
		hostPiece.remove_part(self, false, false, false, true);
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
		%Buttons.disable();

## Acts to actually set [member selected].
func _on_buttons_on_select(foo:bool):
	#print("Part button being selected with foo ",foo)
	select(foo);
	pass # Replace with function body.

func select(foo:bool):
	#prints(partName,"selecting: ", foo)
	%Buttons.set_pressed(foo, false);
	robot_move_mode(false)
	
	if ! selected == foo: 
		selected = foo;
		if is_instance_valid(hostRobot):
			if foo:
				if hostRobot.selectedPart != self:
					#print("Selecting part from hostRobot in Part.select")
					hostRobot.select_part(self, foo);
			else:
				#print("Deselecting all parts from hostRobot in Part.select")
				hostRobot.deselect_all_parts();
		if is_equipped():
			if foo:
				if !hostPiece.get_selected():
					hostPiece.select();
					hostPiece.select_part(self);

func move_mode(enable:bool):
	%Buttons.move_mode_enable(enable);

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
	%Buttons.disable(_disabled);

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
		print_rich("[color=blue]", partName, " adding ", newModName)
		outgoingModifiersRef.append(newMod);
	outgoingModifiers = outgoingModifiersRef.duplicate(true);

##Resets all modified values back to 0. Extend with mods that are added in later derivative classes.
func mods_reset(resetArrays := false):
	print_debug("Resetting Modifiers for ", partName)
	if resetArrays:
		distributedModsAlready = false;
		incomingModifiers.clear();
		outgoingModifiers.clear();
		outgoingModifiers = outgoingModifiersRef.duplicate(true);
		print_debug("Full Reset");
	appliedModsAlready = false;
	appliedModsAlready_recursion = false;
	mod_scrapCost = mod_resetValue.duplicate();
	mod_sellPercent = mod_resetValue.duplicate();
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
	print_debug(partName, " Distributing mods")
	mods_validate();
	mods_conditional();
	if not distributedModsAlready:
		if not appliedModsAlready_recursion:
			mods_apply_all();
		var outMods = outgoingModifiers;
		for mod in outMods:
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
		print(partName, " already has ",  inMod.modName)
	else:
		incomingModifiers.append(inMod);
		print_debug(partName, " Recieving mod ", inMod.modName)
	pass

##Applies a given modifier to itself.
func mods_apply(propertyName : String, add:= 0.0, flat := 0.0, mult := 0.0):
	print_debug(partName, " applying mod for ", propertyName)
	var property = get(propertyName)
	if property:
		print(property)
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

func mods_reset_and_apply_all():
	print_debug(partName, " resetting all mods and applying them")
	mods_reset();
	mods_apply_all();

##Applies all of the modifiers in priority order gathered from [Part.prioritized_mods].
func mods_apply_all():
	mods_validate();
	print(partName, " incoming modifiers: ",incomingModifiers)
	var inMods = prioritized_mods(incomingModifiers);
	for mod in incomingModifiers:
		mod.apply_modifier();
	appliedModsAlready_recursion = true;
	mods_distribute();
	appliedModsAlready = true;
	mods_validate();

func mods_validate():
	print(partName, " validating mods")
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
