@icon ("res://graphics/images/class_icons/robot_base.png")
extends StatHolder3D;

##This entity can be frozen and paused, and can hold stats.[br]
##This entity is a Robot.
class_name Robot

@export_category("General")
@export var meshes : Node3D; ## The [Node3D] responsible for holding any extraneous meshes we may want to give this [Robot], but mainly just [member bodySocket].
@export var bodyPiece : Piece; ## The [Piece] this [Robot] is using as the 3D representation of its body, directly connected to the [Socket] placed visually on the treads.
@export var bodySocket : Socket; ## The [Socket] the [member bodyPiece] gets plugged into.
var gameBoard : GameBoard; ## The root scene.
var camera : Camera; ## The main game camera.
@export var robotNameInternal : String = "Base"; ## The name this [Robot] uses in the codebase.
@export var robotName : String = "Basic"; ## The name this [Robot] uses in-game.
@export var treads : UnderbellyContactPoints; ## The wheels.
var bodyBasis : Basis;
var body : RobotBody;


################################## GODOT PROCESSING FUNCTIONS
func _ready():
	if ! Engine.is_editor_hint():
		hide();
		load_from_startup_generator();
		super();
		detach_pipette();
		freeze(true, true);
		start_all_cooldowns(true);
		assign_references();
		queue_piece_tree_regen(false, true);

func _process(delta):
	if ! Engine.is_editor_hint():
		process_pre(delta);
		if spawned and is_ready:
			process_hud(delta);
	pass

func _physics_process(delta):
	if ! Engine.is_editor_hint():
		#motion_process()
		super(delta);
		if spawned and is_ready and referencesAssigned:
			phys_process_collision(delta);
			GameState.profiler_time_msec_start("robot phys_process_motion 1: full call")
			phys_process_motion(delta);
			GameState.profiler_time_msec_end("robot phys_process_motion 1: full call")
			phys_process_combat(delta);
	pass

##Process and Physics process that run before anything else.
func process_pre(delta):
	## Update whether the bot was alive last frame.
	aliveLastFrame = is_alive();
	## Take the bot out of reverse.
	in_reverse = false;
	## Make the bot come alive if it is queued to do so.
	if is_ready and queuedLife:
		live();
	## Update any invalid references or nodes, if referencesAssigned is set to false.
	assign_references();
	pass;

func phys_process_pre(delta):
	super(delta);
	assign_references();
	if referencesAssigned:
		bodyBasis = body.global_basis;
	pass;

func process_timers(delta):
	super(delta);

func phys_process_timers(delta):
	super(delta);
	##Freeze this bot before it can do physics stuff.
	if not is_frozen():
		##Sleep.
		sleepTimer = max(sleepTimer-delta, 0);
		
		##Invincibility.
		if invincibleTimer > 0:
			invincibleTimer -= delta;
			if not invincible:
				invincible = true;
				health_or_energy_changed.emit();
		else:
			invincibleTimer = 0.0;
			if invincible:
				invincible = false;
				health_or_energy_changed.emit();
		
		## Floorness.
		step_coyote_timer(delta);
		body.isOnGround = isOnFloor;

## When false, [method assign_references] will run as usual. When true, it will return without doing anythinng, as nothing borked.
var referencesAssigned := false;
## Grab all variable references to nodes that can't be declared with exports, or that were but may have broken.[br]
## If [param forceTemp] is [code]true[/code], it forces this to re-run (ignoring [member referencesAssigned]), and then not set [member referencesAssigned] to [code]true[/code]. This is only used during initial setup.
func assign_references(forceTemp := false):
	
	regeneratedPieceTreeStatsThisFrame = false;
	
	if ! forceTemp:
		if referencesAssigned:
			return;
	if not is_instance_valid(body):
		if is_instance_valid($Body):
			body = $Body;
	if is_instance_valid(body):
		body.set_collision_mask_value(1, false);
		body.set_collision_mask_value(11, true);
		bodyBasis = body.global_basis;
		body.robot = self;
	if not is_instance_valid(gameBoard):
		gameBoard = GameState.get_game_board();
	if not is_instance_valid(camera):
		camera = GameState.get_camera();
	if not is_instance_valid(bodySocket):
		bodySocket = $Body/Meshes/Socket;
	if not is_instance_valid(bodyPiece):
		if is_instance_valid(bodySocket):
			set_deferred("bodyPiece",bodySocket.get_occupant());
	if not is_instance_valid(treads):
		treads = $Treads;
	
	if ! forceTemp:
		referencesAssigned = true;

func freeze(doFreeze := (not is_frozen()), force := false):
	super(doFreeze, force)
	reinforce_piece_freeze();

## Loops thru all Pieces and force-freezes them based on the bot's current frozen status.
func reinforce_piece_freeze():
	for piece in allPieces:
		piece.freeze(is_frozen(), true);

func stat_registry():
	super();
	register_stat("HealthMax", maxHealth, StatHolderManager.statIconHeart, StatHolderManager.statTags.Hull);
	register_stat(
		"Health", 
		maxHealth, 
		StatHolderManager.statIconHeart, 
		StatHolderManager.statTags.Hull,
		StatHolderManager.displayModes.ALWAYS,
		StatHolderManager.roundingModes.ClampToZeroAndMax,
		"HealthMax",
		null, 
		func(newValue):
		health_or_energy_changed.emit(); 
		return newValue;
		);
	register_stat("EnergyMax", maxEnergy, StatHolderManager.statIconEnergy, StatHolderManager.statTags.Battery);
	register_stat(
		"Energy", 
		maxEnergy, 
		StatHolderManager.statIconEnergy, 
		StatHolderManager.statTags.Battery, 
		StatHolderManager.displayModes.ALWAYS, 
		StatHolderManager.roundingModes.ClampToZeroAndMax,
		"EnergyMax",
		null, 
		func(newValue): 
		health_or_energy_changed.emit();
		return newValue;
		);
	register_stat("InvincibilityTime", maxInvincibleTimer, StatHolderManager.statIconCooldown, StatHolderManager.statTags.Clock);
	register_stat("MovementSpeedAcceleration", acceleration, StatHolderManager.statIconCooldown, StatHolderManager.statTags.Function);
	register_stat("MovementSpeedMax", maxSpeed, StatHolderManager.statIconCooldown, StatHolderManager.statTags.Function, );
	prints("MAX SPEED: ",get_stat("MovementSpeedMax"), maxSpeed)
	pass;

################## SAVING/LOADING

##Stores the data required to load this robot from an editor save. Stored as the data [method bodySocket] needs to initialize the chain reaction.
@export var startupGenerator : Dictionary = { "rotation": 0.0, "occupant" : { "res://scenes/prefabs/objects/pieces/piece_bodyCube.tscn": { "sockets": { 0: { "occupant": "null", "rotation": 0.0 }, 1: { "occupant": "null", "rotation": 3.14159 }, 2: { "occupant": "null", "rotation": -2.25163 }, 3: { "occupant": "null", "rotation": -2.25158 }, 4: { "occupant": "null", "rotation": 0.0 } } } }
};

func prepare_to_save():
	print("SAVE: prep function")
	hide();
	reset_collision_helpers();
	create_startup_generator();
	clear_stats();
	is_ready = false;
	bodyPiece.queue_free();

############################## SAVE/LOAD

