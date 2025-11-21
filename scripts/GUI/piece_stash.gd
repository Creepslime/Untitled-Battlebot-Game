@icon ("res://graphics/images/class_icons/inspector.png")
extends Control

class_name PieceStash

enum modes {
	NONE,
	PIECES,
	PARTS,
	ALL,
}
var currentMode := modes.NONE;
var currentRobot : Robot;
@export var buttonsHolder : HFlowContainer;
@export var stashButtonScene : PackedScene;
@export var scrollContainer : ScrollContainer;

func _ready():
	scrollContainer.get_v_scroll_bar().custom_minimum_size.x = 6;
	scrollContainer.get_v_scroll_bar().update_minimum_size();
	btn_Equipped.icon = null;
	is_robot_being_referenced();
	rotate_equipped_status(); ##Rotates off of NONE.
	rotate_sort(); ##Rotates off of NONE.

func get_current_mode(): return currentMode;

func get_current_robot(): 
	if is_instance_valid(currentRobot):
		disable_sorters(false);
	else:
		disable_sorters(true);
		currentRobot = null;
	return currentRobot;

func regenerate_list(robotToReference : Robot = get_current_robot(), mode : modes = get_current_mode()):
	currentMode = mode;
	var _allButtons = get_all_buttons_regenerate();
	var buttonReferences : Dictionary[Node, StashButton] = {}; ## {ref : StashButton}
	var goodButtons = []; ## Buttons that are allowed to keep existing.
	var badButtons = []; ## Buttons that are referencing something invalid or not in the gathered stash list.
	var newButtons = []; ## Stash items to be turned into buttons.
	## Get all of the references currently used by all of the buttons.
	for button : StashButton in _allButtons:
		if is_instance_valid(button):
			var ref = button.get_reference();
			if ref != null:
				buttonReferences[ref] = button;
	if is_robot_being_referenced():
		var stash = [];
		## Get the stash based on the modes.
		match mode:
			modes.PIECES:
				stash.append_array(robotToReference.get_stash_pieces(get_current_equipped_status()));
			modes.PARTS:
				stash.append_array(robotToReference.get_stash_parts(get_current_equipped_status()));
			modes.ALL:
				stash.append_array(robotToReference.get_stash_all(get_current_equipped_status()));
			#prints("Stash regen PRE", stash)
		
		## Check if the stash item is inside of the buttons currently existing.
		#prints("Stash regen", stash)
		for item in stash:
			#print(item)
			if buttonReferences.keys().has(item):
				## IF the current buttons contain the thing: remove the button and item from the reference dict, then add it to goodButtons.
				var btn = buttonReferences[item];
				buttonReferences.erase(item);
				goodButtons.append(btn);
			else:
				## IF the thing is NOT in the current buttons, then add it to the list of buttons to make new.
				newButtons.append(item);
		
		## Delete all of the buttons still in the buttonReferences table, as they were not removed earlier when checking if their contents were in the new stash.
		for item in buttonReferences.keys():
			var button = buttonReferences[item];
			button.queue_free();
		
		## Spawn buttons that need represented now.
		for item in newButtons:
			spawn_button(item);
	pass;

func spawn_button(thing : Variant) -> StashButton:
	if is_instance_valid(thing):
		if thing is Piece:
			return spawn_piece_button(thing);
		if thing is Part:
			return spawn_part_button(thing);
	return null;

func spawn_piece_button(tiedPiece : Piece):
	var newButton = stashButtonScene.instantiate();
	newButton.load_piece_data(tiedPiece, self);
	buttonsHolder.add_child(newButton);
	return newButton;

func spawn_part_button(tiedPart : Part):
	var newButton = stashButtonScene.instantiate();
	newButton.load_part_data(tiedPart, self);
	buttonsHolder.add_child(newButton);
	return newButton;

var allButtons : Array[StashButton]= [];
func get_all_buttons() -> Array[StashButton]:
	if allButtons.is_empty():
		get_all_buttons_regenerate();
	return allButtons;
func get_all_buttons_regenerate() -> Array[StashButton]:
	allButtons.clear();
	for child in buttonsHolder.get_children():
		if child is StashButton:
			allButtons.append(child);
	return allButtons;

