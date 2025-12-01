@icon ("res://graphics/images/class_icons/abilitySlotManager.png")
extends Control

class_name AbilitySlotManager
## Holds an [Array] of [AbilitySlot]s on the [GameHUD].

signal button_pressed(slot:AbilitySlot)

@export var slot0 : AbilitySlot;
@export var slot1 : AbilitySlot;
@export var slot2 : AbilitySlot;
@export var slot3 : AbilitySlot;
@export var slot4 : AbilitySlot;
@onready var allSlots = [slot0, slot1, slot2, slot3, slot4];
var currentRobot : Robot;

enum modes {
	NONE,
	ASSIGNING,
}
var curMode : modes = modes.NONE;

func _process(delta):
	
	for slot in allSlots:
		slot.manager = self;
		
		slot.set_index(allSlots.find(slot));
	
	if is_instance_valid(currentRobot):
		## Assign abilities based on the contents of the robot's active_abilities dictionary.
		for index in currentRobot.active_abilities.keys():
			var ability = currentRobot.active_abilities[index];
			var slotAtIndex = allSlots[index];
			
			slotAtIndex.assign_ability(ability);
		
		## If there's something in the pipette, activate assignment mode.
		if currentRobot.get_ability_pipette() != null:
			curMode = modes.ASSIGNING;
		else:
			curMode = modes.NONE;
	else:
		curMode = modes.NONE;
	
	for slot in allSlots:
		if curMode == modes.ASSIGNING:
			slot.curMode = AbilitySlot.modes.ASSIGNING;
		else:
			slot.curMode = AbilitySlot.modes.NONE;

func _on_button_pressed(slot):
	if is_instance_valid(currentRobot):
		var ability = currentRobot.get_ability_pipette();
		if is_instance_valid(ability) and ability is AbilityData:
			currentRobot.assign_ability_to_slot(slot.index, ability);
	pass # Replace with function body.
