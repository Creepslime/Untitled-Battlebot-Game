@icon ("res://graphics/images/class_icons/freezable.png")
extends MakesNoise

##This entity can be frozen and paused.
class_name FreezableEntity

@export var body : RigidBody3D;


var is_ready := false;
func _ready():
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
	paused = foo;
	
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
##Checks for game state pause, attempts to re-pause or re-unpause, then returns the result.
func is_paused():
	var isPaused = GameState.is_paused();
	if paused != isPaused:
		pause(isPaused, true);
	return paused;

var linearVelocityBeforeFreeze = null;
## Freezes this entity. Pauses the rigidbody and saves its velocity results.
func freeze(doFreeze := (not is_frozen()), force := false):
	#print("Freeze attempt for ",name,", doFreeze:", str(doFreeze), " force:", str(force), " frozen already:", str(frozen));
	freezeQueued = false; ##Cancel the freeze queue.
	if not force: if frozen == doFreeze: return;
	var preFreezevalue = frozen;
	frozen = doFreeze;
	var wasFrozenSame = frozen == preFreezevalue;
	#print("Freeze attempt for ",name," successful.")
	
	##If there's a valid body, do stuff to it.
	if is_instance_valid(body):
		##If freezing, save previous linear velocity.
		if frozen:
			#if not preFreezevalue: ##Only If becoming frozen this frame, save the velocity.
			if linearVelocityBeforeFreeze == null:
				linearVelocityBeforeFreeze = body.linear_velocity;
			if is_instance_valid(body):
				body.gravity_scale = 0;
	
		##Lock up linear velocities while frozen.
		body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC;
		body.set_freeze_enabled(frozen);
	
		##If unfreezing, add an impulse for the velocity we had before.
		if not frozen:
			if preFreezevalue: ##Only If becoming unfrozen this frame, apply the impulse.
				print("Unpause velocity:", linearVelocityBeforeFreeze)
				if get_physics_process_delta_time() > 0:
					body.call("apply_impulse", linearVelocityBeforeFreeze * 1 / (get_physics_process_delta_time()));
					linearVelocityBeforeFreeze = null;
			body.gravity_scale = 1;
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
