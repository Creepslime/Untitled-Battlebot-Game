@icon ("res://graphics/images/class_icons/freezable_green.png")
extends Control

# This control can be frozen and paused.
class_name FreezableControl

var is_ready := false;
func _ready():
	set_physics_process(true);
	set_deferred("is_ready", true);

func _process(delta):
	if not is_paused():
		process_timers(delta);

##Any and all timers go here.
func process_timers(delta):
	pass;

func _physics_process(delta):
	phys_process_pre(delta);
	if not is_paused():
		phys_process_timers(delta);

##Physics process stuff run before anything else.
func phys_process_pre(delta):
	if freezeQueued: freeze(true);

##Any and all timers [u]related to physics[/u] go here.
func phys_process_timers(delta):
	pass;

var frozen := true;
var frozenBeforePaused = false;
var paused := false;
func pause(foo: bool, force := false):
	#print("Pause attempt for ",name,", foo:", str(foo));
	if not force: if paused == foo: return;
	#print("Pause attempt for ",name," successful.")
	if foo: ##If pausing:
		## Mark down whether the bot was frozen before pausing.
		if frozenBeforePaused == null:
			frozenBeforePaused = frozen;
		freeze(true, true);
	else: ##If unpausing:
		## Return frozen status to what it was before.
		if frozenBeforePaused != null:
			freeze(frozenBeforePaused, true);
			frozenBeforePaused = null;
	paused = foo;
##Checks for game state pause, attempts to re-pause or re-unpause, then returns the result.
func is_paused():
	var isPaused = GameState.is_paused();
	if paused != isPaused:
		pause(isPaused, true);
	return paused;

func freeze(doFreeze := (not is_frozen()), force := false):
	#print("Freeze attempt for ",name,", doFreeze:", str(doFreeze), " force:", str(force), " frozen already:", str(frozen));
	freezeQueued = false; ##Cancel the freeze queue.
	if not force: if frozen == doFreeze: return;
	var preFreezevalue = frozen;
	frozen = doFreeze;
	pass;

## Convenience function to specifically unfreeze.
func unfreeze(force := false):
	freeze(false, force);
##Returns true if the game is paused or if the bot is frozen.
func is_frozen() -> bool: return frozen or is_paused();
var freezeQueued := false;
##This function sets a flag to freeze the robot during the next frame.
func queue_freeze_next_frame():
	freezeQueued = true;