## Creates the data that builds this robot at _ready().
func create_startup_generator():
	#print("SAVE: generating")
	startupGenerator = { "occupant" = bodyPiece.create_startup_data(), "rotation" = Vector3(0,0,0) };
	#print("SAVE: end result: ", startupGenerator)
	pass;

## Creates this robot from data saved to it. If there is none, it doesn't run.
func load_from_startup_generator():
	assign_references(true);
	print("SAVE: Checking validation of startupGenerator: ", is_instance_valid(startupGenerator), startupGenerator is Dictionary)
	if startupGenerator is Dictionary and not startupGenerator.is_empty():
		#bodySocket.remove_occupant(true);
		print("SAVE: Loading startup generator: ", startupGenerator)
		#print(startupGenerator);
		bodySocket.hostRobot = self;
		print("SOCKET HOST BEFORE ADDING STARTUP DATA:", bodySocket, bodySocket.hostRobot)
		bodySocket.load_startup_data(startupGenerator, self)
		
	pass;

## Recursively sets all sockets and pieces with this as their hostRobot through the tree.
func reinforce_robot_host():
	bodySocket.set_host_robot(self);

########## HUD

var forcedUpdateTimerHUD := 0;
var queueCloseEngine := false;
var engineViewer : PartsHolder_Engine;

func queue_close_engine():
	queueCloseEngine = true;

var queueUpdateEngineWithSelectedOrPipette := false;
func queue_update_engine_with_selected_or_pipette():
	queueUpdateEngineWithSelectedOrPipette = true;

var selected := false;
func is_selected() -> bool:
	return selected;
func select(foo:bool= ! is_selected()):
	print("ROBOT SELECT: ", foo)
	if selected != foo:
		selected = foo;
	queue_update_hud();
func deselect():
	select(false);

func process_hud(delta):
	if Input.is_action_just_pressed("StashSelected") and GameState.get_in_state_of_building():
		print("Stash button pressed")
		stash_selected_piece(true);
		update_hud();
	if Input.is_action_just_pressed("Unselect"):
		print("Unselect button pressed")
		deselect_in_hierarchy();
	if is_instance_valid(engineViewer):
		if queueUpdateEngineWithSelectedOrPipette:
			var selectionResult = get_selected_or_pipette(true);
			#print("Selection result ", selectionResult)
			if selectionResult != null:
				if selectionResult is Piece:
					engineViewer.open_with_new_piece(selectionResult);
			else:
				queue_close_engine();
			
			queueUpdateEngineWithSelectedOrPipette = false;
		
		if queueCloseEngine:
			engineViewer.close_and_clear();
			queueCloseEngine = false;
func queue_update_hud():
	call_deferred("update_hud");
func update_hud(forced := false):
	if is_ready or forced:
		update_inspector_hud(get_selected_for_inspector());
		queue_update_engine_hud();
		update_stash_hud();
		return true;

func update_stash_hud():
	if is_instance_valid(inspectorHUD):
		inspectorHUD.regenerate_stash(self);
func queue_update_engine_hud():
	if is_instance_valid(engineViewer):
		queue_update_engine_with_selected_or_pipette();
func queue_update_engine_button_gfx():
	if is_instance_valid(engineViewer):
		engineViewer.update_button_gfx();

func update_inspector_hud(input = null):
	if is_instance_valid(inspectorHUD):
		inspectorHUD.update_selection(input);

######################### STATE CONTROL

var spawned := false;
@export var sleepTimerLength := 0.0; ## An amount of time in which this robot isn't allowed to do anything after spawning.
var sleepTimer := sleepTimerLength; ## An amount of time the robot must wait.
##Returns true if there's an active sleep timer going. Sleep should be used to prevent actions for a bit on enemies, and maybe "stun" status effects in the future.
func is_asleep() -> bool:
	return sleepTimer > 0;

##This function returns true only if the game is not paused, and the bot is spawned in, alive, awake, and not frozen.
func is_conscious():
	return (not paused) and spawned and (not is_asleep()) and (not is_frozen()) and is_alive() and is_ready;

## Returns true if the bot is in a state where its pieces' cooldowns are able to be used.[br]
## Functionally identical to [method is_conscious], except in [Robot_Player], where [method is_conscious] is modified to also check for [member Robot_Player.hasPlayerControl].
func is_running_cooldowns():
	return (not paused) and spawned and (not is_asleep()) and (not is_frozen()) and is_alive() and is_ready;

##This function returns true only if the game is not paused, the bot is not frozen, alive, and we're in a game state of play.
func is_playing():
	#return true;
	return (not paused) and (not is_frozen()) and (is_alive()) and GameState.get_in_state_of_play();
func is_building(): return GameState.get_in_state_of_building();

##Fired by the gameboard when a new game starts.
func start_new_game():
	pass;
##Fired by the gameboard when the round ends.
func end_round():
	pass;
##Fired by the gameboard when the round starts.
func start_round():
	pass;
##Fired by the gameboard when the shop gets opened.
##In here and not in the player subset... just in case.
func enter_shop():
	pass;
##Fired by the gameboard when the shop gets closed.
##In here and not in the player subset... just in case.
func exit_shop():
	pass;

##Function run when the bot first spawns in.
func live():
	queuedLife = false;
	unfreeze(true);
	show();
	body.show();
	spawned = true;
	alive = true;
	start_all_cooldowns(true); ## Semi-redundant.
	var healthMax = get_max_health();
	#print_rich("[color=pink]Max health is ", healthMax, ". Does stat exist: ", stat_exists("HealthMax"), ". Checking from: ", robotName);
	set_stat("Health", healthMax);
	var energyMax = get_max_energy();
	set_stat("Energy", energyMax);
	
	update_hud();

var queuedLife := false;
func queue_live():
	queuedLife = true;
	pass;

func die():
	#Hooks.OnDeath(self, GameState.get_player()); ##TODO: Fix hooks to use new systems before uncommenting this.
	if ! aliveLastFrame: return false;
	alive = false;
	##Play the death sound
	if GameState.get_in_state_of_play():
		SND.play_sound_nondirectional(deathSound);
	##Play the death particle effects.
	ParticleFX.play("NutsBolts", GameState.get_game_board(), get_global_body_position());
	ParticleFX.play("BigBoom", GameState.get_game_board(), get_global_body_position());
	
	
	Hooks.OnDeath(self, lastAttacker);
	destroy();

func destroy():
	for thing in get_stash_all(PieceStash.equippedStatus.ALL):
		if is_instance_valid(thing):
			thing.destroy();
	queue_free();
	update_hud(true);

################################# STASH

var inspectorHUD : Inspector;
##The effective "inventory" of this robot. Inaccessible outside of Maker Mode for [@Robot]s that are not a [@Robot_Player].
var stashPieces : Array[Piece] = []
var stashParts : Array[Part] = []

func get_stash_pieces(equippedStatus : PieceStash.equippedStatus = PieceStash.equippedStatus.ALL):
	var ret = [];
	match equippedStatus:
		PieceStash.equippedStatus.ALL:
			ret.append_array(stashPieces);
			ret.append_array(get_all_pieces());
		PieceStash.equippedStatus.EQUIPPED:
			ret.append_array(get_all_pieces());
		PieceStash.equippedStatus.NOT_EQUIPPED:
			ret.append_array(stashPieces);
	return ret;
