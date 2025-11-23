extends Resource

class_name PartModifier;

@export var priority := 0.0;
@export var valueAdd : float = 0.0;
@export var valueFlatMult : float = 0.0;
@export var valueTimesMult : float = 1.0;
@export var modName : StringName;
@export var modTags : Array[String] = [str(modName)]; ##A list of ID strings for parts to reference. Basically groups.
@export var offset := Vector2i.ZERO;
@export var enabled := true;
@export var myTargetType := modifierTargetType.PIECE;
@export_subgroup("Deprecated")
@export var myModType : modifierType; ## @deprecated

var owner : Node; ##The owner of this modifier; AKA the one that applied it.
var target : Node: ## The target. Getter is [method try_get_target].
	get:
		return try_get_target(); 
var inventoryNode : Inventory; ## @deprecated
var currentlyApplying := false; ## Whether this is currently being applied. Calculated by [method apply_modifier].

func create_modifier(_owner : Node, _inventoryNode: Inventory, _name : StringName, _modType : modifierType, _offset : Vector2i, _priority, _valueAdd := 0.0, _valueFlatMult := 1.0, _valueTimesMult := 1.0, _enabledAtStart := true, ):
	owner = _owner;
	inventoryNode = _inventoryNode;
	modName = _name;
	myModType = _modType;
	offset = _offset;
	if ! (_priority is float):
		priority = 0.0;
	else:
		priority = _priority;
	valueAdd = _valueAdd;
	valueFlatMult = _valueFlatMult;
	valueTimesMult = _valueTimesMult;
	enabled = _enabledAtStart;
	return modName;

func edit_stat(propertyName : StringName, value):
	var property = get(propertyName)
	if property:
		set(propertyName, value)

## @deprecated
enum modifierType {
	ENERGY_COST,
	FIRE_RATE,
	DAMAGE_BASE,
	SELL_REFUND_PERCENT,
	SCRAP_COST,
}
## @deprecated
var modifierTypesDict = {
	modifierType.ENERGY_COST : "mod_energyCost",
	modifierType.FIRE_RATE : "mod_fireRate",
	modifierType.DAMAGE_BASE : "mod_damage",
	modifierType.SELL_REFUND_PERCENT : "mod_sellPercent",
	modifierType.SCRAP_COST : "mod_scrapCost",
}

## The thing this will attempt to target. Note: If you want it to affect "itself" (i.e a host [Part] or [Piece]), then you'll have to 
enum modifierTargetType {
	PART, ## Affects other [Part]s (or itself if on a part.)
	PIECE, ## Affects the host [Piece].
	ROBOT, ## Affects the host [Robot].
}

##Yoinks the owner. Might be null.
func get_owner():
	return owner;

func get_owner_priority():
	if owner is Part:
		return owner.effectPriority;
	return 0;

## Gets the statHolderID of the [param owner], if it is a StatHolder; Returns 0 if not.
func get_owner_age():
	if owner is StatHolder3D or owner is StatHolderControl:
		return owner.statHolderID;
	if owner is Part:
		return owner.ageOrdering;
	return 0;

func get_owner_index():
	if owner is Part:
		return owner.get_inventory_slot_priority();
	return 0;

##Returns Inventory.is_slot_free_and_in_bounds() witht he setting to make it a dictionary {"free":bool, "inBounds":bool} turned on.
func is_slot_free_and_in_bounds():
	var invPos = get_inventory_position();
	return inventoryNode.is_slot_free_and_in_bounds(invPos.x, invPos.y, null, true)

## Gets the position of the host if it is a Part.
func get_inventory_position():
	var invPosition = offset;
	if owner is Part:
		if owner.invPosition != null:
			invPosition += owner.invPosition;
	return invPosition;

##Tries to add itself to the target.
func distribute_modifier():
	if is_applicable():
		target.mods_recieve(self);

##Tries to apply itself to the target, if able.
func apply_modifier():
	currentlyApplying = try_apply_mod(modifierTypesDict[myModType]);

## Checks 
## For parts: Only returns true if there's a part where this modifier is supposed to apply, and this modifier is enabled.
func is_applicable():
	if ! enabled: return false;
	if ! is_instance_valid(owner): return false;
	return is_instance_valid(try_get_target());

## Sets [member target] to whatever this should be targeting.
func try_get_target():
	target = null;
	if ! is_instance_valid(owner): return null;
	
	match myTargetType:
		modifierTargetType.PART:
			var partAt = try_get_part_at_offset()
			print(modName + " has a part at the target");
			if is_instance_valid(partAt):
				target = partAt;
			pass;
		modifierTargetType.PIECE:
			var piece : Piece = try_get_host_piece();
			if is_instance_valid(piece):
				if piece.is_assigned_to_socket():
					target = piece;
			pass;
		modifierTargetType.ROBOT:
			var robot : Robot = try_get_host_robot();
			if is_instance_valid(robot):
				target = robot;
			pass;
	
	return target;

## Tries to get the [Part] at the engine square this modifier is targeting. Might be null.
func try_get_part_at_offset():
	var invPosition = get_inventory_position();
	var slot = inventoryNode.get_slot_at(invPosition.x, invPosition.y);
	if is_instance_valid(slot):
		if slot is Part:
			print("inventory slot grabbed: ", slot.partName);
			return slot;
	return null;

## tries to get the host [Piece], then returns it or [code]null[/code].
func try_get_host_piece() -> Piece:
	var piece : Piece = null;
	if owner is Part:
		if is_instance_valid(owner.hostPiece):
			piece = owner.hostPiece;
			pass;
	elif owner is Piece:
		piece = owner;
		pass
	return piece;

## Tries to get a host [Robot], then returns it or [code]null[/code].
func try_get_host_robot() -> Robot:
	var piece : Piece = try_get_host_piece();
	var robot : Robot = null;
	if is_instance_valid(piece):
		var potential = piece.get_host_robot();
		robot = potential if is_instance_valid(potential) else null;
	return robot;

##Tries to apply the modifier to the specified property on the part. If the part doesn't have it, then nothing happens.
func try_apply_mod(propertyName : String):
	## Deprecated variable-based modifyng.
	if true == false:
		if is_applicable():
			if propertyName in target:
				return target.mods_apply(propertyName, valueAdd, valueFlatMult, valueTimesMult);
	return false;

func is_applying():
	return currentlyApplying;

##Enables/disables the modifier, then reprompts modifier applicants.
func disable(switch):
	if switch:
		enabled = true;
	else:
		enabled = false;
	if target is Part:
		distribute_modifier();

func kill_if_invalid():
	if ! is_instance_valid(owner) or ! is_instance_valid(inventoryNode):
		free();

## Returns true if this modifier has the given [param tag] in [member tags]
func has_id(tag:String):
	if modTags.has(tag):
		return true;
	return false;
