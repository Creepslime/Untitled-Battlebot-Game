@icon("res://graphics/images/class_icons/stashButton.png")
extends Button

class_name StashButton;

var pieceReferenced : Piece = null;
var partReferenced : Part = null;
var stashHUD : PieceStash;

var iconPart := preload("res://graphics/images/HUD/statIcons/partIconStriped.png");
var iconPiece := preload("res://graphics/images/HUD/statIcons/pieceIconStriped.png");

@export var img_equippedBG : TextureRect;
@export var img_selectedBG : TextureRect;
@export var img_unequippedSelectedBG : TextureRect;
@export var img_moveBG : TextureRect;

signal hover(hovering:bool)

var deathTimer := -1;
var modulationStep := 0;
var pressable = false;
func kill():
	if deathTimer == -1:
		deathTimer = 5;
	pressable = false;
func revive():
	deathTimer = -1;
	pressable = true;

func _process(delta):
	if !is_instance_valid(robot) or !is_instance_valid(get_reference()):
		kill();

	## Modulation rises in 4 frames from birth.
	modulationStep = min(modulationStep + 1, 4)
	
	match deathTimer:
		-1: ## Fully alive, do nothing.
			pass;
		0: ## Death.
			queue_free();
		1: ## Dying.
			modulationStep = min(modulationStep, 1)
			pass;
		2: ## Dying.
			modulationStep = min(modulationStep, 2)
			pass;
		3: ## Start dying.
			modulationStep = min(modulationStep, 3)
			pass;
		4: ## Barely dead. Do nothing.
			pass;
		5: ## Barely dead. Do nothing.
			pass;
	
	if deathTimer >= 0:
		deathTimer -= 1;
	
	## Modulation set.
	var mod = 0.25 * modulationStep if modulationStep > 0 else 1.0;
	modulate.a = mod;
	
	update_bg();

func load_piece_data(inPiece : Piece, hud : PieceStash):
	name = inPiece.pieceName;
	text = inPiece.get_stash_button_name();
	pieceReferenced = inPiece;
	stashHUD = hud;
	icon = iconPiece;
	pressable = true;
	update_bg();


func load_part_data(inPart : Part, hud : PieceStash):
	name = inPart.partName;
	text = inPart.partName;
	partReferenced = inPart;
	stashHUD = hud;
	icon = iconPart;
	pressable = true;
	update_bg();


func _on_pressed():
	if pressable:
		if is_instance_valid(stashHUD):
			if is_instance_valid(pieceReferenced):
				#print("buton pres ", pieceReferenced)
				stashHUD.piece_button_pressed(pieceReferenced, self);
				#select(true);
			if is_instance_valid(partReferenced):
				#print("part buton pres ", partReferenced)
				stashHUD.part_button_pressed(partReferenced, self);
				#select(true);
	update_bg();
	pass 

var robot : Robot;
func get_robot() -> Robot:
	robot = stashHUD.get_current_robot();
	return robot;

var selected := false;
func get_selected() -> bool:
	selected = false;
	if ref_is_piece():
		if is_instance_valid(pieceReferenced) and pieceReferenced.get_selected(): 
			selected = true;
		if get_robot() != null:
			if is_instance_valid(pieceReferenced) and robot.get_current_pipette() == pieceReferenced:
				selected = true;
	elif ref_is_part():
		selected = partReferenced.selected;
	return selected;

var ref;
## gets this button's reference, sets the value to [member ref], then returns it, or [null] if neither. Prioritizes [member partReferenced] over [member pieceReferenced].
func get_reference(forceReturnReference := false):
	if get_robot() == null:
		ref = null;
		return null;
	
	if forceReturnReference:
		if partReferenced != null:
			return partReferenced;
		if pieceReferenced != null:
			return pieceReferenced;
	
	if is_instance_valid(partReferenced):
		ref = partReferenced;
		return partReferenced;
	if is_instance_valid(pieceReferenced):
		ref = pieceReferenced;
		return pieceReferenced;
	ref = null;
	return null;

func ref_is_piece():
	return is_instance_valid(get_reference()) and ref is Piece;
func ref_is_part():
	return is_instance_valid(get_reference()) and ref is Part;

func get_equipped():
	if ref_is_part():
		return is_instance_valid(partReferenced) and partReferenced.is_equipped();
	elif ref_is_piece():
		return is_instance_valid(pieceReferenced) and pieceReferenced.is_equipped();
	return false;

func select(foo := not get_selected()):
	selected = foo;
	if get_reference() != null:
		if !foo:
			if ref_is_piece():
				ref.select(false);
				if get_robot() != null:
					robot.deselect_piece(ref);
			if ref_is_part():
				ref.select(false);
				if get_robot() != null:
					robot.deselect_all_parts();
		else:
			if ref_is_part():
				if get_robot() != null:
					robot.select_part(ref);
				ref.select(true);
	
	update_bg();

enum modes {
	NotSelectedNotEquipped,
	SelectedNotEquipped,
	NotSelectedEquipped,
	SelectedEquipped,
	MoveMode,
}

func update_bg():
	var mode : modes;
	if get_selected():
		if get_equipped():
			mode = modes.SelectedEquipped;
		else:
			mode = modes.SelectedNotEquipped;
		
		if ref_is_part():
			if partReferenced.robot_is_in_move_mode_with_me():
				mode = modes.MoveMode;
	else:
		if get_equipped():
			mode = modes.NotSelectedEquipped;
		else:
			mode = modes.NotSelectedNotEquipped;
	img_selectedBG.visible = mode == modes.SelectedEquipped;
	img_unequippedSelectedBG.visible = mode == modes.SelectedNotEquipped;
	img_equippedBG.visible = mode == modes.NotSelectedEquipped;
	img_moveBG.visible = mode == modes.MoveMode;



func _on_mouse_entered():
	hover.emit(true)
	pass # Replace with function body.


func _on_mouse_exited():
	hover.emit(false)
	pass # Replace with function body.


func _on_tree_exiting():
	hover.emit(false)
	pass # Replace with function body.