func get_stash_parts(equippedStatus : PieceStash.equippedStatus = PieceStash.equippedStatus.ALL):
	var ret = [];
	match equippedStatus:
		PieceStash.equippedStatus.ALL:
			ret.append_array(stashParts);
			ret.append_array(get_all_parts(PieceStash.equippedStatus.ALL));
		PieceStash.equippedStatus.EQUIPPED:
			ret.append_array(get_all_parts(PieceStash.equippedStatus.EQUIPPED));
		PieceStash.equippedStatus.NOT_EQUIPPED:
			ret.append_array(stashParts);
	return ret;
## Gets everything currently in either [member stashParts] or [member stashPieces].
func get_stash_all(equippedStatus : PieceStash.equippedStatus = PieceStash.equippedStatus.ALL):
	var ret = [];
	ret.append_array(get_stash_pieces(equippedStatus));
	ret.append_array(get_stash_parts(equippedStatus));
	return ret;

func remove_something_from_stash(inThing):
	if inThing is Piece:
		var count = 0;
		for item in stashPieces:
			if item == inThing:
				stashPieces.remove_at(count);
			count += 1;
	if inThing is Part:
		var count = 0;
		for item in stashParts:
			if item == inThing:
				stashParts.remove_at(count);
			count += 1;
	
	update_stash_hud();

func add_something_to_stash(inThing):
	call_deferred("update_stash_hud")
	if inThing is Piece:
		add_instantiated_piece_to_stash(inThing);
		return true;
	if inThing is Part:
		add_instantiated_part_to_stash(inThing);
		return true;
	if inThing is PackedScene:
		add_packed_piece_or_part_to_stash(inThing);
		return true;
	return false;

func add_packed_piece_or_part_to_stash(inPieceScene : PackedScene):
	var newPiece = inPieceScene.instantiate();
	if newPiece is Piece:
		add_instantiated_piece_to_stash(newPiece);
		return true;
	if newPiece is Part:
		add_instantiated_part_to_stash(newPiece);
		return true;
	#print(inPieceScene, " failed to add to stash at packedScene step.")
	return false;

func add_instantiated_piece_to_stash(inPiece : Piece):
	stashPieces = Utils.append_unique(stashPieces, inPiece);
	call_deferred("update_stash_hud");

func add_instantiated_part_to_stash(inPiece : Part):
	Utils.append_unique(stashParts, inPiece);
	call_deferred("update_stash_hud");

##The path to the scene the Piece placement pipette is using.
var pipettePiecePath := "";
var pipettePieceScene : PackedScene;
var pipettePieceInstance : Piece;
var pipettePartInstance : Part;

func get_current_pipette(init := true):
	#if ! GameState.get_in_state_of_building():
		#unreference_pipette()
		#return null;
	
	if is_instance_valid(pipettePartInstance):
		return pipettePartInstance;
	if is_instance_valid(pipettePieceInstance):
		return pipettePieceInstance;
	if is_instance_valid(pipettePieceScene):
		return pipettePieceScene;
	if is_instance_valid(pipettePiecePath):
		return pipettePiecePath;
	
	if init:
		var selectedPotential = get_selected();
		if is_instance_valid(selectedPotential) and ! selectedPotential.is_inside_tree():
			if get_stash_all(PieceStash.equippedStatus.NOT_EQUIPPED).has(selectedPotential):
				prepare_pipette(selectedPotential);
				
				return get_current_pipette(false);
	
	return null;

func prepare_pipette_from_path(scenePath : String = pipettePiecePath):
	#print("Preparing pipette")
	pipettePiecePath = scenePath;
	pipettePieceScene = load(scenePath);
	prepare_pipette_from_scene(pipettePieceScene);

func prepare_pipette_from_scene(scene := pipettePieceScene):
	var newPiece = scene.instantiate();
	if newPiece is Piece:
		prepare_pipette_from_piece(newPiece);

func prepare_pipette_from_piece(newPiece : Piece):
	deselect_all_pieces();
	pipettePieceInstance = newPiece;
	pipettePieceInstance.hostRobot = self;

func prepare_pipette_from_part(newPart : Part):
	pipettePartInstance = newPart;
	pipettePartInstance.hostRobot = self;

func prepare_pipette(override : Variant = get_current_pipette()):
	if override is String: 
		prepare_pipette_from_path(override);
	if override is PackedScene: 
		prepare_pipette_from_scene(override);
	if override is Piece: 
		prepare_pipette_from_piece(override);
	if override is Part: 
		prepare_pipette_from_part(override);
	
	queue_update_hud();

## Clears out the current pipette.
func unreference_pipette():
	pipettePiecePath = "";
	pipettePieceScene = null;
	if is_instance_valid(pipettePieceInstance):
		pipettePieceInstance.deselect();
	pipettePieceInstance = null;
	pipettePartInstance = null;
	queue_update_hud();

## Clears out the current pipette, after removinng it from its [Socket] (if it is a [Piece]).
func detach_pipette():
	if is_instance_valid(pipettePieceInstance):
		pipettePieceInstance.remove_from_socket();
	unreference_pipette();

################################## HEALTH AND LIVING


@export_category("Combat Handling")

## Emitted when Health or Energy are changed, or when the bot enters/exits invincibility.
signal health_or_energy_changed();

func _on_health_or_energy_changed():
	if not is_frozen() and is_zero_approx(get_health()):
		die();
	pass # Replace with function body.

@export var deathSound := "Combatant.Die";

func start_all_cooldowns(immediate := false):
	for piece in allPieces:
		piece.set_all_cooldowns();

@export_category("Health Management")
##Game statistics.
@export var maxHealth := 3.0;

func get_health():
	return get_stat("Health");

func get_max_health():
	##TODO: Add bonuses into this calc.
	return get_stat("HealthMax");

var immunities : Dictionary = {
	"general" : 1.0
}

##TODO: This function regenerates the list of damage type immunities and resistances granted by bonuses.
func generate_immunities():
	return immunities;

func get_immunities():
	return immunities;

##This function multiplies damage based on any damage type damage-taken modifiers.
func modify_damage_based_on_immunities(damageData : DamageData):
	var dmg = damageData.get_damage();
	for type in damageData.tags:
		if type in immunities:
			dmg *= immunities[type];
	dmg *= immunities["general"];
	if is_invincible(): return min(0.0, dmg)
	return dmg;

var lastAttacker : Variant;
func take_damage_from_damageData(damageData : DamageData):
	take_damage(modify_damage_based_on_immunities(damageData));
	take_knockback(damageData.get_knockback(), damageData.get_damage_position_local(true))
	lastAttacker = damageData.attackerRobot;

func take_damage(damage:float):
	#print("Damage being taken: ", damage)
	if is_playing() && damage != 0.0:
		#print(damage," damage being taken.")
		var health = get_health();
		var isInvincible = is_invincible();
		TextFunc.flyaway(TextFunc.round_to_dec(damage, 3), get_global_body_position() + Vector3(0,1,0), "unaffordable")
		if damage > 0:
			if !isInvincible:
				#print("Health b4 taking", damage, "damage:", health)
				health -= damage;
			else:
				#print("Health was not subtracted. Bot was invincible!")
				return;
		set_invincibility();
		#print("Health after taking", damage, "damage:", health)
		set_stat("Health", health);
		#print("Health was subtracted. Nothing prevented it. ", get_health())

func heal(health:float):
	take_damage(-health);

