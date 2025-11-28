extends Piece

class_name Piece_Sawblade
## Has a [Bullet] parrying ability ([method deflect]).
## [br]Deals contact damage, but only while recieving Energy.

@export var baseRotationSpeed := 270.0;
var rotationSpeed := baseRotationSpeed;
var rotationDeg := 0.0;
@export var sawSoundPlayer : AudioStreamPlayer3D;
var sawSoundVolume := 0.0;
var sawSoundPitch := 1.0;
var snd : SND;
var hitboxScaleOffset := 0.0;
var bladeScaleOffset := 1.0;
var bladeScaleBase := 0.713;

var reflectingBullets := false;
var reflectingTime := 0;

@export var blade : MeshInstance3D;

func phys_process_pre(delta):
	super(delta);
	#hitboxCollisionHolder.piv

func stat_registry():
	super();

func add_rotation(deg):
	rotationDeg += deg;
	if deg >= 360:
		deg -= 360;


func ability_registry():
	#register_active_ability("Deflect", "Spin the sawblade with extreme speed, causing it to deflect projectiles and deal extra damage.", func (): deflect())
	pass;

func phys_process_timers(delta):
	super(delta);
	if reflectingTime > 0:
		reflectingTime -= 1;
		get_host_robot().set_invincibility(0.1);
	else:
		hitboxScaleOffset = lerp(hitboxScaleOffset, 0.0, delta * 12) 
		bladeScaleOffset = lerp(bladeScaleOffset, 1.0, delta * 12) 
		damageModifier = lerp(damageModifier, 1.0, delta * 12)
	reflectingBullets = hitboxScaleOffset > 0.1;

func phys_process_collision(delta):
	super(delta);
	#if get_cooldown_active() > 0:
		##var maxCooldown = get_stat("CooldownActive");
		##var curCooldown = get_cooldown_active();
		##var ratio = curCooldown / maxCooldown;
		##hitboxCollisionHolder.scale
	hitboxCollisionHolder.scale.x = 1.0 + hitboxScaleOffset;
	hitboxCollisionHolder.scale.y = 1.0 + (hitboxScaleOffset * 8);
	hitboxCollisionHolder.scale.z = 1.0 + hitboxScaleOffset;
	#print(hitboxCollisionHolder.scale.y)
	#else:
		#hitboxCollisionHolder.scale = Vector3.ONE;

func phys_process_abilities(delta):
	super(delta);
	if can_use_passive_any() and not on_cooldown():
		rotationSpeed = lerp(rotationSpeed, baseRotationSpeed, delta * 4);
		pass;
	else:
		rotationSpeed = lerp(rotationSpeed, 0.0, delta * 4);
		damageModifier = 0.0;
		pass;
	add_rotation(rotationSpeed * delta);

func process_draw(delta):
	super(delta);
	blade.rotation.y = deg_to_rad(rotationDeg);
	blade.scale = Vector3.ONE * bladeScaleOffset * bladeScaleBase;

func contact_damage(otherPiece : Piece, otherPieceCollider : PieceCollisionBox, thisPieceCollider : PieceCollisionBox):
	if can_use_named_ability("Spin"):
		if super(otherPiece, otherPieceCollider, thisPieceCollider):
			#print("HUzzah!")
			set_cooldown_passive(get_named_action("Spin"));
			bladeScaleOffset /= 1.5;
		else:
			#print_rich("[color=orange]Sawblade tried to do contact damage, but is on passive cooldown for ",get_cooldown_passive()," seconds.")
			pass;
	else:
		#print_rich("[color=orange]Sawblade tried to do contact damage, but is unable to use its passive.")
		pass;
	pass;

#func cooldown_behavior_active(onCooldown : bool = on_cooldown_active()):
	#hitboxCollisionHolder.scale.lerp(Vector3.ONE * bladeScaleOffset, get_physics_process_delta_time() * 12)
	#pass;
#
#
#func cooldown_behavior_passive(onCooldown : bool = on_cooldown_passive()):
	#hitboxCollisionHolder.scale.lerp(Vector3.ONE * bladeScaleOffset, get_physics_process_delta_time() * 12)
	#pass;

func cooldown_behavior(_onCooldown : bool = on_cooldown()):
	#if onCooldown:
		#
		#return;
	if on_cooldown_named_action("Whirl"):
		set_cooldown_for_ability(get_named_action("Spin"));
		hitboxCollisionHolder.scale.lerp(Vector3.ONE * bladeScaleOffset, get_physics_process_delta_time() * 12)
		return;
	if on_cooldown_named_action("Spin"):
		hitboxCollisionHolder.scale.lerp(Vector3.ONE * 0.5, get_physics_process_delta_time() * 12)
		return;
	pass;

func deflect():
	bladeScaleOffset *= 1.75;
	hitboxScaleOffset += .75;
	reflectingTime = 15;
	rotationSpeed = max(baseRotationSpeed, rotationSpeed);
	rotationSpeed *= 9;
	#$ShapeCast3D.enabled = true;
	#$Timer.start();
	damageModifier *= 2;
	sawSoundPitch = 0.9;
	sawSoundVolume = 1.0;
	get_host_robot().set_invincibility(0.25);
	pass;

func bullet_hit_hitbox(bullet:Bullet):
	##TODO: Add enemies so this can actually be tested. Lol.
	if bullet.get_attacker() != get_host_robot():
		#print_rich("[color=orange]Bullet hit the hitbox.")
		pass;
	if reflectingBullets:
		if bullet.get_attacker() != get_host_robot():
			#var posDif = global_position - bullet.global_position;
			#bullet.flip_direction();
			#bullet.set_attacker(get_host_robot())
			reflectingTime += 5;
			var thisBot = get_host_robot();
			thisBot.call_deferred("take_knockback",(bullet.dir + Vector3(0,0.1,0)) * 1000);
			var dir = bullet.dir * -1;
			bullet.change_direction(dir);
			bullet.set_attacker(thisBot);
			bullet.verticalVelocity /= 2.0;
			bullet.speed *= 1.25;
			
			##Particles!!!
			var particlePos = Vector3(randf_range(0.1,-0.1), 0, randf_range(0.1,-0.1))
			particlePos += bullet.global_position
			ParticleFX.play("Sparks", GameState.get_game_board(), particlePos)
			SND.play_sound_at("Weapon.Sawblade.Parry", particlePos, GameState.get_game_board(), 1.0, 0.5);

func get_ability_slot_data(ability : AbilityManager):
	var data = super(ability);
	if ability.abilityName == "Whirl":
		#print("what")
		#print(get_named_action("Spin"))
		#print(on_cooldown_named_action("Spin"));
		if on_cooldown_named_action("Spin"):
			data["miscText"] = "SPIN is on cooldown!"
			#print("SPIN is on cooldown!")
			data["usable"] = false;
	#data["miscText"] = "SPIN is on cooldown!"
	return data;
