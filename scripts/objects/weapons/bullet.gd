@icon ("res://graphics/images/class_icons/bullet.png")
extends FreezableEntity
## A projectile that can be launched.[br]Is an Area3D rather than a Rigidbody3D, so it does not get affected by physics and will kill itself when touching anything it collides with.
class_name Bullet

## The direction in which this [Bullet] is currently flying.
var dir := Vector3(0,0,0);
## The speed at which this [Bullet] moves, multiplied by [member dir] each frame and added to position.
var speed := 30.0;
## How much knockback the recieving end of the attack recieves when this [Bullet] hits.
@export var knockbackMult := 1000.0;
## A multiplier for how big this guy is.
@export var sizeMult := Vector3(1.0,1.0,1.0);
## @deprecated: How much damage this will do to a [Combatant]. Set by Parts. DamageData takes priority.
var damage := 1.0;
## Whether this bullet has been fired or not. Being fired excludes it from being grabbed from the magazine.
var fired := false;
## How long this bullet will live for.
var lifetime := 1.0;
## @deprecated: A [Timer] to keep track of how long this has been alive. Now uses [member lifeDeltaTimer].
@export var lifeTimer : Timer;
## A timer counted down every frame when not [member frozen]. WHen it hits 0, the bullet goes poof automatically.
var lifeDeltaTimer := 1.0;
## A [RayCast3D] used to scan the distance traveled in the previous frame, to scan for any hits that may have been missed by high speeds.
@export var raycast : RayCast3D;
## A [ShapeCast3D] used to scan the distance traveled in the previous frame, to scan for any hits that may have been missed by high speeds.
@export var shapecast : ShapeCast3D;
## The [CollisionShape3D] that [member hitbox] uses to determine whether it's been hit.
@export var collision : CollisionShape3D;
## Set when fired. Stores the original [member global_position] of this Bullet at the time of firing.
var initPosition = position;
## Added to each frame by [code]direction * speed * delta[/code]. This plus [member initPosition] constitutes its current position in a frame.
var positionAppend := Vector3.ZERO;
## @deprecated: The [PartActive] that launched this.[br]Until we're 100% certain [Part]s will no longer be able to launch projectiles, this is gonna stay here.
var launcher : PartActive; 
## The [Piece] that launched this.
var launcherPiece : Piece;
## The [Robot] that damage from this projectile will be attributed to.
var attacker : Node3D;
## The [Robot] that launched this originally.
var originalAttacker : Node3D;
## A string to declare what [ParticleFX] this [Bullet] will spawn to follow it around as a trail.
@export var tracerFXString := "BulletTracer_small";
## The [resource DamageData] assigned to this bullet.
var damageData : DamageData:
	get:
		if ! is_instance_valid(damageData):
			damageData = DamageData.new();
			damageData.create(damage, knockbackMult, dir, [DamageData.damageTypes.PIERCING])
			if get_attacker() is Robot:
				damageData.attackerRobot = attacker;;
		return damageData;
## The [Area3D] that sends signals that it's been hit.
@export var hitbox : Area3D;
## The amount [member verticalVelocity] gets adjusted by each frame, * delta.
@export var gravity := -0.0987;
## How much y position is going to be affected each frame.
var verticalVelocity := 0.0;
## Updated every frame; The difference in positions from last frame to this one.
var positionDif := Vector3.ZERO;
## @deprecated: How many frames this bullet has been alive. Not in use for anything.
var framesAlive := 0;
## If this is true, next time [method die] is called, then this [Bullet] will call [method queue_free] and delete itself.
var leaking := false;
## How many times this bullet is allowed to deflect itself after hitting a wall before it goes kaput.
@export var bounces := 0; 
var bouncesLeft := bounces;
var collisionDisableFrames := 0;

func _ready():
	die(false);

