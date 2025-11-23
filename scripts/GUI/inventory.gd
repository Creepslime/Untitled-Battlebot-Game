extends Control

class_name Inventory

var battleBotBody : RigidBody3D;
var combatHandler : CombatHandler;
var thisBot : Combatant;

var slots := {
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
	
	##Shop stalls
	"StallA" : null,
	"StallB" : null,
	"StallC" : null,
}

var listOfPieces : Array[Part] = [];
var selectedPart: Part;

func clear_slot_at(x: int, y: int):
	var index = Vector2i(x, y);
	if index in slots.keys():
		slots[index] = null;

func get_slot_at(x: int, y: int):
	var index = Vector2i(x, y);
	var pointer = null;
	
	if index in slots.keys():
		pointer = slots[index];
	
	return pointer


func is_slot_free(x: int, y: int, filterPart:Part) -> bool:
	var index = Vector2i(x, y);
	
	if index in slots.keys():
		var slotAt = get_slot_at(x, y)
		if slotAt == null:
			return true;
		else:
			if is_instance_valid(filterPart):
				if slotAt == filterPart:
					return true;
	return false;

func is_slot_in_bounds(x: int, y: int):
	var index = Vector2i(x, y);
	if index in slots.keys():
		return true;
	return false;

func is_slot_free_and_in_bounds(x: int, y: int, filterPart:Part, separateIntoDict := false):
	var free = is_slot_free(x, y, filterPart);
	var inBounds = is_slot_in_bounds(x, y);
	if separateIntoDict:
		return {"free" : free, "inBounds" : inBounds}
	else:
		return (free and inBounds);

func get_modified_part_dimensions(part: Part, modifier: Vector2i):
	var dimensions = part.dimensions;
	var coords = [];
	for index in dimensions:
		var newCoord = index + modifier;
		coords.append(newCoord);
	
	return coords

func check_coordinate_table_is_free(coords:Array, filterPart:Part):
	for index in coords:
		if is_slot_free(index.x, index.y,filterPart):
			pass
		else:
			return false
	return true

func is_there_space_for_part(part:Part, invPosition : Vector2i) -> bool:
	if is_instance_valid(part):
		var partCoords = get_modified_part_dimensions(part, invPosition)
		if check_coordinate_table_is_free(partCoords, part):
			return true;
	return false;

func add_part(part: Part, invPosition : Vector2i, noisy := false):
	var coordsToCheck = get_modified_part_dimensions(part, invPosition);
	
	if check_coordinate_table_is_free(coordsToCheck, part):
		#print("Coord table is free... somehow ", coordsToCheck)
		for index in coordsToCheck:
			set_slot_at(index.x, index.y, part);
		listOfPieces.append(part);
		part.invPosition = invPosition;
		part.inventoryNode = self;
		part.thisBot = thisBot;
		if part is PartActive:
			part.positionNode = battleBotBody;
			part.meshNode.reparent(battleBotBody);
		add_part_post(part, noisy);
	else:
		pass 
	pass

func add_part_post(part:Part, noisy:=false):
	partMods_deploy();
	pass;

func remove_part(part: Part, destroy:=false, beingSold := false, beingBought := false):
	var coordsToRemove = get_modified_part_dimensions(part, part.invPosition);
	part.invPosition = Vector2i(0,0);
	if part is PartActive:
		part.positionNode = null;
		part.meshNode.reparent(part);
	
	if self is InventoryPlayer:
		part.inPlayerInventory = false;
	
	for coord : Vector2i in coordsToRemove:
		clear_slot_at(coord.x, coord.y);
	
	while listOfPieces.find(part) != -1:
		listOfPieces.remove_at(listOfPieces.find(part));
	
	##This is for the shop
	remove_part_post(part, beingSold, beingBought);
	
	part.invHolderNode = null;
	
	if destroy:
		part.destroy();
	

func remove_part_post(part:Part, beingSold := false, beingBought := false):
	pass;

