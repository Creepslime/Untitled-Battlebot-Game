@icon("res://graphics/images/class_icons/stashButton.png")
extends Button

class_name StashButton;

var pieceReferenced : Piece = null;
var partReferenced : Part = null;
var robotReferenced : Robot = null;
var stashHUD : PieceStash;

var iconPart := preload("res://graphics/images/HUD/statIcons/partIconStriped.png");
var iconPiece := preload("res://graphics/images/HUD/statIcons/pieceIconStriped.png");
var iconPieceBody := preload("res://graphics/images/HUD/statIcons/pieceBodyIconStriped.png");
var iconRobot := preload("res://graphics/images/HUD/statIcons/robotIconStriped.png");

@export var img_equippedBG : TextureRect;
@export var img_selectedBG : TextureRect;
@export var img_unequippedSelectedBG : TextureRect;
@export var img_moveBG : TextureRect;

signal hover(hovering:bool)

var givenID := 0;

var deathTimer := -1;
var modulationStep := 0;
var modulationStepWait := -1;
var pressable = false;
var dying = false;
func _ready():
	modulate.a = 0;
var deemedValid = false;
func kill_or_revive(id):
	givenID = id;
	if deemedValid == true:
		revive(givenID);
	elif deemedValid == false:
		kill(givenID);
func kill(timeOffset := 0):
	var success = false;
	if !dying:
		prints(ref," BUTTON KILL")
		if deathTimer == -1:
			deathTimer = 4 + timeOffset;
			success = true;
	dying = true;
	modulationStepWait = -1;
	pressable = false;

func revive(timeOffset := 0):
	if modulationStepWait == -1:
		prints(ref," BUTTON REVIVE")
		modulationStepWait = timeOffset;
	dying = false;
	deathTimer = -1;
	pressable = true;

func _process(delta):
	if pressable and (!is_instance_valid(robot) or get_reference() == null):
		kill();
	
	## Modulation rises in 4 frames from birth.
	if modulationStepWait <= 0:
		modulationStep = max(0, min(modulationStep + 1, 4))
	
	if modulationStepWait > 0:
		modulationStepWait -= 1;
	
	if deathTimer < 4:
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
		#4: ## Barely dead. Do nothing.
			#pass;
		#5: ## Barely dead. Do nothing.
			#pass;
	
	if deathTimer >= 0:
		#print("DEATH TIMER: ", deathTimer)
		deathTimer -= 1;
	
	## Modulation set.
	var mod = 0.25 * modulationStep if modulationStep > 0 else 0.0;
	modulate.a = mod;
	
	update_bg();
	
	disabled = ! (modulationStep > 0);

func load_piece_data(inPiece : Piece, hud : PieceStash):
	name = inPiece.pieceName;
	text = inPiece.get_stash_button_name();
	pieceReferenced = inPiece;
	stashHUD = hud;
	icon = iconPieceBody if inPiece.isBody else iconPiece;
	pressable = true;
	validRef = true;
	update_bg();

func load_part_data(inPart : Part, hud : PieceStash):
	name = inPart.partName;
	text = inPart.partName;
	partReferenced = inPart;
	stashHUD = hud;
	icon = iconPart;
	pressable = true;
	validRef = true;
	update_bg();


func load_robot_data(inBot : Robot, hud : PieceStash):
	name = inBot.robotName;
	text = "Robot";
	robotReferenced = inBot;
	stashHUD = hud;
	icon = iconRobot;
	pressable = true;
	validRef = true;
	update_bg();


func _on_pressed():
	if pressable:
		if is_instance_valid(stashHUD):
			if ref_is_piece():
				#print("buton pres ", pieceReferenced)
				stashHUD.piece_button_pressed(pieceReferenced, self);
				#select(true);
			if ref_is_part():
				#print("part buton pres ", partReferenced)
				stashHUD.part_button_pressed(partReferenced, self);
				#select(true);
			if ref_is_robot():
				#print("part buton pres ", partReferenced)
				stashHUD.robot_button_pressed(robotReferenced, self);
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
	elif ref_is_robot():
		selected = robotReferenced.selected;
		pass;
	return selected;

var ref;
var validRef := false;
var lastValidRefType = null;
## gets this button's reference, sets the value to [member ref], then returns it, or [null] if neither. Prioritizes [member partReferenced] over [member pieceReferenced].
func get_reference(forceReturnReference := false):
	if get_robot() == null:
		ref = null;
		
		validRef = false;
		return null;
	
	if forceReturnReference:
		if partReferenced != null:
			lastValidRefType = Part;
			ref = partReferenced;
			return partReferenced;
		if pieceReferenced != null:
			lastValidRefType = Piece;
			ref = pieceReferenced;
			return pieceReferenced;
		if robotReferenced != null:
			lastValidRefType = Robot;
			ref = robotReferenced;
			return robotReferenced;
		validRef = false;
		return null;
	
	if partReferenced != null and is_instance_valid(partReferenced):
		ref = partReferenced;
		lastValidRefType = Part;
		return partReferenced;
	else:
		partReferenced = null;
	if pieceReferenced != null and is_instance_valid(pieceReferenced):
		ref = pieceReferenced;
		lastValidRefType = Piece;
		return pieceReferenced;
	else:
		pieceReferenced = null;
	if robotReferenced != null and is_instance_valid(robotReferenced):
		ref = robotReferenced;
		lastValidRefType = Robot;
		return robotReferenced;
	else:
		robotReferenced = null;
	
	ref = null;
	validRef = false;
	return null;

func ref_is_piece():
	return is_instance_valid(get_reference()) and ref is Piece;
func ref_is_part():
	return is_instance_valid(get_reference()) and ref is Part;
func ref_is_robot():
	return is_instance_valid(get_reference()) and ref is Robot;

func get_equipped():
	if ref_is_robot():
		return true;
	elif ref_is_part():
		return partReferenced.is_equipped();
	elif ref_is_piece():
		return pieceReferenced.is_equipped();
	return false;

func select(foo := not get_selected()):
	selected = foo;
	if get_reference() != null:
		if !foo:
			if ref_is_piece():
				pieceReferenced.select(false);
				if get_robot() != null:
					robot.deselect_piece(pieceReferenced);
			elif ref_is_part():
				partReferenced.select(false);
				if get_robot() != null:
					robot.deselect_part(partReferenced);
			elif ref_is_robot():
				robotReferenced.select(false);
		else:
			if ref_is_part():
				if get_robot() != null:
					robot.select_part(partReferenced);
				ref.select(true);
			elif ref_is_robot():
				robotReferenced.select(true);
	
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