## WHether this bot was alive [i]last[/i] frame.[br]Updatied in [method process_pre].
var aliveLastFrame := false;
## Returns true if [member alive] and [member is_ready] are both true.
func is_alive():
	return is_ready and alive;

var invincible := false;
var invincibleTimer := 0.0;
@export var maxInvincibleTimer := 0.25; #TODO: Add in bonuses for this.
## Whether the bot is currently considered "alive".[br][b]Note:[/b] In order for [method is_alive] to return [code]true[/code], [member is_ready] must ALSO be true.
var alive := false;

##Replaces the invincible timer with the value given (Or maxInvincibleTimer by default) if that value is greater than the current invincibility timer.
func set_invincibility(amountOverride : float = maxInvincibleTimer):
	#print("old invincibility time: ",invincibleTimer)
	invincibleTimer = max(invincibleTimer, amountOverride);
	#print("new invincibility time: ",invincibleTimer)
	health_or_energy_changed.emit();

func is_invincible() -> bool:
	invincible = invincibleTimer > 0 or (GameState.get_setting("godMode") == true && self is Robot_Player) or (GameState.get_setting("EnemyGodMode") == true && self is Robot_Enemy);
	return invincible or invincibleTimer > 0 or (GameState.get_setting("godMode") == true && self is Robot_Player);

func take_knockback(inDir:Vector3, posDir:=Vector3.ZERO):
	##TODO: Weight calculation.
	#inDir *= 100;
	inDir.y = 0;
	#if isOnFloor:
		#inDir.y = 200;
	body.call_deferred("apply_impulse", inDir, posDir);
	pass

func apply_force(inDir:Vector3):
	body.apply_force(inDir);
	#print(inDir)

## Regenerates [member weightLoad], and queues regeneration for [member movementSpeedAcceleration] and [member weightSpeedModifier], via [member regenMovementSpeedAcceleration] and [member regenWeightSpeedModifier] respectively.
var regenWeightLoad := false;
var weightLoad : float = -1.0:
	get:
		if regenWeightLoad or weightLoad < 0:
			get_weight_regenerate();
		return weightLoad;
func get_weight_regenerate():
	regenWeightSpeedModifier = true;
	regenMovementSpeedAcceleration = true;
	regenWeightLoad = false;
	weightLoad = bodySocket.get_weight_load(true);
	return weightLoad;
func get_weight(forceRegen := false):
	if forceRegen:
		regenWeightLoad = true;
	return weightLoad;


var regenMovementSpeedAcceleration = true;
var movementSpeedAcceleration := 1.0:
	get:
		if regenMovementSpeedAcceleration:
			return get_movement_speed_acceleration();
		return movementSpeedAcceleration;
func get_movement_speed_acceleration() -> float:
	if !regenMovementSpeedAcceleration:
		return movementSpeedAcceleration;
	var base = get_stat("MovementSpeedAcceleration");
	var mod = weightSpeedModifier;
	regenMovementSpeedAcceleration = false;
	movementSpeedAcceleration = max(0, base * mod);
	return movementSpeedAcceleration;

var regenWeightSpeedModifier = true;
var weightSpeedModifier := 1.0:
	get:
		if regenWeightSpeedModifier:
			return get_weight_speed_modifier();
		return weightSpeedModifier;
func get_weight_speed_modifier(baseValue := 1.5) -> float:
	if !regenWeightSpeedModifier:
		return weightSpeedModifier;
	var mod = 0.0;
	mod += baseValue;
	mod -= weightLoad * weightSpeedPenaltyMultiplier;
	#print(mod);
	weightSpeedModifier = max(0, mod);
	regenWeightSpeedModifier = false;
	return weightSpeedModifier;



##Physics process for combat. 
func phys_process_combat(delta):
	
	#return;
	if not is_frozen():
		pass;

################################## ENERGY

@export_category("Energy Management")
@export var maxEnergy := 3.0;

##Returns available power. Whenever something is used in a frame, it should detract from the energy variable.
func get_available_energy() -> float:
	#prints("Available energy:", maxEnergy, get_maximum_energy(), get_stat("Energy"))
	#print(statCollection)
	#for stat in statCollection:
		#print(stat.statName, stat.get_stat())
	return get_stat("Energy");

func get_max_energy() -> float:
	return get_stat("EnergyMax");

##Returns true or false depending on whether the sap would work or not.
func try_sap_energy(amount):
	if is_conscious():
		var energy = get_available_energy();
		if amount <= energy:
			#energy -= amount;
			#print(amount)
			set_stat("Energy", energy - amount);
			return true;
		else:
			return false;
	return false;

## Sets energy to 0.
func drain_all_energy():
	set_stat("Energy", 0.0);

##Adds to the energy total. 
##If told to "cap at max" it will not add energy if it is above or at the current maximum, and will clamp it at the max. 
##If told NOT to "cap at max" it will just flat add the energy amount. 
func generate_energy(amount, capAtMax := true):
	var energy = get_available_energy();
	if capAtMax: 
		energy = clamp(energy + amount, 0, get_max_energy());
	else:
		energy += amount;
	
	set_stat("Energy", energy);

################################# MOTION HANDLER STUFF

@export_category("Motion Handling")


#TODO: Implement "target pointer" to be used in mouse aiming and AI targeting. 


func get_global_body_position():
	return body.global_position;
func get_global_body_rotation():
	return body.global_rotation;

##Should fire whenever a Piece connected to this robot gets hit by something.
func on_hitbox_collision(body : PhysicsBody3D, pieceHit : Piece):
	pass;

## Sets up a deferred call to [method regen_piece_tree_stats], and then calls [method queue_update_hud].
func queue_piece_tree_regen(needPlacementColliders := false, forceRegen := false):
	if forceRegen:
		regeneratedPieceTreeStatsThisFrame = false;
	call_deferred("regen_piece_tree_stats", needPlacementColliders);
	queue_update_hud();

var regeneratedPieceTreeStatsThisFrame := false;
var lastNeedForPlacementColliders := false;
## Regenerates all the things that need to be regenerated when changing piece data around. Do not call directly, use [method queue_piece_tree_regen].
func regen_piece_tree_stats(needPlacementColliders := false):
	## If the last time this was called, and it needed the same placement collider requirements, return , because the work has already been done.
	## If they were different, 
	if regeneratedPieceTreeStatsThisFrame:
		if lastNeedForPlacementColliders == needPlacementColliders:
			return;
	lastNeedForPlacementColliders = needPlacementColliders; ## Set the last placement collider call to the current one.
	regeneratedPieceTreeStatsThisFrame = true; ## Set the variable to true so this won't run again.
	
	reassign_body_collision(needPlacementColliders); ## allPieces also gets regenerated within this function, for both this robot as well as each piece in its socket tree.
	get_weight(true); ## Regenerates the amount of weight load on the robot, as well as for any piece on it.
	body.set_deferred("mass", max(75, min(150, get_weight() * 2))); ## Sets the mass to a value reflective of the weight load.
	has_body_piece(true); ## Checks over all the pieces to see if there's a body piece, then sets the appropriate flag.
	reinforce_piece_freeze(); ## Freezes all pieces based on current frozen status, in case any were frozen/unfrozen when they should have been.
	queue_update_hud(); ## Update the hud.
	referencesAssigned = false; ## Make it so the next time [method phys_process_pre] gets called, it looks for references again.
	assign_references(); ## ...the next time is now.
	
	## Update the body's stuff.
	body.maxSpeed = get_stat("MovementSpeedMax");
	
	regenAllHurtboxes = true; ## For some stupid reason these variables are getting UNSET without actually properly regenerating the fucking list.
	regenAllPieces = true;

