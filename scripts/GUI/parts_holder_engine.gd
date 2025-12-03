@icon ("res://graphics/images/class_icons/engine.png")

extends Control

class_name PartsHolder_Engine
## The engine block for all [Piece]s, which visually holds all of its [Part]s.[br]
## Opened up when the player selects a [Part] or [Piece], either through the [PieceStash] or by clicking while in a state of building.

## Enitted by this via child [PartHolderButton] nodes when they are pressed; Calls [method _on_engine_button_pressed].
signal buttonPressed(x:int,y:int);

## The gfx for the front door.
@export var door : TextureRect;
var doorOpeningSpeed := 13.0 ## How fast the door opens; Multiplied by delta time.
var doorClosingSpeed := 13.0 / 1.5 ## How fast the door closes; Multiplied by delta time.

enum doorStates {
	OPEN, ## Door's fully open.
	CLOSED, ## Door's fully closed.
	OPENING, ## Door's opening. Changes to [enum doorStates.OPEN] when fully open.
	CLOSING, ## Door's closing. Changes to [enum doorStates.CLOSED] when fully closed.
}
var curState := doorStates.CLOSED; ## The state the door is currently in, from [enum doorStates].

var referenceQueued : Piece; ## The [Piece] reference that will be switched into when this closes. See [method set_reference_from_queue].
var referenceCurrent : Piece; ## The referenced [Piece] currently being looked at. 
var referenceVisual : Piece; ## The [Piece] reference being displayed, even if [member referenceCurrent] is [code]null[/code].
var patternQueued : Array[Vector2i]; ## The pattern that will be inputted after the door closes. See [method set_pattern_from_queue].
var patternIsQueued := false; ## Whether or not a pattern is queued. See [member patternQueued].
var currentPattern : Array[Vector2i]; ## The currently displayed engine block pattern.

## Changes [member curState] to [param newState] as long as it's a different state than current, and we're currently in one of the [param filterStates]. [member curState] gets autofilled into [param filterStates] if it is left empty.[br]Runs the old state thru [method leave_state], then [method enter_state] on the new state.
func change_state(newState : doorStates, filterStates : Array[doorStates] = []):
	if filterStates.is_empty():
		filterStates.append(curState)
	if newState != curState and curState in filterStates:
		leave_state(curState);
		enter_state(newState);

## Returns true if we're in one of the given [param filterStates] from [enum doorStates]. 
func check_in_state(filterStates : Array[doorStates] = []):
	return curState in filterStates;

## Run on the new state after a state change, after [method leave_state]. Actually sets the new state. See [method change_state].
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

## Run on the old state after a state change, before [method enter_state]. See [method change_state].
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

## Runs a [code]match[/code] statement over [member curState] each frame.
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

## What it says on the tin. Updates the graphics of each [PartHolderButton] from [method get_buttons].
func update_button_gfx():
	for button in get_buttons():
		button.update_gfx();

## Changes states to [enum doorStates.OPENING] if we're currently CLOSED or CLOSING.
func open():
	change_state(doorStates.OPENING, [doorStates.CLOSED, doorStates.CLOSING]);

## Changes states to [enum doorStates.CLOSING] if we're currently OPEN or OPENING.
func close():
	change_state(doorStates.CLOSING, [doorStates.OPEN, doorStates.OPENING]);

## Disables/enables each [PartHolderButton] from [method get_buttons].
func disable(disabled:bool):
	for button in get_buttons():
			button.disable(disabled);

## The border gfx.
@export var bgTiles : TileMapLayer;

## Gets the engine block pattern from [param inPiece] via [method get_pattern_from_piece], then runs it thru [method set_pattern].
func set_pattern_from_piece(inPiece : Piece):
	set_pattern(get_pattern_from_piece(inPiece));

## Gets the engine block pattern from [param inPiece], then returns it.
func get_pattern_from_piece(inPiece : Piece) -> Array[Vector2i]:
	var tilesArray : Array[Vector2i] = [];
	
	var piece_engine = inPiece.engineSlots;
	
	for slot in piece_engine.keys():
		if slot is Vector2i:
			tilesArray.append(slot);
	
	return tilesArray;

