@icon ("res://graphics/images/class_icons/inspector.png")
extends TextureRect

class_name Inspector

@export var stash : PieceStash;
@export var infobox : InfoBox;
var inspectedThing;
var queued_thing;

## All of the modes this inspector window can be in, not including the different modes of the nodes within.
enum inspectorModes {
	OPENING,
	CLOSING,
	PART,
	PIECE,
	ROBOT,
	CLOSED,
	OPEN_QUEUED,
	}
## Used to show and hide the infobox window.
var inspectorOpen := false;
## The current mode. Use [method get_current_mode] to get this instead of grabbing it directly.
var curMode : inspectorModes = inspectorModes.CLOSED;
## Gets the current mode.
func get_current_mode() -> inspectorModes:
	return curMode;
## Run to change to a new mode from [enum inspectorModes]. 
func change_mode(newMode:inspectorModes, fromModes:Array[inspectorModes] = []):
	queuedMode = null;
	queuedModeFilter = [];
	if newMode == get_current_mode(): return;
	#print("Changing modes to ", str(inspectorModes.keys()[newMode]))
	if not ((fromModes.is_empty()) or (get_current_mode() in fromModes)): return; ##if the array is empty, skip this step. If it is not, only change modes if you're in one of the given modes.
	#print("Mode passed the array check.")
	curMode = newMode;
	enter_mode(newMode);
	pass;
var queuedMode = null;
var queuedModeFilter = [];
func change_mode_next_frame(newMode:inspectorModes, fromModes:Array[inspectorModes] = []):
	queuedMode = newMode;
	queuedModeFilter = fromModes;
## Returns true if you're in the given mode ([enum inspectorModes] value) or modes ([code]Array[inspectorModes][/code]).
func in_modes(modes):
	if modes is Array:
		return get_current_mode() in modes;
	if modes is inspectorModes:
		return get_current_mode() == modes;
	return false;

var updateFrame := true;
## Runs when we enter a new mode from [enum inspectorModes]. 
func enter_mode(newMode : inspectorModes):
	#await infobox.ready
	#print("Changed modes to ", str(inspectorModes.keys()[newMode]))
	updateFrame = false;
	match newMode:
		inspectorModes.CLOSED:
			inspectorOpen = false;
			inspectedThing = null;
			queued_thing = null;
			pass;
		inspectorModes.CLOSING:
			inspectorOpen = false;
			infobox.clear_info();
			inspectedThing = null;
			queued_thing = null;
			calc_target_stash_height();
			pass;
		inspectorModes.OPEN_QUEUED:
			#print("Open queued state.")
			if is_instance_valid(queued_thing):
				#prints("Attempted to open inspector in OPEN_QUEUED, here's the queue:", queued_thing);
				populate_from_queued();
				change_mode(inspectorModes.OPENING);
			else:
				#print("Attempted to open inspector in OPEN_QUEUED, but the queue was invalid!")
				close_inspector();
		inspectorModes.OPENING:
			calc_target_stash_height();
			pass;
		inspectorModes.PART:
			set_deferred("queued_thing", null);
			inspectorOpen = true;
			pass;
		inspectorModes.PIECE:
			set_deferred("queued_thing", null);
			inspectorOpen = true;
			pass;
		inspectorModes.ROBOT:
			set_deferred("queued_thing", null);
			inspectorOpen = true;
			pass;
	
	calc_target_stash_height();

var targetStashHeight := 439.0;
var currentStashHeight := 439.0;
var targetInfoboxHeight := 1.0;
const fullWindowHeight := 500;
const gapBetweenStashAndInfobox := 5;
const sorterHeight := 55;
const gapAboveInfobox := 4;
const gapBelowStash := 2;
const startingStashY := 17;
var infoboxHeight := 279;
const stashHeightWhenClosed := 439;

@export var stashSeparator : TextureRect;

func calc_target_stash_height(_infoboxHeight := infobox.get_required_height()):
	#if !in_modes([inspectorModes.OPENING, inspectorModes.PART, inspectorModes.PIECE]): 
	if !is_instance_valid(inspectedThing): 
		_infoboxHeight = 0; 
		targetStashHeight = stashHeightWhenClosed;
		#print("Not in the correct mode to get a new height. Returning ",stashHeightWhenClosed)
		#print("Inspected thing is invalid.")
		return targetStashHeight;
	if ! infobox.data_ready: 
		_infoboxHeight = infoboxHeight;
	#print_rich("[color=red]" + str(_infoboxHeight))
	infoboxHeight = _infoboxHeight;
	var calc = fullWindowHeight;
	calc -= infoboxHeight;
	calc -= gapBetweenStashAndInfobox;
	calc -= sorterHeight;
	calc -= gapAboveInfobox;
	calc -= gapBelowStash;
	
	targetStashHeight = calc;
	return targetStashHeight;
	pass;

func calc_visible_infobox_height():
	var calc = fullWindowHeight;
	calc -= gapBetweenStashAndInfobox;
	calc -= currentStashHeight;
	calc -= sorterHeight;
	calc -= gapAboveInfobox;
	calc -= gapBelowStash;
	
	targetInfoboxHeight = calc;
	return targetInfoboxHeight;