## Sets up placement shapes among all pieces.
func propagate_placement_shapes(foo := true):
	for piece in allPieces:
		piece.propagate_placement_shapes(foo);

##Gives the Body new collision based on its Parts.
func reassign_body_collision(needPlacementColliders := false):
	regenAllPieces = true; ## Update the list of pieces.
	regenAllHurtboxes = true; ## Make it so the next time hurtboxes are called, they regenerate.
	
	##First, clear the Body of all collision shapes.
	for child in body.get_children(false):
		if child is PieceCollisionBox:
			child.queue_free();
	
	##Then, gather copies of every Hitbox collider from all pieces, and assign a copy of it to the Body.
	var colliderIDsInUse = [];
	for piece in allPieces:
		await piece.refresh_and_gather_collision_helpers(needPlacementColliders);
		for hurtbox in piece.get_all_hurtboxes():
			if not ((hurtbox.copiedByBody) or (hurtbox.get_collider_id() in colliderIDsInUse) or !is_instance_valid(hurtbox.originalHost)):
				colliderIDsInUse.append(hurtbox.colliderID);
				var newHurtbox = hurtbox.make_copy();
				newHurtbox.debug_color = Color("af7fff6b");
				newHurtbox.position = Vector3(0,0,0);
				newHurtbox.disabled = false;
				body.add_child(newHurtbox, true);
				newHurtbox.owner = body;
				hurtbox.copiedByBody = true;
				newHurtbox.copiedByBody = true;
	
	call_deferred("reinforce_robot_host"); ## Make sure that each piece in the tree, and all of their sockets, register this as their host.

##TODO: Reimplement movement.
#@export var topSpeed : 
@export var acceleration: float = 6000.0;
@export var maxSpeed: float = 20.0;
var movementVector := Vector2.ZERO;
var movementVectorRotation := 0.0;
var lastInputtedMV = Vector2.ZERO;
var bodyRotationAngle = Vector2.ZERO;
@export var bodyRotationSpeedBase := 0.80;
@export var bodyRotationSpeedMaxBase := 40.0;
var bodyRotationSpeed := bodyRotationSpeedBase;
@export var speedReductionWhileNoInput := 0.9; ##Slipperiness, basically.
var lastLinearVelocity : Vector3 = Vector3(0,0,0);
@export var treadsRotationSpeed : float = 6.0;
@export var treadsRotationSpeedClamp : float = 1.0;
@export var weightSpeedPenaltyMultiplier := 0.005;

##Physics process step to adjust collision box positions according to the parts they're attached to.
func phys_process_collision(delta):
	#return;
	for box in allHurtboxes:
		if is_instance_valid(box):
			var boxOrigin = box.originalBox;
			if is_instance_valid(boxOrigin):
				if boxOrigin.is_inside_tree():
					box.global_position = boxOrigin.global_position;
					box.rotation = boxOrigin.global_rotation - get_global_body_rotation() + box.originalRotation;
				else:
					box.disabled = true;
			else:
				box.queue_free();
		else:
			regenAllHurtboxes = true;

## If the robot was on the floor last frame.
var wasOnFloorLastFrame := true;
## Whether we're on the floor this frame.
var isOnFloor := false:
	get:
		return coyoteTimer > 0 or treads.onDriveable;

var coyoteTimer := 0.0;
## Steps the "coyote timer" ([member coyoteTimer])- if you're off the ground for less than five frames, the game lets you drive.
func step_coyote_timer(delta : float) -> bool:
	if coyoteTimer > 0:
		coyoteTimer -= delta;
	else:
		jolt_coyote_timer();
	
	coyoteTimer = clamp(coyoteTimer, 0.0, 0.15);
	
	return isOnFloor;

func jolt_coyote_timer(time := 0.15):
	treads.full_status_report();
	if treads.onDriveable:
		coyoteTimer = 0.15;

##Physics process step for motion.
# custom physics handling for player movement. regular movement feels flat and boring.

func phys_process_motion(delta):
	
	#return;
	if not is_frozen():
		##Calc the last velocity. 
		if !body.linear_velocity.is_equal_approx(Vector3.ZERO):
			lastLinearVelocity = body.linear_velocity;
		
		##Reset movement vector for the frame.
		movementVector = Vector2.ZERO;
	
		##If conscious, get the current movement vector.
		if is_conscious():
			movementVector = get_movement_vector(true);
	
		##Apply the current movement vector.
		#print("MV",movementVector);
		GameState.profiler_time_msec_start("robot phys_process_motion 2: Rotating + moving robot")
		move_and_rotate_towards_movement_vector(delta);
		GameState.profiler_time_msec_end("robot phys_process_motion 2: Rotating + moving robot")
		GameState.profiler_time_msec_start("robot phys_process_motion 6: Updating treads rotation")
		update_treads_rotation(delta);
		GameState.profiler_time_msec_end("robot phys_process_motion 6: Updating treads rotation")
	if is_instance_valid(treads):
		update_treads_position();
	pass;

func move_and_rotate_towards_movement_vector(delta : float):
	if is_frozen(): return;
	#print("MV2",movementVector);
	##Rotating the body mesh towards the movement vector
	var rotatedMV = movementVector.rotated(PI/2);
	
	if is_inputting_movement() and isOnFloor:
		if lastInputtedMV != movementVector: ## Only run the MV rotation if there was a change.
			lastInputtedMV = movementVector;
			var movementVectorRotated = movementVector.rotated(deg_to_rad(90.0))
			var vectorToRotTo = Vector2(movementVectorRotated.x, -movementVectorRotated.y)
			bodyRotationAngle = vectorToRotTo;
	
	## Mandatory.
	if is_in_reverse():
		bodyRotationAngle = bodyRotationAngle.rotated(deg_to_rad(180));
	
	bodyRotationSpeed = get_rotation_speed();
	
	GameState.profiler_time_msec_start("robot phys_process_motion 3: Body rotation")
	body.update_target_rotation(bodyRotationAngle, delta * bodyRotationSpeed);
	GameState.profiler_time_msec_end("robot phys_process_motion 3: Body rotation")
	
	##Get movement input.
	if is_inputting_movement():
		## Move the body.
		var accel = movementSpeedAcceleration;
		
		GameState.profiler_time_msec_start("robot phys_process_motion 4: Body rotation Euler stuff")
		var forceVector = Vector3.ZERO;
		forceVector += body.global_transform.basis.x * movementVector.x * -accel;
		forceVector += body.global_transform.basis.z * movementVector.y * -accel;
		
		var bodBasisRotationOrthonormalized := bodyBasis.orthonormalized();
		var bodBasisRotation = bodBasisRotationOrthonormalized.get_euler();
		
		GameState.profiler_time_msec_end("robot phys_process_motion 4: Body rotation Euler stuff")

		##Rotate the force vector so the body's rotation doesn't meddle with it.
		forceVector = forceVector.rotated(Vector3(0.0,1.0,0.0), float(-bodBasisRotation.y));
		GameState.profiler_time_msec_start("robot phys_process_motion 5: Body central force")
		body.apply_central_force(forceVector);
		GameState.profiler_time_msec_end("robot phys_process_motion 5: Body central force")
	else:
		if not is_frozen():
			body.linear_velocity.x *= speedReductionWhileNoInput;
			body.linear_velocity.z *= speedReductionWhileNoInput;
	
	GameState.profiler_time_msec_start("robot phys_process_motion 7: Body speed clamp")
	clamp_speed();
	GameState.profiler_time_msec_end("robot phys_process_motion 7: Body speed clamp")


