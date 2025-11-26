@icon ("res://graphics/images/class_icons/engine.png")

extends Control

class_name PartsHolder_Engine

signal buttonPressed(x:int,y:int);

@export var door : TextureRect;
var doorOpeningSpeed := 13.0
var doorClosingSpeed := 13.0 / 1.5

enum doorStates {
	OPEN,
	CLOSED,
	OPENING,
	CLOSING,
}
var curState := doorStates.CLOSED;

var referenceQueued : Piece; ## The reference that will be switched into when this closes.
var referenceCurrent : Piece; ## The reference currently being looked at. 
var referenceVisual : Piece; ## The reference being displayed, even if referenceCurrent is null.
var patternQueued : Array[Vector2i];
var patternIsQueued := false;
var currentPattern : Array[Vector2i];

func change_state(newState : doorStates, filterStates : Array[doorStates] = []):
	if filterStates.is_empty():
		filterStates.append(curState)
	if newState != curState and curState in filterStates:
		leave_state(curState);
		enter_state(newState);

func check_in_state(filterStates : Array[doorStates] = []):
	return curState in filterStates;

func enter_state(newState : doorStates):
	curState = newState;
	match newState:
		doorStates.OPEN:
			door.position.x = 0.0;
			door.position.y = -271.0;
			disable(false);
			pass;
		doorStates.OPENING:
			if currentPattern == []:
				change_state(doorStates.CLOSING);
			else:
				SND.play_sound_nondirectional("Shop.Door.Open", 0.85, 5.5);
			pass;
		doorStates.CLOSING:
			pass;
		doorStates.CLOSED:
			door.position.x = 0.0;
			door.position.y = 0.0;
			SND.play_sound_nondirectional("Shop.Door.Thump", 0.85, 2);
			pass;

func leave_state(oldState : doorStates):
	match oldState:
		doorStates.OPEN:
			pass;
		doorStates.OPENING:
			pass;
		doorStates.CLOSING:
			pass;
		doorStates.CLOSED:
			pass;

func _process(delta):
	match curState:
		doorStates.OPEN:
			set_pattern_from_queue();
			update_button_gfx();
			pass;
		doorStates.OPENING:
			set_pattern_from_queue();
			
			disable(true);
			door.position.y = lerp (door.position.y, -280.0, doorOpeningSpeed * delta);
			door.position.x = randi_range(-1, 1);
			if door.position.y < -272.0:
				change_state(doorStates.OPEN);
			pass;
		doorStates.CLOSING:
			disable(true);
			door.position.y = lerp (door.position.y, 10.0, doorClosingSpeed * delta);
			door.position.x = randi_range(-1, 1);
			if door.position.y > 0.0:
				change_state(doorStates.CLOSED);
			pass;
		doorStates.CLOSED:
			set_pattern_from_queue();
			disable(true);
			#change_state(doorStates.OPENING);
			if referenceQueued != null and is_instance_valid(referenceQueued):
				set_pattern_from_piece(referenceQueued);
				set_reference_from_queue();
				open_slow();
			pass;

func update_button_gfx():
	for button in get_buttons():
		button.update_gfx();

func open():
	change_state(doorStates.OPENING, [doorStates.CLOSED, doorStates.CLOSING]);

func close():
	change_state(doorStates.CLOSING, [doorStates.OPEN, doorStates.OPENING]);

func disable(disabled:bool):
	for button in get_buttons():
			button.disable(disabled);

@export var bgTiles : TileMapLayer;

func set_pattern_from_piece(inPiece : Piece):
	set_pattern(get_pattern_from_piece(inPiece));

func get_pattern_from_piece(inPiece : Piece) -> Array[Vector2i]:
	var tilesArray : Array[Vector2i] = [];
	
	var piece_engine = inPiece.engineSlots;
	
	for slot in piece_engine.keys():
		if slot is Vector2i:
			tilesArray.append(slot);
	
	return tilesArray;

func set_pattern(coordsArray : Array[Vector2i]):
	if currentPattern == coordsArray: return;
	
	currentPattern = coordsArray;
	
	#print("Setting Pattern at ",Time.get_datetime_dict_from_system(), ": ",coordsArray)
	bgTiles.clear();
	var pat = bgTiles.tile_set.get_pattern(0);
	
	##Set up all the plug faces.
	for index in coordsArray:
		bgTiles.set_pattern(index * 2, pat);
	
	##Make the tiles fancy.
	var used = bgTiles.get_used_cells();
	bgTiles.set_cells_terrain_connect(used, 0, 0);
	
	##Set up all the plug faces a second time to cover up the weirdness.
	for index in coordsArray:
		bgTiles.set_pattern(index * 2, pat);
	
	update_all_availability_to_reflect_pattern(coordsArray);

func set_availability_of_tile(availabilityVal: bool, coords : Vector2i):
	for button in get_buttons():
		if Vector2i(button.coordX, button.coordY) == coords:
			button.set_availability(availabilityVal);

func get_Vector2i_coords_of_button(button : PartHolderButton) -> Vector2i:
	return Vector2i(button.coordX, button.coordY);

func update_all_availability_to_reflect_pattern(coordsArray : Array[Vector2i]):
	for button in get_buttons():
		var vector = get_Vector2i_coords_of_button(button);
		#print(button, vector, vector in coordsArray)
		button.set_availability(vector in coordsArray);

func get_buttons() -> Array[PartHolderButton]:
	var buttons : Array[PartHolderButton] = [];
	for child in get_children():
		if child is PartHolderButton:
			buttons.append(child);
	return buttons;

func open_with_new_piece(piece : Piece):
	if referenceCurrent != piece:
		referenceQueued = piece;
		close();

func queue_pattern(inPattern : Array[Vector2i]):
	if inPattern != currentPattern:
		patternQueued = inPattern;
		patternIsQueued = true;

func open_slow():
	$PatternChange.start();

func _on_pattern_change_timeout():
	open();
	pass # Replace with function body.

func close_and_clear():
	close();
	queue_clear_pattern();
	clear_current_reference();
	pass;


const emptyPattern : Array[Vector2i] = [];
func queue_clear_pattern():
	queue_pattern(emptyPattern);

func set_pattern_from_queue():
	if patternIsQueued:
		set_pattern(patternQueued);
		patternIsQueued = false;

func set_reference_from_queue():
	referenceCurrent = referenceQueued;
	if is_instance_valid(referenceVisual):
		referenceVisual.engine_update_part_visibility(false);
	referenceVisual = referenceQueued;
	referenceCurrent.engine_update_part_visibility(true);
	referenceQueued = null;

func clear_current_reference():
	referenceCurrent = null;


func _on_engine_button_pressed(x, y):
	if is_instance_valid(referenceCurrent):
		if is_instance_valid(referenceCurrent.get_host_robot()):
			var robot = referenceCurrent.get_host_robot();
			if is_instance_valid(robot.partMovementPipette):
				var part = robot.partMovementPipette;
				robot.part_move_mode_enable(part, false);
				## After we've ensured all the bullshit is correct... disable move mode on the robot, and add the Part to the Piece.
				referenceCurrent.engine_add_part(part, Vector2i(x, y), true);
				part.show();
	pass # Replace with function body.