func move_part(part:Part, invPosition : Vector2i):
	if is_there_space_for_part(part, invPosition):
		var beingBought = false;
		if part.invHolderNode is ShopStall:
			beingBought = true;
		remove_part(part, TYPE_NIL,TYPE_NIL, beingBought);
		add_part(part, invPosition);
		deselect_part();
	pass

func set_slot_at(x: int, y: int, part: Part):
	if is_slot_free(x, y, part):
		var index = Vector2i(x, y);
		slots[index] = part;

func add_part_from_scene(x: int, y:int, _partScene:String, activeSlot = null):
	if all_refs_valid():
		if is_slot_free(x,y, null):
			var partScene = load(_partScene);
			var part = partScene.instantiate();
			if part is PartActive && activeSlot is int && activeSlot != null:
				add_child(part);
				add_part(part, Vector2i(x,y), false);
				part.set_equipped(true);
				combatHandler.set_active_part(part, activeSlot, true);
				return
			else:
				print("Adding ", part.name)
				add_child(part);
				add_part(part, Vector2i(x,y), false);
				return
			part.queue_free();

func select_part(part:Part, foo:bool):
	if foo:
		if part != selectedPart:
			if is_instance_valid(selectedPart):
				selectedPart.select(false);
			selectedPart = part;
			print("selected new part: ", part);
	else:
		selectedPart = null;
		if is_instance_valid(part):
			if part.selected:
				part.select(false);
		print("Unselected part: ", part);

func deselect_part():
	if is_instance_valid(selectedPart):
		select_part(selectedPart, false);
	else:
		selectedPart = null;

func get_selected_part():
	if is_instance_valid(selectedPart):
		return selectedPart;
	return null;

func clear_inventory():
	while listOfPieces.size() > 0:
		for part in listOfPieces:
			remove_part(part);

#########################

##This is in here for parts like Repair to look at; Returns a fixed 0 here, but the player's version ([InventoryPlayer]) returns a different value based on the shop.
func get_heal_price():
	return 0;
##This is in here for parts like Repair to look at; Returns a fixed 1 here, but the player's version ([InventoryPlayer]) returns a different value based on the shop.
func get_heal_amount():
	return 1;

#########################

func _process(delta):
	assign_references();

func assign_references():
	if ! is_instance_valid(combatHandler):
		var par = get_parent();
		combatHandler = par.get_node("CombatHandler");
	
	if ! is_instance_valid(battleBotBody):
		var par = get_parent();
		battleBotBody = par.get_node("Body");
		
	if ! is_instance_valid(thisBot):
		var par = get_parent();
		if par is Combatant:
			thisBot = par;

func all_refs_valid():
	if is_instance_valid(combatHandler) and is_instance_valid(battleBotBody) and is_instance_valid(thisBot):
		return true;
	assign_references();
	return false;

func _physics_process(delta):
	if battleBotBody != null:
		pass





######### Below is stuff regarding part modifiers.

##Clears all modifiers.
func partMods_clear_all():
	for part in listOfPieces:
		if part is Part:
			part.mods_reset(true);
	pass

##Deploys all modifiers. [b]VERY[/b] HEFTY.
func partMods_deploy():
	##All bonuses cleared.
	partMods_clear_all();
	##Organizes all parts.
	var parts = prioritized_parts();
	for part in parts:
		if part is Part:
			part.mods_distribute();
	##Applies all modifiers after the fact.
	for part in listOfPieces:
		if part is Part:
			part.mods_apply_all();
	##Runs mods_conditional_post().
	for part in listOfPieces:
		if part is Part:
			part.mods_conditional_post();
	##Prints the modifiers of the parts as a debug.
	for part in listOfPieces:
		if part is Part:
			print_rich("[color=green]", part.partName, " ", part.incomingModifiers)
			if part is PartActive:
				print_rich(part.mod_energyCost);
				print_rich(part.energyCost);
				print_rich(part.get_energy_cost());
	pass

##Organizes a given list of parts (default [Inventory.listOfPieces]) by the order in which they should be prioritized.[br]
##Part priorty is first priority, then index, then age, then finally whatever method the engine is choosing to order arrays.
func prioritized_parts(partsArray : Array[Part] = listOfPieces) -> Array:
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