## Whether this bullet is available to be scooped up and fired or not.
func available(printWhy := false):
	if leaking: 
		Utils.print_if_true("Bullet leaking", printWhy)
		queue_free(); 
		return false;
	if fired: 
		Utils.print_if_true("Already fired", printWhy)
		return false;
	if lifeDeltaTimer < 0: 
		Utils.print_if_true(("Alive too long, "+str(lifeDeltaTimer)), printWhy)
		leak();
		return false;
	if is_queued_for_deletion(): 
		Utils.print_if_true("Queued for deletion", printWhy)
		return false;
	#if hitSomething: return false;
	return true;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	super(delta);
	if not is_frozen():
		collision.disabled = collisionDisableFrames > 0;
		raycast.enabled = collisionDisableFrames == 0;
		shapecast.enabled = false;
		if collisionDisableFrames > 0:
			collisionDisableFrames -= 1;
		
		if fired && visible:
			positionAppend += (dir * speed * delta);
			positionAppend += Vector3(0,1,0) * verticalVelocity;
			verticalVelocity += gravity * delta;
			#print(verticalVelocity)
			var oldPos = global_position;
			position = initPosition + positionAppend;
			var newPos = global_position;
			positionDif = oldPos - newPos;
			
			var colPassed = check_passed_through();
			if colPassed is CollisionObject3D:
				shot_something(colPassed);
	if not visible:
		if leaking:
			die();
	pass

func phys_process_timers(delta):
	super(delta);
	if not is_frozen():
		if fired and visible:
			if lifeDeltaTimer < 0:
				_on_life_timer_timeout();
			lifeDeltaTimer -= delta;
		else:
			lifeDeltaTimer = 0;


## @deprecated: Fires from a given [Combatant] and [Node].[br]This is here for compatibility reasons until we can completely flush out all references to Combatants.
func fire(_attacker : Combatant, _launcher : Node ,_initPosition : Vector3, _direction := Vector3(1,0,0), _fireSpeed := 30.0, _lifetime := 1.0, _damage := 1.0):
	set_attacker(_attacker);
	originalAttacker = _attacker;
	if ! is_instance_valid(attacker): 
		die()
		return
	launcher = _launcher;
	speed = _fireSpeed;
	dir = _direction;
	lifetime = _lifetime;
	lifeTimer.wait_time = lifetime;
	lifeTimer.start();
	damage = _damage;
	positionAppend = Vector3.ZERO;
	initPosition = _initPosition;
	set_deferred("scale", sizeMult);
	position = initPosition;
	collision.set_deferred("disabled", false);
	raycast.set("enabled", true);
	rotateTowardVector3(dir);
	bouncesLeft = bounces;
	show();
	ParticleFX.play("SmokePuffSingle", GameState.get_game_board(), Vector3.ZERO, 0.5, self);
	ParticleFX.play(tracerFXString, GameState.get_game_board(), Vector3.ZERO, sizeMult, self,);
	fired = true;
	#print("I have been fired at ", global_position, ", attacker is at ", attacker.global_position)

## Fires from a given [Robot] and [Piece].
func fire_from_robot(_attacker : Robot, _launcher : Piece ,_initPosition : Vector3, _damageData : DamageData, _direction := Vector3(1,0,0), _fireSpeed := 30.0, _lifetime := 1.0, _gravity := -0.0987):
	launcherPiece = _launcher;
	set_attacker(_attacker);
	if ! is_instance_valid(attacker): 
		die();
		return;
	speed = _fireSpeed;
	dir = _direction;
	verticalVelocity = 0.0;
	lifetime = _lifetime;
	lifeDeltaTimer = lifetime;
	#lifeTimer.wait_time = lifetime;
	#lifeTimer.start();
	gravity = _gravity;
	damageData = _damageData;
	positionAppend = Vector3.ZERO;
	initPosition = _initPosition;
	set_deferred("scale", sizeMult);
	position = initPosition;
	collision.set_deferred("disabled", false);
	raycast.set("enabled", true);
	rotateTowardVector3(dir);
	bouncesLeft = bounces;
	show();
	unfreeze();
	ParticleFX.play("SmokePuffSingle", GameState.get_game_board(), Vector3.ZERO, 0.5, self);
	ParticleFX.play(tracerFXString, GameState.get_game_board(), Vector3.ZERO, sizeMult, self,);
	fired = true;
	#print("I have been fired at ", global_position, ", attacker is at ", attacker.global_position)