func update_treads_rotation(delta : float):
	## Rotate the treads to look towards the movement vector.
	var bodMV = body.linear_velocity.normalized();
	
	if bodMV.is_equal_approx(Vector3.ZERO):
		if lastLinearVelocity.is_equal_approx(Vector3.ZERO):
			bodMV = Vector3(0,0,1).normalized();
		else:
			bodMV = lastLinearVelocity.normalized();
	var bodMV2 = Vector2(bodMV.x, bodMV.z);
	
	var bodMVA = bodMV2.angle();
	
	var prevMV = lastInputtedMV.normalized();
	if lastInputtedMV.is_equal_approx(Vector2.ZERO):
		prevMV = Vector2(0,1);
	var prevMVA = prevMV.angle();
	
	var inputMV = movementVector;
	if ! is_inputting_movement():
		inputMV = prevMV;
	inputMV.y *= -1;
	
	var inputMVA = inputMV.angle() - PI/2;
	
	var treadsMVA = treads.rotation.y;
	var treadsMV = Vector2.from_angle(treadsMVA);
	
	var angleDif = Utils.angle_difference_relative(treadsMVA, inputMVA);
	
	if angleDif > PI/2:
		angleDif -= PI;
	if angleDif < PI/-2:
		angleDif += PI;
	
	var treadsMVAlerped = lerp_angle(treadsMVA, treadsMVA + angleDif, delta * (treadsRotationSpeed + (get_current_movement_speed_length() / 5)));
	treadsMVAlerped = clamp(treadsMVAlerped, treadsMVA - treadsRotationSpeedClamp, treadsMVA + treadsRotationSpeedClamp)
	
	var angleDifFromLerp = treadsMVA - treadsMVAlerped;
	
	if !is_zero_approx(get_current_movement_speed_length()):
		treads.rotation.y = treadsMVAlerped;
	
	var angleDif3 = 0;
	
	treads.update_visuals_to_match_rotation( - angleDifFromLerp, get_current_movement_speed_length());

func update_treads_position():
	treads.global_position = get_global_body_position();

##This is empty here, but the Player and Enemy varieties of this should have things for gathering input / getting player location respectively.
func get_movement_vector(rotatedByCamera : bool = false) -> Vector2:
	var vectorOut = Vector2(0.0,0.0);
	movementVector = vectorOut;
	movementVectorRotation = movementVector.angle();
	return movementVector.normalized();

var inputtingMovementThisFrame := false; ##This should be set by AI bots before [method phys_process_motion] is called to notify whether to update their position or not this frame.
func is_inputting_movement() -> bool: ## Returns [member inputtingMovementThisFrame].
	return inputtingMovementThisFrame;
var in_reverse := false; ##@experimental: Whether the bot is 'reversing' or not. When true, [method move_and_rotate_towards_movement_vector] will rotate the target rotation 180* so the bot can move "backwards".[br][i]Note: Gets reset to false during [method phys_process_pre].[/i]
func is_in_reverse() -> bool: ##@experimental: Returns [member in_reverse].
	return in_reverse;
func put_in_reverse(): ##@experimental: Sets [member in_reverse] to true for the frame.
	in_reverse = true;
func get_current_movement_speed_length() -> float:
	return body.linear_velocity.length();

func get_rotation_speed() -> float:
	var spd = get_current_movement_speed_length();
	var mod = weightSpeedModifier;
	return min(bodyRotationSpeedBase * spd * mod, bodyRotationSpeedMaxBase);

func _on_collision(collider: PhysicsBody3D, thisComponent: PhysicsBody3D = body):
	SND.play_collision_sound(thisComponent, collider, Vector3.ZERO, 0.45)
	Hooks.OnCollision(thisComponent, collider);
	if collider.is_in_group("WorldWall"):
		print("HIT WALL")
		Hooks.OnHitWall(thisComponent);
	if collider.is_in_group("Driveable"):
		jolt_coyote_timer();

## Makes sure the bot's speed doesn't go over its max speed.
func clamp_speed():
	body.clamp_speed()
	return;

## Runs the Reset function on all collision helpers on all Pieces.
func reset_collision_helpers():
	for piece in get_all_pieces():
		piece.reset_collision_helpers();

##################################################### 3D INVENTORY STUFF

@export_category("Piece Management")
## Holds [AbilityData] resources to be fired at the press of a button input is this is a [Robot_Player], or by code elsewise.[br]There's presently only 5 slots.
var active_abilities : Dictionary[int, AbilityData] = {
	0 : null,
	1 : null,
	2 : null,
	3 : null,
	4 : null,
}

##TODO: There needs to be UI for all pieces you have active.
##TODO: DONE: - as well as pieces generally in your tree.

##Fired by a Piece when it is added to the Robot permanently.
func on_add_piece(piece:Piece):
	remove_something_from_stash(piece);
	piece.owner = self;
	if is_ready: ## Prevent the Piece from automatically adding abilities if we aren't fully initialized yet.
		for ability in piece.activeAbilitiesDistributed:
			var AD = ability.get_ability_data(piece.statHolderID)
			print("Adding ability ", ability.abilityName)
			assign_ability_to_next_active_slot(AD);
	
	queue_piece_tree_regen(false);
	pass;

## Fired by a Piece when it is removed from the Robot.
func on_remove_piece(piece:Piece):
	piece.owner = null;
	piece.hostRobot = null;
	remove_abilities_of_piece(piece);
	queue_piece_tree_regen(false);
	#deselect_everything();
	pass;

## Removes all abilities that were supplied by the given Piece.
func remove_abilities_of_piece(piece:Piece):
	for abilityKey in active_abilities:
		var ability = active_abilities[abilityKey];
		if ability is AbilityData:
			if ! is_instance_valid(piece):
				unassign_ability_slot(abilityKey, str("INVALID piece being removed, deleting the whole lot"));
			else:
				if ability.statHolderID == piece.statHolderID:
					unassign_ability_slot(abilityKey, str("piece ", piece.pieceName, " being removed"));

## A list of all Pieces attached to this Robot and which have it set as their host.
var allPieces : Array[Piece]= []:
	get:
		if regenAllPieces: ## This bool doesn't get unset until get_all_pieces_regenerate() is called.
			return get_all_pieces_regenerate();
		return allPieces;
## WHen set to [code]true[/code], [member allPieces] or [method get_all_pieces()] will call [method get_all_pieces_regenerate]
var regenAllPieces := false;
## Returns [member allPieces]. Calls [method get_all_pieces_regenerate] before returning if [member allPieces] is empty.
func get_all_pieces() -> Array[Piece]:
	if allPieces.is_empty() or regenAllPieces:
		return get_all_pieces_regenerate();
	return allPieces;

