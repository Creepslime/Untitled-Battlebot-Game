@icon ("res://graphics/images/class_icons/robot_player.png")
extends Robot

class_name Robot_Player
##It's you![br]Still untitled.

var gameHUD : GameHUD;
var barHP : HealthBar;
var barEnergy : HealthBar;
@export var roundTimeRegen := 30.0;

func _ready():
	super();

func stat_registry():
	super();
	register_stat("RoundTimeRegen", roundTimeRegen, StatHolderManager.statIconCooldown, StatHolderManager.statTags.Clock);

func assign_references(forceTemp := false):
	if referencesAssigned: return;
	super(forceTemp);
	if !is_instance_valid(gameHUD):
		gameHUD = GameState.get_game_hud();
	if is_instance_valid(gameHUD):
		if !is_instance_valid(barHP):
			barHP = GameState.get_bar_hp();
		if !is_instance_valid(barEnergy):
			barEnergy = GameState.get_bar_energy();
		if !is_instance_valid(engineViewer):
			engineViewer = GameState.get_engine_viewer();


func is_conscious():
	return super() and hasPlayerControl;


######################## INPUT MANAGEMENT

func _physics_process(delta):
	super(delta)
func _process(delta):
	super(delta)
	update_bars(); ##Bars should be updated at the very end.

func process_timers(delta):
	super(delta);
	forcedUpdateTimerHUD -= 1;
	if forcedUpdateTimerHUD <= 0:
		forcedUpdateTimerHUD = 20;
		update_hud();

func phys_process_combat(delta):
	super(delta);
	if Input.is_action_pressed("Fire0"):
		if fire_active(0):
			print("Ability 1? ",active_abilities[0].manager.abilityName)
	if Input.is_action_pressed("Fire1"):
		if fire_active(1):
			print("Ability 2? ",active_abilities[1].manager.abilityName)
	if Input.is_action_pressed("Fire2"):
		if fire_active(2):
			print("Ability 3? ",active_abilities[2].manager.abilityName)
	if Input.is_action_pressed("Fire3"):
		if fire_active(3):
			print("Ability 4? ",active_abilities[3].manager.abilityName)
	if Input.is_action_just_pressed("Fire4"):
		if fire_active(4):
			print("Ability 5? ",active_abilities[4].manager.abilityName)

func get_movement_vector(rotatedByCamera : bool = true) -> Vector2:
	movementVector = Vector2.ZERO
		
	if Input.is_action_pressed("MoveLeft"):
		movementVector += Vector2.LEFT;
		
	if Input.is_action_pressed("MoveRight"):
		movementVector += Vector2.RIGHT;
		
	if Input.is_action_pressed("MoveUp"):
		movementVector += Vector2.UP;
		
	if Input.is_action_pressed("MoveDown"):
		movementVector += Vector2.DOWN;
	
	if is_instance_valid(camera):
		if rotatedByCamera:
		
			var camRotY = - camera.targetRotationY;
			
			movementVector = movementVector.rotated(camRotY);
	else:
		camera = GameState.get_camera();
	
	if is_inputting_movement():
		movementVectorRotation = movementVector.angle();
	return movementVector.normalized();

var hasPlayerControl := false;
func is_inputting_movement() -> bool:
	inputtingMovementThisFrame = false;
	#print("ASDASDASD")
	if GameState.get_in_state_of_play() and is_conscious() and hasPlayerControl:
		if Input.is_action_pressed("MoveLeft"):
			inputtingMovementThisFrame = true;
			return inputtingMovementThisFrame;
			
		if Input.is_action_pressed("MoveRight"):
			inputtingMovementThisFrame = true;
			return inputtingMovementThisFrame;
			
		if Input.is_action_pressed("MoveUp"):
			inputtingMovementThisFrame = true;
			return inputtingMovementThisFrame;
			
		if Input.is_action_pressed("MoveDown"):
			inputtingMovementThisFrame = true;
			return inputtingMovementThisFrame;
	
	return inputtingMovementThisFrame;

func die():
	#gameBoard.game_over();
	#super();
	#return;
	if is_alive() and aliveLastFrame:
		#Hooks.OnDeath(self, GameState.get_player()); ##TODO: Fix hooks to use new systems before uncommenting this.
		alive = false;
		hide();
		freeze(true, true);
		gameBoard.game_over();
		
		##Play the death sound
		if GameState.get_in_state_of_play() or GameState.get_in_state_of_game_over():
			#SND.play_sound_nondirectional(deathSound);
			SND.play_sound_nondirectional("Combatant.Die");
		##Play the death particle effects.
		ParticleFX.play("NutsBolts", GameState.get_game_board(), get_global_body_position());
		ParticleFX.play("BigBoom", GameState.get_game_board(), get_global_body_position());
		
	#print("Searching for Sockets ", Utils.get_all_children("Piece getting all sockets on death",self).size())
	#print("Searching for Sockets, checking ownership ", Utils.get_all_children("Piece getting all sockets on death, checking ownership",self, self).size())
	#print(Utils.get_all_children("Piece getting all children on death",self, self))

##Fired by the gameboard when the round starts.
func start_round():
	super();
	enable_player_control(true);
##Fired by the gameboard when the round ends.
func end_round():
	super();
	enable_player_control(false);
	GameState.add_death_time(get_stat("RoundTimeRegen"));

##Fired by the gameboard when the shop gets opened.
func enter_shop():
	drain_all_energy();
	super();
	enable_player_control(false);
	pass;
##Fired by the gameboard when the shop gets opened.
func enter_shop_build():
	drain_all_energy();
	enable_player_control(false);
	pass;
##Fired by the gameboard when the shop gets opened.
func enter_shop_test():
	drain_all_energy();
	enable_player_control(true);
	pass;
##Fired by the gameboard when the shop gets closed.
func exit_shop():
	super();
	enable_player_control(false);
	pass;

func enable_player_control(foo:bool):
	hasPlayerControl = foo;

#################### COMBAT HANDLING

func update_bars():
	if is_instance_valid(barHP) and is_instance_valid(barEnergy):
		var currentHealth = get_health();
		var currentHealthMax = get_max_health();
		#print(currentHealth);
		barHP.set_health(currentHealth, currentHealthMax);
		barHP.set_alt_color(invincible);
		var currentEnergy = get_available_energy();
		#print("BARS UPDATE, CURRENT ENERGY: ", currentEnergy)
		var currentEnergyMax = get_max_energy();
		barEnergy.set_health(currentEnergy, currentEnergyMax);

func _on_health_or_energy_changed():
	super();
	update_bars();
	pass # Replace with function body