## A function to make the bullet rotate its [member rotation.y] to look at the direction it's moving in.
func rotateTowardVector3(dir : Vector3):
	Utils.look_at_safe(self, global_transform.origin + dir, Vector3.UP);
	#look_at(, Vector3.UP)
	rotation.x = dir.y;

## Changes [member dir], and calls [method rotateTowardVector3] to update visuals.
func change_direction(newAngle : Vector3):
	dir = newAngle;
	rotateTowardVector3(dir);

## Changes [member dir] to [code]dir * -1[/code], and calls [method rotateTowardVector3] to update visuals.
func flip_direction():
	dir *= -1;
	rotateTowardVector3(dir);

## Gets the normal of whatever collider is ahead of this bullet.
func get_normal_ahead():
	var difLen = positionDif.length();
	shapecast.enabled = true
	shapecast.shape = collision.shape;
	shapecast.scale = hitbox.scale;
	shapecast.position.z = difLen; 
	shapecast.target_position.z = -difLen * 2;
	shapecast.force_shapecast_update();
	if shapecast.is_colliding():
		var allNorm := Vector3.ZERO
		for id in shapecast.get_collision_count():
			var norm = shapecast.get_collision_normal(id);
			allNorm += norm
		return (allNorm / shapecast.get_collision_count()).normalized();
	return false;

func check_passed_through():
	var difLen = positionDif.length();
	raycast.position.z = difLen;
	raycast.target_position.z = -difLen;
	if raycast.is_colliding():
		var col = raycast.get_collider();
		#print("Bullet Raycast hit something this time")
		return col;
	return false;

func bounceBullet():
	if bouncesLeft <= 0:
		die();
		return;
	add_collision_disable_frames(2);
	var normal = get_normal_ahead();
	if normal is Vector3:
		change_direction(dir.bounce(normal));
	bouncesLeft -= 1;
	#print("BOUNCES LEFT: " ,bouncesLeft)
	#print("BOUNCE NORMAL: " ,normal)

## Called when this [Bullet] hits something. Kills it off and starts it leaking.
func die(noisy := true):
	if visible and noisy: 
		ParticleFX.play("SmokePuffSingle", GameState.get_game_board(), position, 0.5);
	#position = Vector3.ZERO;
	fired = false;
	collision.set("disabled", true);
	raycast.set("enabled", false);
	hide();
	set_attacker(originalAttacker);
	if leaking:
		queue_free();
	pass

## @deprecated: Calls [method die].[br]Called when [member lifeTimer] runs out of time, but [member lifeTimer] never starts when fired using [method fire_from_robot].
func _on_life_timer_timeout():
	die();
	pass # Replace with function body.

func _on_body_entered(body):
	shot_something(body);
	pass # Replace with function body.

func _on_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	if not leaking and body is RobotBody and body.get_parent() != get_attacker():
		#print("tis a robot. from ", name)
		var other_shape_owner = body.shape_find_owner(body_shape_index)
		var other_shape_node = body.shape_owner_get_owner(other_shape_owner)
		if other_shape_node is not PieceCollisionBox: return;
		
		var local_shape_owner = hitbox.shape_find_owner(local_shape_index)
		var local_shape_node = hitbox.shape_owner_get_owner(local_shape_owner)
		#if local_shape_node is not PieceCollisionBox: return;
		
		var otherPiece : Piece = other_shape_node.get_piece();
		#print("Other Piece in hitbox collision: ", otherPiece)
		if ! is_instance_valid(otherPiece): return;
		#print("Bullet damage commencing:")
		shot_something(body);
	pass # Replace with function body.