## Returns a freshly gathered array of all Pieces attached to this Robot and which have it set as their host, and Saves it to [member allPieces]. Also regenerates their host data while we're looping through them.
func get_all_pieces_regenerate() -> Array[Piece]:
	regenAllPieces = false;
	#print("regenerating piece list")
	var piecesGathered : Array[Piece] = [];
	if bodySocket.get_occupant() != null:
		bodyPiece = bodySocket.occupant;
		bodyPiece.regenAllSockets = true;
		piecesGathered = bodyPiece.get_all_pieces_recursive();
	
	allPieces = piecesGathered;
	return piecesGathered;

## UNRELATED TO [member bodyPiece]. This is whether the bot has a piece that isBody.
var hasBodyPiece := false;
## Checks over all pieces to see if any have [member Piece.isBody] as true. 
func has_body_piece(forceRecalculate := false) -> bool:
	if forceRecalculate:
		for piece in allPieces:
			if piece.isBody:
				hasBodyPiece = true;
				return true;
		hasBodyPiece = false;
		return false;
	else:
		return hasBodyPiece;

## A list of all Parts attached to this Robot within the engines all of its Parts.
var allParts : Array[Part]=[];

##Returns a freshly gathered array of all Parts placed within the engines of every Piece attached to this Robot.[br]
## Saves it to [member allParts].
func get_all_parts(equippedStatus : PieceStash.equippedStatus = PieceStash.equippedStatus.ALL) -> Array[Part]:
	if allParts.is_empty():
		return get_all_parts_regenerate();
	for part in allParts:
		if !is_instance_valid(part) or part.is_queued_for_deletion():
			return get_all_parts_regenerate();
	var partsGathered = allParts;
	match equippedStatus:
		PieceStash.equippedStatus.NONE:
			pass;
		PieceStash.equippedStatus.ALL:
			pass;
		PieceStash.equippedStatus.EQUIPPED:
			var partsOnlyEquipped : Array[Part] = []
			for part in partsGathered:
				if part.is_equipped():
					partsOnlyEquipped.append(part);
			partsGathered = partsOnlyEquipped;
			pass;
		PieceStash.equippedStatus.NOT_EQUIPPED:
			var partsOnlyNotEquipped : Array[Part] = []
			for part in partsGathered:
				if !part.is_equipped():
					partsOnlyNotEquipped.append(part);
			partsGathered = partsOnlyNotEquipped;
			pass;
	
	return partsGathered;

##Returns a freshly gathered array of all Parts attached to this Robot and whih have it set as their host.
func get_all_parts_regenerate() -> Array[Part]:
	var partsGathered : Array[Part] = [];
	for piece in allPieces:
		Utils.append_array_unique(partsGathered, piece.listOfParts);
	Utils.append_array_unique(partsGathered, stashParts);
	allParts = partsGathered;
	return partsGathered;

## When [code]true[/code], the next time [member allHurtboxes] is gotten, it returns [method get_all_gathered_hurtboxes_regenerate].
var regenAllHurtboxes := true:
	set(newVal):
		regenAllHurtboxes = newVal;
## A list of all hurtboxes attached to the body.
var allHurtboxes = []:
	get:
		if regenAllHurtboxes:
			allHurtboxes = get_all_gathered_hurtboxes_regenerate();
		return allHurtboxes;
func get_all_gathered_hurtboxes_regenerate():
	regenAllHurtboxes = false;
	var boxes = []
	for child in body.get_children():
		if child is PieceCollisionBox:
			if is_instance_valid(child):
				var boxOrigin = child.originalBox;
				if is_instance_valid(boxOrigin):
					if ! boxOrigin.is_queued_for_deletion():
						boxes.append(child)
	allHurtboxes = boxes;
	return boxes;
##Returns an array of all PieceCollisionBox nodes that are direct children of the body.
func get_all_gathered_hurtboxes():
	if allHurtboxes.is_empty() or regenAllHurtboxes:
		get_all_gathered_hurtboxes_regenerate();
	return allHurtboxes;

##Adds an AbilityData to the given slot index in active_abilities.
func assign_ability_to_slot(slotNum : int, abilityManager : AbilityData):
	unassign_ability_slot(slotNum, str("new ability ",abilityManager.abilityName," assigned to slot")); ## Unassign whatever was in the slot.
	
	if slotNum in active_abilities.keys():
		if is_instance_valid(abilityManager):
			abilityManager.assign_robot(self, slotNum);
			active_abilities[slotNum] = abilityManager;
			clear_ability_pipette();

##Turns the given slot null and unassigns this robot from that ability on the resource.
func unassign_ability_slot(slotNum : int, reason := ""):
	if slotNum in active_abilities.keys():
		if active_abilities[slotNum] is AbilityData: 
			var abilityManager = active_abilities[slotNum];
			if is_instance_valid(abilityManager):
				abilityManager.unassign_slot(slotNum);
	active_abilities[slotNum] = null;
	print_rich("[color=red][b]ABILITY IN SLOT ",slotNum," INVALID","."if reason == "" else " because of reason [ ",reason," ]");

##Runs thru active_abilities and deletes AbilityManager resources that no longer have a valid Piece or Part reference.
func check_abilities_are_valid():
	if is_ready:
		for slot in active_abilities.keys():
			var ability = active_abilities[slot];
			if ability is AbilityManager:
				var assignedPieceOrPart = ability.assignedPieceOrPart
				if !is_instance_valid(assignedPieceOrPart):
					unassign_ability_slot(slot, str("Validity check found an ability without a valid piece or part."));
				else:
					if assignedPieceOrPart is Piece:
						if !assignedPieceOrPart.is_equipped():
							unassign_ability_slot(slot, str("Validity check found piece ", assignedPieceOrPart.pieceName, " to be not equipped."));
				##TODO: Part support

##Attempts to fire the active ability in the given slot, if that slot has one.
func fire_active(slotNum) -> bool:
	check_abilities_are_valid();
	if slotNum in active_abilities.keys():
		var ability = active_abilities[slotNum];
		if ability is AbilityData:
			#print("ROBOT FIRING ABILITY ", ability.abilityName)
			return ability.call_ability();
	return false;

##Grabs the next ability slot that is currently null.
func get_next_available_active_slot():
	check_abilities_are_valid();
	var allKeys = active_abilities.keys().duplicate(true);
	while allKeys.size() > 0:
		var slotNum = allKeys.pop_front();
		var ability = active_abilities[slotNum];
		if ability == null:
			return slotNum;
	return null;

##Assigns an ability to the next available slot, if there are any.
func assign_ability_to_next_active_slot(abilityManager : AbilityData):
	var slot = get_next_available_active_slot();
	if slot == null: return;
	assign_ability_to_slot(slot, abilityManager);

var abilityPipette : AbilityData;
## Gets the currently selected ability.
func get_ability_pipette() -> AbilityData:
	if abilityPipette != null and abilityPipette is AbilityData:
		return abilityPipette;
	return null;

func clear_ability_pipette():
	var pip = get_ability_pipette()
	if pip != null and is_instance_valid(pip):
		abilityPipette.deselect();
	abilityPipette = null;

func set_ability_pipette(new : AbilityData):
	var assignedThing = new.assignedPieceOrPart;
	if assignedThing is Piece:
		if ! assignedThing.assignedToSocket:
			clear_ability_pipette();
			return;
		pass;
	var cur = get_ability_pipette();
	if cur != null:
		clear_ability_pipette();
	abilityPipette = new;
	abilityPipette.select();

########################## SELECTION

var selectedPiece : Piece;
var selectedPieceQueue : Piece; ##@deprecated
var selectedPart : Part;