func piece_button_pressed(tiedPiece : Piece, button: StashButton):
	pieceButtonClicked.emit(tiedPiece, button);

func part_button_pressed(tiedPart : Part, button: StashButton):
	partButtonClicked.emit(tiedPart, button);

func _on_sort_by_parts_pressed():
	if is_robot_being_referenced():
		rotate_sort();
	pass # Replace with function body.

func is_robot_being_referenced():
	disable_sorters(not is_instance_valid(get_current_robot()));
	return is_instance_valid(get_current_robot());

@export var btn_sortPieces : Button;

func disable_sorters(_disabled : bool):
	btn_sortPieces.disabled = _disabled;
	btn_Equipped.disabled = _disabled;

enum equippedStatus {
	NONE,
	EQUIPPED,
	NOT_EQUIPPED,
	ALL,
}
var curEquippedStatus := equippedStatus.NONE
func get_current_equipped_status():
	return curEquippedStatus;

@export var btn_Equipped : Button;

func rotate_equipped_status():
	match get_current_equipped_status():
		equippedStatus.NONE:
			curEquippedStatus = equippedStatus.ALL;
			btn_Equipped.icon = null;
			btn_Equipped.text = "Any";
		equippedStatus.ALL:
			curEquippedStatus = equippedStatus.EQUIPPED;
			btn_Equipped.icon = null;
			btn_Equipped.text = "Equipped";
		equippedStatus.EQUIPPED:
			curEquippedStatus = equippedStatus.NOT_EQUIPPED;
			btn_Equipped.icon = null;
			btn_Equipped.text = "Not Equipped";
		equippedStatus.NOT_EQUIPPED:
			curEquippedStatus = equippedStatus.ALL;
			btn_Equipped.icon = null;
			btn_Equipped.text = "Any";
	regenerate_list();

@onready var icon_Piece := preload("res://graphics/images/HUD/statIcons/pieceIconStriped.png");
@onready var icon_Part := preload("res://graphics/images/HUD/statIcons/partIconStriped.png");
@onready var icon_PieceAndPart := preload("res://graphics/images/HUD/statIcons/piecePartIconStriped.png");

func rotate_sort():
	match get_current_mode():
		modes.NONE:
			currentMode = modes.ALL;
			btn_sortPieces.icon = icon_PieceAndPart;
			btn_sortPieces.text = "All";
		modes.ALL:
			currentMode = modes.PIECES;
			btn_sortPieces.icon = icon_Piece;
			btn_sortPieces.text = "Pieces";
		modes.PIECES:
			currentMode = modes.PARTS;
			btn_sortPieces.icon = icon_Part;
			btn_sortPieces.text = "Parts";
		modes.PARTS:
			currentMode = modes.ALL;
			btn_sortPieces.icon = icon_PieceAndPart;
			btn_sortPieces.text = "All";
	regenerate_list();

##Shows only equipped buttons.
func _on_sort_by_equipped_pressed():
	if is_robot_being_referenced():
		rotate_equipped_status();
	pass # Replace with function body.


signal pieceButtonClicked(tiedPiece : Piece, button : StashButton);
signal partButtonClicked(tiedPart : Part, button : StashButton);

func _on_part_button_clicked(tiedPart:Part, button : StashButton):
	deselect_all_buttons(button);
	if is_instance_valid(currentRobot):
		currentRobot.prepare_pipette(tiedPart);
	pass # Replace with function body.

func _on_piece_button_clicked(tiedPiece:Piece, button : StashButton):
	deselect_all_buttons(button);
	if is_instance_valid(currentRobot):
		var selected = button.get_selected();
		if ! tiedPiece.has_robot_host():
			if currentRobot.get_current_pipette() != tiedPiece:
				currentRobot.prepare_pipette(tiedPiece);
			else:
				currentRobot.unreference_pipette();
		else:
			if !selected:
				currentRobot.select_piece(tiedPiece);
			else:
				currentRobot.deselect_all_pieces();
				button.get_selected();
	pass # Replace with function body.

func deselect_all_buttons(ignoredButton : StashButton):
	for button : StashButton in buttonsHolder.get_children():
		if button != ignoredButton:
			button.select(false);
