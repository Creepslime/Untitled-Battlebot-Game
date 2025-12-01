@icon ("res://graphics/images/class_icons/stash.png")
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
@export var stashButtonScene : PackedScene;

@export var buttonsHolder : HFlowContainer;
@export var scrollContainer : ScrollContainer;

@export var btn_sortPieces : Button;
@export var btn_Equipped : Button;

@onready var icon_Piece := preload("res://graphics/images/HUD/statIcons/pieceIconStriped.png");
@onready var icon_Part := preload("res://graphics/images/HUD/statIcons/partIconStriped.png");
@onready var icon_PieceAndPart := preload("res://graphics/images/HUD/statIcons/piecePartIconStriped.png");

@onready var icon_Robot := preload("res://graphics/images/HUD/statIcons/robotIconStriped.png");

func _ready():
	scrollContainer.get_v_scroll_bar().custom_minimum_size.x = 6;
	scrollContainer.get_v_scroll_bar().update_minimum_size();
	btn_Equipped.icon = null;
	is_robot_being_referenced();
	rotate_equipped_status(); ##Rotates off of NONE.
	rotate_sort(); ##Rotates off of NONE.

var refreshCounter := 0;
var refreshRate := 4;
func _process(delta):
	if instantRefreshMode:
		refreshCounter -= 1;
	else:
		refreshCounter = 0;
	
	if refreshCounter < 0:
		refreshCounter = 15;
		regenerate_list();

func get_current_mode(): return currentMode;

func get_current_robot(): 
	if is_instance_valid(currentRobot):
		disable_sorters(false);
	else:
		disable_sorters(true);
		currentRobot = null;
	return currentRobot;

var buttonID = -1;
func get_new_button_id():
	buttonID += 1;
	return buttonID;

func regenerate_list(robotToReference : Robot = get_current_robot(), mode : modes = get_current_mode()):
	buttonID = -1;
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
		stash = Utils.array_duplicates_removed(stash);
		stash.append(robotToReference);
		## Check if the stash item is inside of the buttons currently existing.
		#prints("Stash regen", stash)
		for item in stash:
			if is_instance_valid(item):
				if buttonReferences.keys().has(item):
					## IF the current buttons contain the thing: remove the button and item from the reference dict, then add it to goodButtons.
					var button = buttonReferences[item];
					buttonReferences.erase(item);
					goodButtons.append(button);
					
					## Revive it if the reference turns out to be valid.
					if button.dying:
						button.deemedValid = true;
					else:
						button.deemedValid = null;
				else:
					## IF the thing is NOT in the current buttons, then add it to the list of buttons to make new.
					newButtons.append(item);
		
		## Delete all of the buttons still in the buttonReferences table, as they were not removed earlier when checking if their contents were in the new stash.
		for item in buttonReferences.keys():
			var button = buttonReferences[item];
			button.deemedValid = false;
		
		## Spawn buttons that need represented now.
		for item in newButtons:
			var button = spawn_button(item);
			if button != null:
				button.deemedValid = true;
			refreshCounter = -1;
		
		## Sort the buttons.
		sort_buttons();
	pass;

func spawn_button(thing : Variant) -> StashButton:
	if is_instance_valid(thing):
		if thing is Piece:
			return spawn_piece_button(thing);
		if thing is Part:
			return spawn_part_button(thing);
		if thing is Robot:
			return spawn_robot_button(thing);
	return null;

func spawn_piece_button(tiedPiece : Piece):
	var newButton : StashButton = stashButtonScene.instantiate();
	newButton.load_piece_data(tiedPiece, self);
	buttonsHolder.add_child(newButton);
	if ! newButton.is_connected("hover", hover_button):
		newButton.connect("hover", hover_button);
	return newButton;

func spawn_part_button(tiedPart : Part):
	var newButton : StashButton  = stashButtonScene.instantiate();
	newButton.load_part_data(tiedPart, self);
	buttonsHolder.add_child(newButton);
	if ! newButton.is_connected("hover", hover_button):
		newButton.connect("hover", hover_button);
	newButton.revive()
	return newButton;