var moveFactor : int = 0;
func _process(delta : float):
	if queuedMode != null:
		change_mode(queuedMode, queuedModeFilter);
	var dif2 = currentStashHeight - targetStashHeight;
	currentStashHeight = move_toward(currentStashHeight, targetStashHeight, moveFactor);
	dif2 = currentStashHeight - targetStashHeight;
	
	var dif = stashHeightWhenClosed - currentStashHeight;
	
	if dif <= 0:
		currentStashHeight = stashHeightWhenClosed;
	
	stash.size.y = currentStashHeight;
	stash.position.y = startingStashY + dif;
	
	match get_current_mode():
		inspectorModes.CLOSED:
			#print("closed mode")
			inspectedThing = null;
			queued_thing = null;
			inspectorOpen = false;
			pass;
		inspectorModes.OPENING:
			#print("opening mode")
			calc_movefactor_for_opening(delta);
			#print(dif2)
			inspectorOpen = infobox.data_ready;
			if dif2 <= 0.0: 
				if ! is_instance_valid(queued_thing):
					change_mode(inspectorModes.CLOSING);
				else:
					if queued_thing is Part:
						change_mode(inspectorModes.PART);
					if queued_thing is Piece:
						change_mode(inspectorModes.PIECE);
					if queued_thing is Robot:
						change_mode(inspectorModes.ROBOT);
			pass;
		inspectorModes.CLOSING:
			inspectorOpen = true;
			moveFactor = roundi(600 * delta);
			if dif2 >= 0: 
				change_mode_next_frame(inspectorModes.CLOSED);
			pass;
		inspectorModes.OPEN_QUEUED:
			inspectorOpen = false;
			moveFactor = 0;
			pass;
		inspectorModes.PART:
			inspectorOpen = true;
			calc_movefactor_for_opening(delta)
			pass;
		inspectorModes.PIECE:
			inspectorOpen = true;
			calc_movefactor_for_opening(delta)
			pass;
		inspectorModes.ROBOT:
			inspectorOpen = true;
			calc_movefactor_for_opening(delta)
			pass;
	
	##Visibility 
	if inspectorOpen:
		calc_visible_infobox_height()
		if targetInfoboxHeight > 0 and infobox.data_ready:
			infobox.size.y = targetInfoboxHeight;
		else:
			inspectorOpen = false;
	
	infobox.visible = inspectorOpen;
	stashSeparator.visible = ! (dif < 4);

## Refreshes the stash height and gives an updated moveFactor depending on if the inspector has its data prepared.
func calc_movefactor_for_opening(delta):
	if infobox.data_ready: 
		calc_target_stash_height();
		moveFactor = roundi(600 * delta);
	else: 
		moveFactor = 0;

## Clears [member queued_thing] after populating the inspector with it.
func populate_from_queued():
	if is_instance_valid(queued_thing):
		populate_inspector(queued_thing);
	else:
		queued_thing = null;
		close_inspector();

## Populates the infobox with Part or Piece details.
func populate_inspector(thing):
	#prints("Inspector is being populated by ",thing)
	if infobox.populate_info(thing):
		inspectedThing = thing;

## Changes modes to closing.
func close_inspector():
	change_mode(inspectorModes.CLOSING, [inspectorModes.OPENING, inspectorModes.PIECE, inspectorModes.PART, inspectorModes.ROBOT, inspectorModes.OPEN_QUEUED]);

## Use this when updating the inspector with the currently selected Piece or Part.[br]
## If we're not inspecting something already, queue the opening of the inspector.[br]
## If we're already inspecting the thing being asked to update, it repopulates the infobox with updated data.
func update_selection(thing):
	#print("Currently inspected: ",inspectedThing)
	if thing == null:
		close_inspector();
	if !is_instance_valid(thing) and queued_thing == null:
		close_inspector();
	else:
		#print("Valid thing to inspect. ", thing)
		if thing == inspectedThing: return;
		if ! (get_current_mode() == inspectorModes.PART or get_current_mode() == inspectorModes.PIECE or get_current_mode() == inspectorModes.ROBOT) and thing == inspectedThing:
			#prints("Attempting opening inspector with thing",thing)
			open_inspector(thing);
			return;
		else:
			open_inspector(thing);
			return;

## Queues a new thing to open the inspector for.
func open_inspector(thing):
	if queued_thing != thing:
		queued_thing = thing;
		change_mode(inspectorModes.OPEN_QUEUED, [inspectorModes.CLOSED, inspectorModes.CLOSING, inspectorModes.PIECE, inspectorModes.PART, inspectorModes.ROBOT]);
	else:
		#prints("Opening inspector failed. ", queued_thing != thing, inspectedThing != thing, inspectedThing, thing)
		pass;
	pass;

## Regenerates all the stash buttons.
func regenerate_stash(bot : Robot, mode : PieceStash.modes = stash.get_current_mode()):
	stash.currentRobot = bot;
	stash.regenerate_list(bot, mode);