## Sets the displayed pattern to the new one given in [param coordsArray]. Updates all the gfx and availability for all the [PartHolderButton]s via [method update_all_availability_to_reflect_pattern].
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

## Sets a given tile as availabole or unavailable.
func set_availability_of_tile(availabilityVal: bool, coords : Vector2i):
	for button in get_buttons():
		if Vector2i(button.coordX, button.coordY) == coords:
			button.set_availability(availabilityVal);

## Returns a [Vector2i] constructed from the given [PartHolderButton]'s [member PartHolderButton.coordX] and [member PartHolderButton.coordY] as X and Y, respectively.
func get_Vector2i_coords_of_button(button : PartHolderButton) -> Vector2i:
	return Vector2i(button.coordX, button.coordY);

## Sets the availability of each [PartHolderButton] from [method get_buttons], based on the given pattern.
func update_all_availability_to_reflect_pattern(coordsArray : Array[Vector2i]):
	for button in get_buttons():
		var vector = get_Vector2i_coords_of_button(button);
		#print(button, vector, vector in coordsArray)
		button.set_availability(vector in coordsArray);

## Gets all [PartHolderButton] children in an array and returns it.
func get_buttons() -> Array[PartHolderButton]:
	var buttons : Array[PartHolderButton] = [];
	for child in get_children():
		if child is PartHolderButton:
			buttons.append(child);
	return buttons;

## Given that [param piece] does not equal [member referenceCurrent], then it is queued up into [member referenceQueued] and [method close] is called.
func open_with_new_piece(piece : Piece):
	if referenceCurrent != piece:
		referenceQueued = piece;
		close();

## Given that [param inPattern] is not equal to [currentPattern], queues it into [member patternQueued] then sets [member patternIsQueued] to [code]true[/code].
func queue_pattern(inPattern : Array[Vector2i]):
	if inPattern != currentPattern:
		patternQueued = inPattern;
		patternIsQueued = true;

## Starts the $PatternChange [Timer] node. On timeout, this calls [method _on_pattern_change_timeout].
func open_slow():
	$PatternChange.start();

## Run after the post-door-close timer runs out; calls [method open].
func _on_pattern_change_timeout():
	open();
	pass # Replace with function body.

## Calls [method close], [method queue_clear_pattern], then [method clear_current_reference] all in sequence.
func close_and_clear():
	close();
	queue_clear_pattern();
	clear_current_reference();
	pass;

## An empty pattern to copy.
const emptyPattern : Array[Vector2i] = [];
## Queues [member emptyPattern] into [method queue_pattern].
func queue_clear_pattern():
	queue_pattern(emptyPattern);

## If [member patternIsQueued] is [code]true[/code], then [member patternQueued] gets run through [set_pattern] and [member patternIsQueued] gets set to false.
func set_pattern_from_queue():
	if patternIsQueued:
		set_pattern(patternQueued);
		patternIsQueued = false;

## Changes over queued stuff into being the current reference. Sets [member referenceVisual] and [member referenceCurrent] equal to [member referenceQueued].[br]Also calls [method Piece.engine_update_part_visibility] on [member referenceCurrent] before and after the switch.
func set_reference_from_queue():
	referenceCurrent = referenceQueued;
	if is_instance_valid(referenceVisual):
		referenceVisual.engine_update_part_visibility(false);
	referenceVisual = referenceQueued;
	referenceCurrent.engine_update_part_visibility(true);
	referenceQueued = null;

## Sets [member referenceCurrent] to [code]null[/code].
func clear_current_reference():
	referenceCurrent = null;

## Called when you click one of the child [PartHolderButton] nodes with a [Part] in your [member Robot.partMovementPipette].
func _on_engine_button_pressed(x, y):
	if is_instance_valid(referenceCurrent):
		if is_instance_valid(referenceCurrent.get_host_robot()):
			var robot = referenceCurrent.get_host_robot();
			if is_instance_valid(robot.partMovementPipette):
				var part = robot.partMovementPipette;
				robot.part_move_mode_enable(part, false);
				## After we've ensured all the bullshit is correct... disable move mode on the robot, and add the Part to the Piece.
				referenceCurrent.engine_add_or_import_part(part, Vector2i(x, y), true);
				part.show();
	pass # Replace with function body.