## Fired after either [member hitbox] or [member raycast] have sensed that they've hit something. Sets up damage to the potential target, plays particles, then dies.
func shot_something(inbody):
	if leaking: return;
	if ! is_instance_valid(inbody): return;
	if ! visible: return;
	if Utils.is_equal_approx_vector3(get_current_position(), initPosition): return;
	var validTarget = false;
	var parent = inbody.get_parent();
	
	if inbody in casterExceptions:
		return;
	#if parent == attacker:
		#return;
	#if parent == launcher:
		#return;
	if parent is Combatant:
		#print(inbody.get_parent())
		parent.take_damage(damage);
		parent.call_deferred("take_knockback",(dir + Vector3(0,0.01,0)) * knockbackMult);
		#print("should be taking knockback....")
		validTarget = true;
	elif inbody is RobotBody:
		parent = inbody.get_robot()
		#print(inbody.get_parent())
		#print_rich("[color=purple]Bullet hit robot. Yippie!")
		parent.take_damage_from_damageData(damageData);
		validTarget = true;
	elif inbody is HurtboxHolder:
		var piece = inbody.get_piece();
		if piece.hasHostRobot:
			var bot = piece.hostRobot;
			if bot == get_attacker():
				return;
			
			piece.hurtbox_collision_from_projectile(self, damageData);
			
			validTarget = true;
	elif inbody is StaticBody3D:
		validTarget = true;
		#parent.call_deferred("take_knockback",(dir + Vector3(0,0.01,0)) * knockbackMult);
		#print("should be taking knockback....")
	#print("Shot ded by ",inbody, " named: ", inbody.name)
	
	#if not ( inbody.is_in_group("Player Part") ):
		#die()
		#;
		
	#Hooks.OnCollision(self, inbody);
	#prints("Bullet hit a thing! If this doesn't show, then something borked...")
	#prints("BULLET INBODY: ", inbody)
	#prints(self, inbody)
	#prints(fired, lifeTimer, lifeDeltaTimer)
	
	SND.play_collision_sound(self, inbody, get_current_position(), 0.85, 1.5);
	ParticleFX.play("Sparks", GameState.get_game_board(), get_current_position(), 0.5);
	
	#hitSomething = true;
	#print(validTarget)
	bounceBullet();

## Sets [member leaking] to true.
func leak():
	leaking = true;
## Returns [code]initPosition + positionAppend[/code].
func get_current_position():
	return initPosition + positionAppend;

## Returns [member attacker].
func get_attacker():
	return attacker;
## Returns [member launcherPiece].
func get_launcher():
	return launcherPiece;

## Sets the attacker to a new attacker. Works with both Combatants and Robots while we transition.
func set_attacker(atkr):
	attacker = atkr;
	var newExceptions : Array[CollisionObject3D] = []
	
	if attacker is Combatant:
		newExceptions.append(get_attacker().body);
	if attacker is Robot:
		newExceptions.append_array(attacker.get_all_piece_hurtbox_holders());
		newExceptions.append(attacker.body);
		newExceptions.append(get_launcher().hurtboxCollisionHolder);
	
	newExceptions.append(hitbox);
	
	set_caster_exceptions_and_collision_flags(newExceptions);

const layerFlags : Dictionary[int, bool] = {
	1 : false, ## This is NOT a robot body.
	10: true, ## This is a bullet.
}
const maskFlags : Dictionary[int, bool] = {
	1 : false, ## DON'T collide with robot bodies.
	4 : true, ## Collide with Piece hurtboxes,
	7 : true, ## Collide with *placed* Piece hurtboxes.
	10: true, ## Collide with other bullets.
	11: true, ## Collide with the ground.
}

var collisionSet := false;
var casterExceptions : Array[CollisionObject3D] = [];
func set_caster_exceptions_and_collision_flags(exceptions : Array[CollisionObject3D]):
	raycast.clear_exceptions();
	shapecast.clear_exceptions();
	
	casterExceptions = exceptions;
	
	for exception in exceptions:
		raycast.add_exception(exception);
		shapecast.add_exception(exception);
	
	if ! collisionSet:
		collisionSet = true;
		hitbox.collision_layer = 0;
		hitbox.collision_mask = 0;
		raycast.collision_mask = 0;
		shapecast.collision_mask = 0;
		for flagNum in maskFlags:
			var flagValue = maskFlags[flagNum]
			hitbox.set_collision_mask_value(flagNum, flagValue);
			raycast.set_collision_mask_value(flagNum, flagValue);
			shapecast.set_collision_mask_value(flagNum, flagValue);

func add_collision_disable_frames(amt:=1):
	collisionDisableFrames += amt;