func spawn_robot_button(tiedRobot : Robot):
	var newButton : StashButton  = stashButtonScene.instantiate();
	newButton.load_robot_data(tiedRobot, self);
	buttonsHolder.add_child(newButton);
	if ! newButton.is_connected("hover", hover_button):
		newButton.connect("hover", hover_button);
	return newButton;

func button_sort_algo(buttonA : StashButton, buttonB: StashButton):
	var refA = buttonA.get_reference(true);
	var refTypeA = buttonA.lastValidRefType;
	if refTypeA == null:
		return true;
	var refB = buttonB.get_reference(true);
	var refTypeB = buttonB.lastValidRefType;
	if refTypeB == null:
		return false;
	
	if buttonA.get_equipped() and not buttonB.get_equipped():
		return true;
	elif buttonB.get_equipped() and not buttonA.get_equipped():
		return false;
	
	var bothValid = buttonA.validRef and buttonB.validRef;
	if refTypeA == Part: ## At the top; Always returns false
		if refTypeB == Part:
			return refA.partName + str(refA.statHolderID) > refB.partName + str(refB.statHolderID)
		return false;
	if refTypeA == Piece: ## Moves itself below the Parts.
		if refTypeB == Part:
			return true;
		if refTypeB == Piece:
			return refA.pieceName + str(refA.statHolderID) > refB.pieceName + str(refB.statHolderID)
		return false;
	if refTypeA == Robot:
		return true;
	
	return true;

func sort_buttons():
	#allButtons.sort_custom(button_sort_algo);
	buttonID = -1;
	for button in allButtons:
		var buttonIndex = allButtons.find(button);
		buttonsHolder.move_child.call_deferred(button, buttonIndex)
		if button.deemedValid != null:
			button.kill_or_revive(get_new_button_id());

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

func robot_button_pressed(tiedRobot : Robot, button: StashButton):
	robotButtonClicked.emit(tiedRobot, button);

func _on_sort_by_parts_pressed():
	if is_robot_being_referenced():
		rotate_sort();
	pass # Replace with function body.

func is_robot_being_referenced():
	disable_sorters(not is_instance_valid(get_current_robot()));
	return is_instance_valid(get_current_robot());


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


func rotate_equipped_status():
	match get_current_equipped_status():
		equippedStatus.NONE:
			curEquippedStatus = equippedStatus.ALL;
			btn_Equipped.icon = null;
			btn_Equipped.text = "Equipped: Any";
		equippedStatus.ALL:
			curEquippedStatus = equippedStatus.EQUIPPED;
			btn_Equipped.icon = null;
			btn_Equipped.text = "Equipped: Yes";
		equippedStatus.EQUIPPED:
			curEquippedStatus = equippedStatus.NOT_EQUIPPED;
			btn_Equipped.icon = null;
			btn_Equipped.text = "Equipped: No ";
		equippedStatus.NOT_EQUIPPED:
			curEquippedStatus = equippedStatus.ALL;
			btn_Equipped.icon = null;
			btn_Equipped.text = "Equipped: Any";
	regenerate_list();

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
signal robotButtonClicked(tiedBot : Robot, button : StashButton);

func _on_part_button_clicked(tiedPart:Part, button : StashButton):
	deselect_all_buttons(button);
	if is_instance_valid(currentRobot):
		if tiedPart.selected:
			currentRobot.call_deferred("select_part",tiedPart, false);
		else:
			currentRobot.call_deferred("select_part",tiedPart, true);
		#currentRobot.prepare_pipette(tiedPart);
		button.call_deferred("get_selected");
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

func _on_robot_button_clicked(tiedRobot:Robot, button : StashButton):
	deselect_all_buttons(button);
	if is_instance_valid(tiedRobot):
		var selected = button.get_selected();
		tiedRobot.select(!selected)
		pass;
	pass # Replace with function body.

func deselect_all_buttons(ignoredButton : StashButton):
	var ignoredButtonRef = ignoredButton.ref;
	for button : StashButton in buttonsHolder.get_children():
		var buttonRef = button.ref;
		if button != ignoredButton:
			if (ignoredButtonRef is Piece and buttonRef is Piece) or (ignoredButtonRef is Part and buttonRef is Part):
				button.select(false);

var instantRefreshMode := true;
func hover_button(hovering:bool):
	instantRefreshMode = !hovering;
	if ! hovering:
		regenerate_list();