func is_piece_selected() -> bool:
	return is_instance_valid(selectedPiece);
func is_pipette_loaded() -> bool:
	return is_instance_valid(pipettePieceInstance) or is_instance_valid(pipettePartInstance);

func get_selected_for_inspector():
	if is_selected():
		return self;
	return get_selected_or_pipette();

## Returns what's selected, or what's in the pipette. Returns [code]null[/code] elsewise.[br]Priority is [member pipettePartPath] > [member pipettePiecePath] > [member selectedPart] > [member selectedPiece] > [code]null[/code].
func get_selected_or_pipette(ignoreParts := false):
	var pipette = get_current_pipette();
	if is_instance_valid(pipette):
		return pipette;
	var selected = get_selected(ignoreParts);
	if is_instance_valid(selected):
		return selected;
	return null;

## Returns what's selected. Returns [code]null[/code] if it's invalid.[br]Priority is [member selectedPart] > [member selectedPiece] > [code]null[/code].
func get_selected(ignoreParts := false):
	if ! ignoreParts:
		if is_instance_valid(get_selected_part()):
			return selectedPart;
	var selPiece = get_selected_piece();
	if is_instance_valid(selPiece):
		return selPiece;
	return null;

func get_selected_piece(mustBeInTree := false)->Piece:
	if is_instance_valid(selectedPiece):
		## If the "selected piece" is not selected, then select it.
		if !selectedPiece.selected:
			selectedPiece.select(true);
		
		## If selectedPiece is inside the tree, or is not but we aren't checking, then continue
		var go = ! mustBeInTree;
		if mustBeInTree:
			if selectedPiece.is_inside_tree():
				go = true;
		
		
		if go:
			## If the thing is in the shop, we have to be in state SHOP for it to remain selected.
			if selectedPiece.inShop:
				if GameState.get_in_one_of_given_states([GameBoard.gameState.SHOP]):
					return selectedPiece;
				else:
					deselect_piece(selectedPiece);
			else:
				return selectedPiece;
	return null;

## Deselects based on a predetermined hierarchy.[br]
## Ability > Pipette > Part > Piece;
func deselect_in_hierarchy():
	queue_update_hud();
	if selected:
		select(false);
		return;
	if partMovementPipette != null:
		clear_move_mode_pipette();
		return;
	if abilityPipette != null:
		clear_ability_pipette();
		return;
	if get_current_pipette() != null:
		unreference_pipette();
		return;
	var selectionResult = get_selected();
	if selectionResult != null:
		if selectionResult is Part:
			print("Deselecti in hierarchy is deselecting part")
			selectionResult.deselect();
			deselect_all_parts();
			return;
		if selectionResult is Piece:
			selectionResult.deselect();
			deselect_all_pieces();
			return;
	deselect_everything();

func deselect_everything():
	unreference_pipette();
	deselect_all_pieces();
	deselect();

func deselect_all_pieces(ignoredPiece : Piece = null):
	unreference_pipette();
	for piece in get_all_pieces():
		GameState.profiler_ping_create("Deselecting a Piece via Robot.deselect_all_pieces")
		if ignoredPiece == null or piece != ignoredPiece:
			if piece.get_selected():
				piece.deselect();
	if ignoredPiece == null or selectedPiece != ignoredPiece:
		selectedPiece = null;
	
	queue_update_hud();
	pass;

## Force-deselects one specific piece.
func deselect_piece(piece:Piece):
	if piece == selectedPiece:
		deselect_all_pieces();
	else:
		piece.deselect();

## Runs [member Piece.select] and then acts on the result.
func select_piece(piece : Piece, forcedValue = null):
	if (is_instance_valid(piece) 
	#)and (piece in allPieces
	):
		if piece != selectedPiece:
			if is_instance_valid(selectedPiece):
				selectedPiece.deselect();
		
		var result = false;
		if forcedValue != null:
			result = piece.select(forcedValue);
		else:
			result = piece.select();
		
		if result:
			deselect();
			
			print("Selected Piece: ", selectedPiece)
			deselect_all_pieces(piece);
			
			selectedPiece = piece;
			update_hud();
			return piece;
		else:
			deselect_all_pieces();
			selectedPiece = null;
	return null;

## Deselects all [Part]s in all [Pieces] on this bot, as well as [member selectedPart]. If [param ignoredPart] is set to a [Part], then it will try not to deselect it.
func deselect_all_parts(ignoredPart : Part = null):
	#print("Deselecting all parts except ", ignoredPart)
	
	if ignoredPart == null or ignoredPart != selectedPart:
		if is_instance_valid(selectedPart):
			#print("Selected Part deselected: ", selectedPart)
			select_part(selectedPart, false, false);
	for part in get_all_parts():
		if ignoredPart == null or part != ignoredPart:
			#print("Part deselected: ", part)
			part.select(false);
	
	queue_update_hud();

## Sets the given [Part] as "selected," even if it is not inside the player's ecosystem.
func select_part(part : Part, foo: bool= true, deselectAllElse := true):
	if is_instance_valid(part):
		if deselectAllElse:
			#print("Calling deselect_all_parts from select_part")
			deselect_all_parts(part)
		#print("Calling part.select on ", part, " with foo ", foo)
		part.select(foo);
		if foo:
			#print("Setting selected part: ", part)
			selectedPart = part;
			update_hud();
			return part;
		else:
			#print("Setting selected part to null")
			selectedPart = null;
			update_hud();
	return null;

## Force-deselects one specific piece.
func deselect_part(part:Part):
	if part == selectedPart:
		deselect_all_parts();
	else:
		part.deselect();

## Gets [member selectedPart] or null.
func get_selected_part():
	if is_instance_valid(selectedPart):
		if !selectedPart.selected:
			selectedPart.select(true);
		return selectedPart;
	return null;

############# PARTS
var buyMode := false; ## If in "buy" mode (enabled/dsiabled with [method part_buy_mode_enable] ), then the player can place a Part selectd fromm the shop into the engine of one of their Pieces, similarly to being in [member moveMode].[br]
## After placing into an engine or hitting the Stash button, then Scrap will leave your bank account.
func part_buy_mode_enable(foo:bool):
	pass;

var moveMode := false; ## If in "move" mode (enabled/dsiabled with [method part_move_mode_enable] ), then the player can move Parts between different bits of their bot, throughout the different Pieces.
var partMovementPipette : Part = null;
func part_move_mode_enable(part:Part, foo:bool):
	moveMode = foo;
	clear_move_mode_pipette();
	if foo:
		part.move_mode(true);
		partMovementPipette = part;
	else:
		pass;
	queue_update_engine_button_gfx();
	pass;

func clear_move_mode_pipette():
	if is_instance_valid(partMovementPipette):
		partMovementPipette.move_mode(false);
		partMovementPipette = null;


######################## STASH

func stash_selected_piece(fancy := false):
	if is_instance_valid(selectedPiece):
		print("Attempting to stash ", selectedPiece)
		if selectedPiece.removable:
			selectedPiece.remove_and_add_to_robot_stash(self, fancy);
	regenAllPieces = true;

##TODO: Parts and Engine bs.
func stash_selected_part():
	if is_instance_valid(selectedPart):
		print("Attempting to stash ", selectedPart)
		if selectedPiece.removable:
			selectedPiece.remove_and_add_to_robot_stash(self);
	get_all_parts_regenerate();
