extends Node3D

class_name GameBoard;

@export var playerSpawnPosition : Vector3;
@export var enemySpawnPositions : Node3D;
@export var enemySpawnList := {};
#@onready var playerScene = preload("res://scenes/prefabs/objects/player.tscn");
@onready var playerScene = preload("res://scenes/prefabs/objects/robots/robot_player.tscn");
@export var spawnChecker : ShapeCast3D;
var spawnTimer := 0.0;
var spawnPool := [];
var waveSpawnList := [];
var waveTimer := 0.0;
var wave := 0;
var roundEnemiesInit := 1;
var roundEnemies := 0;
var roundNum := 0;
var enemiesAlive = [];
var enemiesSpawned = [];
var enemiesDead = [];
var player : Robot_Player;

var enemiesKilled := 0;
var scrapGained := 0;

var scrapCount := 0; ## @depreated: See [ScrapManager].


@export_subgroup("HUD nodes")
#@export var HUD_playerStats : Control;
@export var HUD_mainMenu : Control;
@export var HUD_credits : Control;
@export var HUD_options : Control;
@export var HUD_gameOver : Control;
@export var HUD_player : Control;
@export var MUSIC : MusicHandler;
@export var LIGHT : DirectionalLight3D;
@export var CANVAS_HUD : CanvasLayer;
@export var CANVAS_GAMECAMERA : CanvasLayer;

@export var CANVAS_SHOP : CanvasLayer;
@export var HUD_shopTabs : ShopPanel;
@export var HUD_shopManager : ShopManager;

##Camera stuff
## Main game camera.
@export_subgroup("Cameras")
@export var gameCamera : GameCamera;
func get_main_camera():
	return gameCamera;
@export var followerCamera : FollowerCamera;
@export var backupCamPointer : Node3D;
func get_camera_pointer() -> Node3D:
	if player != null and is_instance_valid(player):
		if in_state_of_building():
			var selected = player.get_selected_piece();
			if is_instance_valid(selected) and selected.is_inside_tree():
				return selected;
		return player.body;
	else:
		return backupCamPointer;
func change_backup_cam_pos_to_current_arena():
	if is_instance_valid(currentArena):
		var pos = currentArena.fallbackCameraPosition;
		backupCamPointer.global_position = currentArena.fallbackCameraPosition;

#@export var bi
func _ready():
	get_tree().current_scene.ready.connect(_on_scenetree_ready);
	
	#return_random_spawn_location()
func _on_scenetree_ready():
	
	Hooks.add(self, "OnDeath", "LifetimeKillCounter", 
		func(thisBot, killer):
			Utils.append_unique(enemiesDead, thisBot);
			if is_instance_valid(killer) and killer is Robot_Player:
				enemiesKilled += 1;
				#print_rich("[color=red][b]Enemies killed: ",enemiesKilled)
			)
			
	Hooks.add(self, "OnGainScrap", "LifetimeScrapCounter", 
		func(source, amt):
			if amt > 0:
				scrapGained += amt;
				#print_rich("[color=yellow][b]Scrap gained: ",scrapGained)
			)
	
	arena_move_master("Workshop", "Base", "Base", cacheOpt.OVERWRITE_OLD_AND_SET_INPUT_CURRENT);
	
	change_state(gameState.SPLASH);
	

func _process(delta):
	process_state(delta, curState);

################### STATE CONTROL

##Controls the state of the game.
enum gameState {
	START, ## Initial value set on startup.
	INVALID, ## Invalid value. Returned by [GameState.get_game_board_state()] when the game board is invalid.
	MAKER, ## Invalid value. Returned by [GameState.get_game_board_state()] when the dev editor is open.
	QUEUE_EMPTY, ## Invalid value. Denotes an empty queue as used by [member queuedRightTransitionState] and [member queuedCenterTransitionState].
	SPLASH, ## The splash screen when the software first opens.
	MAIN_MENU, ## Main menu.
	INIT_NEW_GAME, ## The start of a new game.
	INIT_ROUND, ## Round setup happens. Timers are reset, the enemy pool for the round is decided and then frontloaded, then after the game stops lagging we move on to LOAD_ROUND.
	LOAD_ROUND, ## Screen transition from INIT_ROUND. Goes to PLAY when the transition leaves.
	PLAY, ## Main combat game loop. Pew pew slice slice and all that.
	GAME_OVER, ## YOU HAVE DIED... or you hit "end run" on the pause menu.
	CREDITS, ## Credits screen.
	OPTIONS, ## Options screen as accessed by the main menu. 
	GOTO_SHOP, ## Screen transition to INIT_SHOP. Caching!
	INIT_SHOP, ## Start up shop data. Load up the screen transition.
	LOAD_SHOP, ## Screen transition from INIT_SHOP. Goes to SHOP when the transition leaves.
	SHOP, ## Shopping state. The UI for the shop is open. Time to spend money!
	SHOP_TEST, ## Shopping state. The UI for the shop is closed. The player is able to modify the placements of Pieces and Partss on their bot with special camera control.
	SHOP_BUILD, ## Shopping state. The UI for the shop is closed. The player is aable to drive around and fire their weapons. Certain pieces should behave differently if they interact with Scrap.
	LEAVE_SHOP, ## We're exiting whatever shopping state we were in with a screen transition. Goes to INIT_ROUND when the transition arrives.
}
var curState := gameState.START;

##@deprecated
const play_states = [
	GameBoard.gameState.INIT_ROUND,
	GameBoard.gameState.LOAD_ROUND,
	GameBoard.gameState.PLAY,
	GameBoard.gameState.GOTO_SHOP,
	GameBoard.gameState.INIT_SHOP,
	GameBoard.gameState.LOAD_SHOP,
	GameBoard.gameState.SHOP_TEST,
	GameBoard.gameState.SHOP,
	GameBoard.gameState.SHOP_BUILD,
	GameBoard.gameState.LEAVE_SHOP,
]

##returns true if we're in a state that might be considered a part of the game loop.
func in_state_of_play(includeLoading := true)->bool:
	return in_state_of_combat(includeLoading) or in_state_of_shopping(includeLoading);

const combat_states = [
	GameBoard.gameState.PLAY,
]
const combat_load_states = [
	GameBoard.gameState.INIT_ROUND,
	GameBoard.gameState.LOAD_ROUND,
]
const combat_test_states = [
	GameBoard.gameState.SHOP_TEST,
]
##returns true if we're in a state where the player is being controlled.
func in_state_of_combat(includeLoading := false, includeTesting := false)->bool:
	if includeLoading:
		if includeTesting: return in_one_of_given_states(combat_states) or in_one_of_given_states(combat_load_states) or in_one_of_given_states(combat_test_states);
		return in_one_of_given_states(combat_states) or in_one_of_given_states(combat_load_states);
	if includeTesting: return in_one_of_given_states(combat_states) or in_one_of_given_states(combat_test_states);
	return in_one_of_given_states(combat_states);

const shop_states = [
	GameBoard.gameState.SHOP_TEST,
	GameBoard.gameState.SHOP,
	GameBoard.gameState.SHOP_BUILD,
]
const building_states = [
	#GameBoard.gameState.SHOP,
	GameBoard.gameState.SHOP_BUILD,
]
const shop_load_states = [
	GameBoard.gameState.GOTO_SHOP,
	GameBoard.gameState.INIT_SHOP,
	GameBoard.gameState.LOAD_SHOP,
	GameBoard.gameState.LEAVE_SHOP,
]
##returns true if we're in the shop.
func in_state_of_shopping(includeLoading := false)->bool:
	if includeLoading:
		return in_one_of_given_states(shop_states) or in_one_of_given_states(shop_load_states);
	return in_one_of_given_states(shop_states);
##Returns true if we're in a state where build-a-bot mode is activated.
func in_state_of_building()->bool:
	return in_one_of_given_states(building_states);

const camera_tilt_states = [
	GameBoard.gameState.PLAY,
	GameBoard.gameState.SHOP_TEST,
	GameBoard.gameState.SHOP,
	GameBoard.gameState.SHOP_BUILD,
]
const game_over_states = [
	GameBoard.gameState.PLAY,
	GameBoard.gameState.SHOP,
	GameBoard.gameState.SHOP_TEST,
	GameBoard.gameState.SHOP_BUILD,
]
func in_game_over_state()->bool:
	return in_one_of_given_states(game_over_states) and player.aliveLastFrame;
const loading_states = [
	GameBoard.gameState.INIT_ROUND,
	GameBoard.gameState.INIT_SHOP
]
func in_state_of_loading() -> bool:
	return in_one_of_given_states(loading_states);

func in_one_of_given_states(states:Array)->bool:
	var currentState = GameState.get_game_board_state();
	return currentState in states;



func change_state(newState : gameState):
	var changeToDefer = func change(newState):
		if curState != newState:
			exit_state(curState);
			var oldState = curState;
			Hooks.OnChangeGameState(curState, newState);
			curState = newState;
			enter_state(newState, oldState);
	changeToDefer.call_deferred(newState);

func exit_state(oldState:gameState):
	match oldState:
		gameState.SPLASH:
			MUSIC.play();
			GameState.make_screen_transition_leave();
		gameState.MAIN_MENU:
			HUD_mainMenu.hide();
			pass
		gameState.GAME_OVER:
			#HUD_playerStats.hide();
			HUD_gameOver.hide();
			pass
		gameState.CREDITS:
			HUD_credits.hide();
			pass
		gameState.OPTIONS:
			HUD_options.open_sesame(false);
			pass
		gameState.PLAY:
			pass
		gameState.SHOP:
			pass
		gameState.SHOP_TEST:
			pass
		gameState.SHOP_BUILD:
			pass
		gameState.LEAVE_SHOP:
			HUD_shopTabs.open = false;
			CANVAS_SHOP.hide();
			move_out_of_workshop();
			pass
		gameState.INIT_ROUND:
			pass
		gameState.START:
			HUD_shopTabs.open = false;
			CANVAS_SHOP.hide();
			HUD_mainMenu.hide();
			HUD_credits.hide();
			HUD_gameOver.hide();
			HUD_options.open_sesame(false);
			update_lighting();
			HUD_options.load_settings();
			pass

func enter_state(_newState:gameState, _oldState:gameState):
	#print("ENTERING STATE ",var_to_str(gameState.keys()[_newState]));
	match _newState:
		gameState.SPLASH:
			GameState.init_screen_transition_vanity();
		gameState.MAIN_MENU:
			queuedShopLeave = false;
			HUD_shopTabs.open = false;
			CANVAS_SHOP.hide();
			HUD_shopManager.close_up_shop();
			MUSIC.change_state(MusicHandler.musState.MENU);
			ScrapManager.remove_scrap(999999, "Game End");
			destroy_all_enemies(true);
			player = null;
			HUD_mainMenu.show();
			roundNum = 0;
			pass
		gameState.GAME_OVER:
			HUD_shopManager.close_up_shop();
			
			MUSIC.change_state(MusicHandler.musState.GAME_OVER);
			
			HUD_gameOver.show();
			pass
		gameState.CREDITS:
			MUSIC.change_state(MusicHandler.musState.CREDITS);
			
			HUD_credits.show();
			pass
		gameState.OPTIONS:
			MUSIC.change_state(MusicHandler.musState.OPTIONS);
			
			HUD_options.open_sesame(true);
			pass
		gameState.INIT_NEW_GAME:
			MUSIC.change_state(MusicHandler.musState.PREGAME);
			var startingScrapAmount = GameState.get_setting("startingScrap")
			ScrapManager.set_scrap(startingScrapAmount);
			HUD_shopManager.reset_shop();
			
			GameState.start_death_timer(120.0,true)
			
			roundNum = 0;
			roundEnemiesInit = 1;
			clear_enemy_spawn_list();
			scrapGained = 0;
			enemiesKilled = 0;
			player = null;
			
			queue_center_transition_state(gameState.INIT_ROUND, 3)
			pass
		gameState.INIT_ROUND:
			MUSIC.change_state(MusicHandler.musState.PREGAME);
			destroy_all_enemies(false);
			
			queuedShopLeave = false; ## Necessary setup.
			
			roundNum += 1;
			set_enemy_spawn_waves(roundNum);
			waveTimer = 3;
			wave = 0;
			roundEnemiesInit += 2;
			roundEnemies = roundEnemiesInit;
			enemiesSpawned.clear();
			enemiesDead.clear();
			
			new_round_arena_sequence();
			
			pass
		gameState.LOAD_ROUND:
			call_screen_transition_out();
		gameState.PLAY:
			player.start_round();
			pass
		gameState.GOTO_SHOP:
			MUSIC.change_state(MusicHandler.musState.PREGAME);
			
			player.end_round();
			
			call_screen_transition_in();
		gameState.INIT_SHOP:
			HUD_shopTabs.change_tab(0);
			CANVAS_SHOP.show();
			##TODO: Reimplementation of shop logic.
			
			move_player_to_workshop();
		gameState.LOAD_SHOP:
			HUD_shopTabs.open = true;
			MUSIC.change_state(MusicHandler.musState.SHOP);
			
			call_screen_transition_out();
			pass;
		gameState.SHOP:
			if GameState.screenTransition.is_on_center():
				call_screen_transition_out();
			
			MUSIC.change_state(MusicHandler.musState.SHOP);
			CANVAS_SHOP.show();
			HUD_shopManager.open_up_shop();
			player.enter_shop();
			##TODO: SHOP UI LOGIC
			##TODO: BUILD MODE / TEST MODE SWITCHING LOGIC
			pass
		gameState.SHOP_BUILD:
			if GameState.screenTransition.is_on_center():
				call_screen_transition_out();
			
			MUSIC.change_state(MusicHandler.musState.SHOP_BUILD);
			CANVAS_SHOP.hide();
			player.enter_shop_build();
			respawn_player();
			##TODO: SHOP UI LOGIC
			##TODO: BUILD MODE / TEST MODE SWITCHING LOGIC
			pass
		gameState.SHOP_TEST:
			if GameState.screenTransition.is_on_center():
				call_screen_transition_out();
			
			MUSIC.change_state(MusicHandler.musState.SHOP_TEST);
			CANVAS_SHOP.hide();
			player.enter_shop_test();
			##TODO: SHOP UI LOGIC
			##TODO: BUILD MODE / TEST MODE SWITCHING LOGIC
			pass
		gameState.LEAVE_SHOP:
			HUD_shopTabs.open = false;
			player.exit_shop();
			queue_center_transition_state(gameState.INIT_ROUND, 3)


func new_round_arena_sequence():
	if roundNum == 1:
		move_to_random_biome_and_arena();
		arena_move_master("RANDOM", "RANDOM", "RANDOM", cacheOpt.CACHE_OLD_AND_SET_INPUT_CURRENT);
	else:
		arena_move_master("CURRENT", "NEW", "NEW", cacheOpt.CACHE_OLD_AND_SET_INPUT_CURRENT);
	##TODO: Move enemies down here and have the frames to wait be max between that and obstacles.

var queuedShopLeave := false;
func queue_shop_exit():
	HUD_shopManager.close_up_shop();
	queuedShopLeave = true;

var splashTimer := 5.5;
var initArenaFrameWait := 0;
var lightingUpdateTimer := 0;
func process_state(delta : float, _state : gameState):
	lightingUpdateTimer -= 1;
	if lightingUpdateTimer < 0:
		update_lighting();
		lightingUpdateTimer = 15;
	
	if awaitingScreenTransition:
		ping_screen_transition_result();
	
	match curState:
		gameState.SPLASH:
			splashTimer -= delta;
			if splashTimer < 0 or  GameState.is_fire_action_being_pressed():
				change_state(gameState.MAIN_MENU);
			pass
		gameState.MAIN_MENU:
			pass
		gameState.GAME_OVER:
			pass
		gameState.CREDITS:
			pass
		gameState.PLAY:
			if GameState.get_setting("killAllKey") and Input.is_action_just_pressed("DBG_KillAll"):
				destroy_all_enemies()
			
			if not GameState.is_paused():
				waveTimer -= delta;
				spawnTimer -= delta;
			
			if roundEnemies > 0:
				if waveTimer <= 0:
					waveTimer = 10;
					wave += 1;
					var amtAlive = check_alive_enemies()
					#print("alive: ", amtAlive)
					var amtToSpawn = max(0, min(3+roundNum,10,roundEnemies))
					#var amtToSpawn = max(0, min(1, 1 - amtAlive))
					#print(amtToSpawn, amtAlive)
					spawn_wave(amtToSpawn)
					MUSIC.change_state(MusicHandler.musState.BATTLING);
			
			if spawnTimer <= 0:
				spawn_enemy_from_wave();
				
				if get_enemies_left_for_wave() <= 0:
					change_state(gameState.GOTO_SHOP);
				else:
					spawnTimer=0.15;
			
			if Input.is_action_just_pressed("dbg_SpawnEnemy"):
				spawn_single_random_enemy();
			
			pass
		gameState.INIT_SHOP:
			if wait_for_arena_to_build_and_respawn_to_happen():
				change_state(gameState.LOAD_SHOP);
			pass
		gameState.LOAD_SHOP:
			pass;
		gameState.GOTO_SHOP:
			pass
		gameState.SHOP:
			pass
		gameState.INIT_ROUND:
			if wait_for_arena_to_build_and_respawn_to_happen():
				change_state(gameState.LOAD_ROUND);
			pass
		gameState.LOAD_ROUND:
			pass;
		gameState.LEAVE_SHOP:
			pass;
	pass

var awaitingScreenTransition := false; ## If set to true, then [method ping_screen_transition_result] will be called every frame until [method screen_transition] is called from [GameState].
## Pings the [ScreenTransition] to try to coax a result out of it.
func ping_screen_transition_result():
	GameState.ping_screen_transition();
## At the end of the frame, makes the screen transition leave and sets [member awaitingScreenTransition] to true.
func call_screen_transition_in(transitionLayer := 3):
	GameState.call_deferred("make_screen_transition_arrive", transitionLayer);
	set_deferred("awaitingScreenTransition", true);
## At the end of the frame, makes the screen transition leave and sets [member awaitingScreenTransition] to true.
func call_screen_transition_out():
	GameState.call_deferred("make_screen_transition_leave");
	set_deferred("awaitingScreenTransition", true);

var queuedRightTransitionState := gameState.QUEUE_EMPTY;
var queuedCenterTransitionState := gameState.QUEUE_EMPTY;
var queuedCenterTransitionForceLeave := false;
func screen_transition(scr_state : ScreenTransition.mode):
	match scr_state:
		ScreenTransition.mode.RIGHT:
			awaitingScreenTransition = false; ## Stop waiting for the transition.
			
			## Handle state-specfic transitions.
			match curState:
				gameState.LOAD_ROUND:
					if is_instance_valid(player):
						change_state(gameState.PLAY);
				gameState.LOAD_SHOP:
					change_state(gameState.SHOP);
			
			if queuedRightTransitionState != gameState.QUEUE_EMPTY:
				change_state(queuedRightTransitionState);
				queuedRightTransitionState = gameState.QUEUE_EMPTY;
			
		ScreenTransition.mode.CENTER:
			awaitingScreenTransition = false; ## Stop waiting for the transition.
			
			## Handle state-specfic transitions.
			match curState:
				gameState.INIT_NEW_GAME:
					change_state(gameState.INIT_ROUND);
				gameState.GOTO_SHOP:
					change_state(gameState.INIT_SHOP);
				gameState.LEAVE_SHOP:
					change_state(gameState.INIT_ROUND);
			
			if queuedCenterTransitionState != gameState.QUEUE_EMPTY:
				change_state(queuedCenterTransitionState);
				queuedCenterTransitionState = gameState.QUEUE_EMPTY;
				if queuedCenterTransitionForceLeave:
					call_screen_transition_out();
			pass;

## Sets a state to be called when the screen transition shows up, then makes it show up.
func queue_center_transition_state(state := gameState.QUEUE_EMPTY, layer := 3, instantLeave := false):
	queuedCenterTransitionState = state;
	queuedCenterTransitionForceLeave = instantLeave;
	call_screen_transition_in(layer);

## Sets a state to be called when the screen transition leaves, then makes it leave.
func queue_right_transition_state(state := gameState.QUEUE_EMPTY):
	queuedRightTransitionState = state;
	call_screen_transition_out();

func wait_for_arena_to_build_and_respawn_to_happen() -> bool:
	var respawnResult = false;
	if !is_instance_valid(currentArena):
		initArenaFrameWait += 1;
	else:
		if is_instance_valid(currentArena.obstaclesNode):
			if currentArena.obstaclesNode.cells.size() > 0:
				initArenaFrameWait = max(initArenaFrameWait, currentArena.obstaclesNode.cells.size());
	
	if initArenaFrameWait >= 0:
		#print_rich("[color=grey]STATE: WAITING FOR ", initArenaFrameWait, " MORE FRAMES FOR ARENA TO LOAD");
		initArenaFrameWait -= 1;
	else:
		#print_rich("[color=grey]STATE: WAITING ON PLAYER TO SPAWN.");
		respawnResult = spawn_or_respawn_player();
	
	return respawnResult;

func update_lighting():
	LIGHT.shadow_enabled = GameState.get_setting("renderShadows");

################################# ARENAS
@export_subgroup("Arena stuff")
@export var biomes : Dictionary[String,BiomeData] = {}
var currentArena : Arena;
@export var currentBiome : BiomeData;
var currentBiomeName : String = "None";

enum cacheOpt {
	OVERWRITE_OLD_AND_SET_INPUT_CURRENT,
	CACHE_OLD_AND_SET_INPUT_CURRENT,
	CLEAR_CACHE_AND_SET_INPUT_CURRENT,
	CACHE_INPUT,
	CACHE_INPUT_AND_SET_OLD_CACHE_CURRENT,
}
## Moves you to the given biome, arena, and variant. Very flexible. Returns the amount of frames to wait for building.
func arena_move_master(inBiome : Variant = "Random", inArena : Variant = "Random", inVariant : Variant = "Random", cacheMode : cacheOpt = cacheOpt.OVERWRITE_OLD_AND_SET_INPUT_CURRENT):
	## If we're meant to cache the old stuff, do that here.
	if cacheMode == cacheOpt.CACHE_OLD_AND_SET_INPUT_CURRENT:
		clear_cache();
		cache_current_arena();
		cache_current_biome();
	elif cacheMode == cacheOpt.CLEAR_CACHE_AND_SET_INPUT_CURRENT:
		clear_cache();
	
	var BIOME : BiomeData;
	var ARENA : Arena;
	
	## 
	if inBiome.to_upper() == "RANDOM" and inArena.to_upper() == "RANDOM":
		move_to_random_biome_and_arena(false);
	elif inBiome.to_upper() == "NEW" and inArena.to_upper() == "NEW":
		move_to_random_biome_and_arena(true);
	else:
		if inBiome == null:
			BIOME = get_current_biome();
			pass;
		elif inBiome is String:
			if inBiome.to_upper() == "CURRENT": ## The current biome.
				BIOME = get_current_biome();
				move_to_biome(BIOME);
				pass;
			elif inBiome.to_upper() == "RANDOM": ## A completely random new biome.
				BIOME = get_random_biome(false);
				move_to_biome(BIOME);
				pass;
			elif inBiome.to_upper() == "NEW": ## A random new biome, excluding the current one.
				BIOME = get_random_biome(true);
				move_to_biome(BIOME);
				pass;
			else:
				BIOME = move_to_biome_name(inBiome);
				pass;
		elif inBiome is BiomeData:
			BIOME = inBiome;
			move_to_biome(BIOME);
		
		BIOME = get_current_biome();
		
		if inArena == null:
			ARENA = get_current_arena();
		elif inArena is PackedScene or inArena is Arena:
			move_to_arena_and_biome(BIOME, inArena);
		elif inArena is String:
			if inArena.to_upper() == "CURRENT": ## The current arena.
				ARENA = get_current_arena();
				pass;
			elif inArena.to_upper() == "RANDOM": ## A completely random new biome.
				move_to_random_arena_in_current_biome(false);
				pass;
			elif inArena.to_upper() == "NEW": ## A random new biome, excluding the current one.
				move_to_random_arena_in_current_biome(true);
				pass;
			else:
				move_to_named_arena_in_current_biome(inArena);
	
	BIOME = get_current_biome();
	ARENA = get_current_arena();
	var TIME : int = 0; ## Returned.
	var doObstacles := true; ## Whether to spawn in obstacles on ARENA.
	
	if cacheMode == cacheOpt.CACHE_INPUT:
		## Cache the thing we just made and end here.
		cache_arena(ARENA);
		cache_biome(BIOME);
		doObstacles = false;
	elif cacheMode == cacheOpt.CACHE_INPUT_AND_SET_OLD_CACHE_CURRENT:
		## Swap out the thing we just made into the cache, and perform obstaclage to the unstashed thing.
		swap_current_arena_with_cache();
		swap_current_biome_with_cache();
		
		BIOME = get_current_biome();
		ARENA = get_current_arena();
	
	if doObstacles:
		TIME = 1;
		
		if inVariant == null:
			TIME = load_random_arena_variant(ARENA);
		elif inVariant is String:
			if inVariant == "CURRENT":
				## Nothing happens.
				pass;
			elif inVariant == "RANDOM":
				TIME = load_random_arena_variant(ARENA);
				pass;
			elif inVariant == "NEW":
				ARENA.clear_used_variants();
				TIME = load_random_arena_variant(ARENA);
				pass;
			else:
				TIME = load_arena_named_variant(ARENA, inVariant);
	
	ARENA.reset_spawning_locations();
	
	return TIME;

## Returns [member currentBiome].
func get_current_biome():
	return currentBiome;
## Gets a named biome from [member biomes] if it exists.
func get_named_biome(biomeKey : String):
	if biomeKey in biomes:
		return biomes[biomeKey];
	return biomes["Old"]; ## Old is the fallback.
## Gets a random biome from [member biomes].
func get_random_biome(excludeCurrent := true) -> BiomeData:
	var all = biomes.duplicate(true);
	var keys = all.keys();
	keys.erase("Workshop");
	if excludeCurrent:
		keys.erase(currentBiomeName);
		if keys.is_empty():
			return biomes["Old"];
	keys.shuffle();
	var key = keys.pop_front();
	return biomes[key];
## Gets a random biome from [member biomes], gets a random [Arena] from it, then moves to both.
func move_to_random_biome_and_arena(excludeCurrent := true, putOldInCache := false):
	var newBiome = get_random_biome(excludeCurrent);
	var newArenaScene = newBiome.get_random_arena(excludeCurrent);
	move_to_arena_and_biome(newBiome, newArenaScene, putOldInCache);
## Gets the current biome, gets a random [Arena] from it, then moves to both.
func move_to_random_arena_in_current_biome(excludeCurrent := true, putOldInCache := false):
	var newArenaScene = currentBiome.get_random_arena(excludeCurrent);
	move_to_arena_and_biome(currentBiome, newArenaScene, putOldInCache);
## Moves to the given biome data.
func move_to_biome(newBiome : BiomeData) -> BiomeData:
	if is_instance_valid(newBiome):
		if newBiome != currentBiome:
			currentBiome = newBiome;
			currentBiomeName = biome_name_from_biome(newBiome);
	return currentBiome;
## Moves to the bime in [member Biomes] with the given biome name, or just stays in the biome you're currently in.[br]
## Note: Does not actually affect anything regarding the current arena.
func move_to_biome_name(newBiomeName) -> BiomeData:
	if biomes.has(newBiomeName):
		#prints("STATE: CHANGING BIOME NAMES TO ", newBiomeName, "FROM", currentBiomeName);
		if newBiomeName != currentBiomeName:
			move_to_biome(biomes[newBiomeName]);
			currentBiomeName = newBiomeName;
	return currentBiome;
## Move to a new named arena in the biome you specify by name. Moves us to the new biome if it is indeed new, but keeps us there if it's the same.
func move_to_named_arena_in_named_biome(newBiomeName : String, arenaName : String, putOldInCache := false):
	## If the biome name is new, move there.
	if biomes.has(newBiomeName):
		move_to_biome_name(newBiomeName);
	move_to_named_arena_in_current_biome(arenaName, putOldInCache);
## Move to a new arena in the current biome. (Calls [method move_to_named_arena_in_biome] using [member currentBiome])
func move_to_named_arena_in_current_biome(arenaName : String, putOldInCache := false):
	move_to_named_arena_in_biome(currentBiome, arenaName, putOldInCache);
## Move to a new named arena in the given biome. (Calls [method move_to_arena_and_biome] using the given name.[br]If the specified arena does not have the specified arena name, this function will fallback to the workshop arena.
func move_to_named_arena_in_biome(inBiome : BiomeData, arenaName : String, putOldInCache := false):
	var scene = inBiome.get_named_arena(arenaName);
	move_to_arena_and_biome(inBiome, scene, putOldInCache);
## Move to a new arena or arena packedscene in the given biome.
func move_to_arena_and_biome(inBiome : BiomeData, newArenaOrScene, putOldInCache := false):
	## Move to the new biome if it's new.
	move_to_biome(inBiome);
	## Setup. Use the current arena as a fallback.
	var arena = currentArena;
	## Check if the biome has an arena by the name given.
	if putOldInCache:
		cache_current_arena();
		cache_current_biome();
	else:
		destroy_current_arena();
	
	set_new_arena_as_current(newArenaOrScene);
## Instantiates the given arena scene, adds it as a child, and then returns it, if the operation was successful.
func create_new_arena(arenaScene : PackedScene) -> Arena:
	var new = arenaScene.instantiate();
	if new is Arena:
		add_child(new);
		return new;
	return null;
## Returns [member currentArena].
func get_current_arena():
	if is_instance_valid(currentArena):
		print("CURRENT ARENA: ", currentArena.name);
		pass;
	else:
		print("CURRENT ARENA IS INVALID.");
		pass;
	return currentArena;
## if [param newArenaOrScene] is an [Arena], then it sets it directly as the current arena.[br]
## If [param newArenaOrScene] is instead a [PackedScene], then it unpacks and instantiates it first using create_new_arena().[br]
## If, for whatever reason, after unpacking or loading, the arena is not inside the tree, then we add it as a child.[br]
## If all of this went south, nothing happens in the end.
func set_new_arena_as_current(newArenaOrScene):
	if !is_instance_valid(newArenaOrScene): return; ## Check for if the input is bad.
	if newArenaOrScene is PackedScene:
		newArenaOrScene = create_new_arena(newArenaOrScene);
	if !is_instance_valid(newArenaOrScene): return; ## Check for if the unpack went bad.
	if newArenaOrScene is Arena:
		#print("STATE: ENTERING NEW ARENA ",newArenaOrScene.name);
		currentArena = newArenaOrScene;
		if !newArenaOrScene.is_inside_tree():
			add_child(newArenaOrScene);
		change_backup_cam_pos_to_current_arena();

func biome_name_from_biome(inBiome : BiomeData):
	return biomes.find_key(inBiome);
var cachedArena : Arena;
var cachedBiome : BiomeData;
var cachedBiomeName : String;
func clear_cache():
	cachedArena = null;
	cachedBiome = null;
## Chaches the current arena if there is one.
func cache_current_arena():
	cache_arena(currentArena);
func cache_current_biome():
	cache_biome(currentBiome);
func cache_arena(inArena : Arena):
	if is_instance_valid(inArena):
		cachedArena = inArena;
		if cachedArena.is_inside_tree():
			inArena.get_parent().remove_child(cachedArena);
func cache_biome(inBiome : BiomeData):
	if is_instance_valid(inBiome):
		cachedBiome = inBiome;
		cachedBiomeName = biome_name_from_biome(inBiome);
## Gets the arena out of the cache if there is one.
func get_arena_from_cache() -> Arena:
	if is_instance_valid(cachedArena):
		return cachedArena;
	return null;
func get_biome_from_cache() -> BiomeData:
	if is_instance_valid(cachedBiome):
		return cachedBiome;
	return null;
## Takes the arena out of the cache and returns it.
func pop_arena_from_cache() -> Arena:
	#print("STATE: CACHED ARENA RESULT: ", is_instance_valid(cachedArena))
	if is_instance_valid(cachedArena):
		var c = cachedArena;
		cachedArena = null;
		return c;
	return null;
func pop_biome_from_cache() -> BiomeData:
	if is_instance_valid(cachedBiome):
		var b = cachedBiome;
		cachedBiome = null;
		return b;
	return null;
## Swaps the contents of the cache with the arena you give as input, unless the input is invalid.
func swap_arena_with_cache(oldArena : Arena):
	if ! is_instance_valid(oldArena): return;
	var c = pop_arena_from_cache();
	if is_instance_valid(c):
		set_new_arena_as_current(c);
	cache_arena(oldArena);
func swap_biome_with_cache(oldBiome : BiomeData):
	if ! is_instance_valid(oldBiome): return;
	var b = pop_biome_from_cache();
	if is_instance_valid(b):
		move_to_biome(b);
	cache_biome(oldBiome);
## Swaps the contents of the cache with the current arena.
func swap_current_arena_with_cache():
	swap_arena_with_cache(currentArena);
func swap_current_biome_with_cache():
	swap_biome_with_cache(currentBiome);
## Destroys the current arena, then sets currentArena to null regardless of if the result was successful.
func destroy_current_arena():
	destroy_arena(get_current_arena());
	currentArena = null;
## Destroys the arena given as input.
func destroy_arena(inArena : Arena) -> bool:
	if is_instance_valid(currentArena):
		currentArena.queue_free();
		return true;
	return false
## Runs [method load_random_arena_variant] using [member currentArena] as [param load_random_arena_variant.inArena].
func load_random_current_arena_variant() -> int:
	return load_random_arena_variant(currentArena);
## Builds a new random variant of the given arena. Returns an amount of frames to hold for, as well as setting [member initArenaFrameWait] to that value.
func load_random_arena_variant(inArena : Arena) -> int:
	if is_instance_valid(inArena):
		#print("STATE: LOADING ARENA VARIANT")
		initArenaFrameWait = inArena.load_new_random_variant();
		return initArenaFrameWait;
	initArenaFrameWait = max(1, initArenaFrameWait);
	return initArenaFrameWait;
## Builds a new random variant of the current arena. Returns an amount of frames to hold for.
func load_current_arena_named_variant(namedVariant := "Base"):
	return load_arena_named_variant(currentArena, namedVariant);
## Builds a new random variant of the given arena. Returns an amount of frames to hold for.
func load_arena_named_variant(inArena : Arena, namedVariant := "Base") -> int:
	if is_instance_valid(inArena):
		#print("STATE: LOADING ARENA VARIANT");
		initArenaFrameWait = inArena.load_variant(namedVariant);
		return initArenaFrameWait;
	initArenaFrameWait = max(1, initArenaFrameWait);
	return initArenaFrameWait;

############################ WAVES SETUP     TODO: Move a lot of the waves setup code to the individual game maps, when those exist.

func set_enemy_spawn_waves(inWave:int):
	var changed = false;
	if inWave == -1:
		clear_enemy_spawn_list();
		changed = true;
	if inWave == 1:
		#add_enemy_to_spawn_list(load("res://scenes/prefabs/objects/robots/robot_test_volley.tscn"), 4)
		#add_enemy_to_spawn_list(load("res://scenes/prefabs/objects/robots/robot_test.tscn"), 4)
		add_enemy_to_spawn_list(load("res://scenes/prefabs/objects/robots/robot_pokey.tscn"), 4)
		#add_enemy_to_spawn_list(load("res://scenes/prefabs/objects/npcs/enemy_ranger.tscn"), 2)
		#add_enemy_to_spawn_list(load("res://scenes/prefabs/objects/npcs/enemy_flash.tscn"), 4)
		#add_enemy_to_spawn_list(load("res://scenes/prefabs/objects/npcs/enemy_thruster.tscn"), 8)
		changed = true;
	if inWave == 2:
		#add_enemy_to_spawn_list(load("res://scenes/prefabs/objects/npcs/enemy_ranger.tscn"), 3)
		changed = true;
	if inWave == 4:
		#add_enemy_to_spawn_list(load("res://scenes/prefabs/objects/npcs/enemy_ranger.tscn"), 2)
		changed = true;
	if inWave == 10:
		#add_enemy_to_spawn_list(load("res://scenes/prefabs/objects/npcs/enemy_soldier.tscn"), 1)
		#add_enemy_to_spawn_list(load("res://scenes/prefabs/objects/npcs/enemy_thruster.tscn"), -3)
		changed = true;
	
	if changed:
		define_enemy_spawn_pool();

func define_enemy_spawn_pool():
	var pool = []
	var spawnListCopy = enemySpawnList.duplicate(true);
	for scene in spawnListCopy.keys():
		var weight = spawnListCopy[scene];
		
		while weight > 0:
			pool.append(scene);
			weight -= 1;
	spawnPool = pool;

func clear_enemy_spawn_list():
	enemySpawnList.clear();

func add_enemy_to_spawn_list(scene : PackedScene, weight : int):
	if scene in enemySpawnList.keys():
		enemySpawnList[scene] += weight;
		if enemySpawnList[scene] && enemySpawnList[scene] <= 0:
			enemySpawnList.erase(scene);
	else:
		enemySpawnList[scene] = weight;

func return_random_enemy():
	var pool = spawnPool;
	var sceneReturn = pool.pick_random();
	return sceneReturn;

#################### PLAYER SPAWNING 

@export var inspectorHUD : Inspector;
@export var stashHUD : PieceStash;
@export var abilityHUD : AbilitySlotManager;

func spawn_player_new_game() -> Robot_Player:
	if player != null and is_instance_valid(player):
		return player;
	else:
		if is_instance_valid(player):
			if player.is_inside_tree():
				player.queue_free();
		
		var newPlayer = playerScene.instantiate();
		add_child(newPlayer);
		player = newPlayer;
	
	player.start_new_game();
	player.queue_live();
	stashHUD.currentRobot = player;
	player.inspectorHUD = inspectorHUD;
	abilityHUD.currentRobot = player;
	stashHUD.regenerate_list();
	return player;

func teleport_player(_in_position := playerSpawnPosition):
	var teleportResult = false;
	#print("STATE: TELEPORTING PLAYER")
	if player != null and is_instance_valid(player):
		player.body.set_deferred("position", _in_position);
		teleportResult = true;
		#print("STATE: TELEPORTING PLAYER DOES EXISTd")
	return teleportResult;

func respawn_player():
	var respawnResult := false;
	var respawnError := ""
	if is_instance_valid(player):
		if is_instance_valid(currentArena):
			if is_instance_valid(currentArena.obstaclesNode):
				currentArena.reset_spawning_locations();
				#print("STATE: RESPAWNING PLAYER ATTEMPT NOW; ", currentArena.obstaclesNode, currentArena.spawningLocations.size())
				if currentArena.spawningLocations.size() > 0:
					var location = return_random_unoccupied_spawn_location_position();
					if currentArena.spawningLocations.size() > 1:
						if location != null:
							respawnResult = teleport_player(location);
							respawnError = "" if respawnResult else " || Error: Teleport to a valid location failed"
						else:
							respawnError = " || Error: No valid spawning locations"
					else:
						respawnResult = teleport_player(currentArena.spawningLocations.front().global_position);
						respawnError = "" if respawnResult else " || Error: Teleport to the ONLY LOCATION failed"
	#print("STATE: PLAYER RESPAWN RESULT: ",respawnResult,respawnError)
	return respawnResult;

func spawn_or_respawn_player():
	var respawnResult = false;
	
	## Spawn the player if they're null.
	if (player == null or !is_instance_valid(player)):
		spawn_player_new_game();
	respawnResult = respawn_player();
	#print("STATE:WHY, ",respawnResult)
	return respawnResult;

##Returns a spawn location that isn't occupied by the player
func return_random_unoccupied_spawn_location_position():
	var node = return_random_unoccupied_spawn_location();
	if node != null:
		return node.global_position;
	return null;
##Returns a spawn location that isn't occupied by the player
func return_random_unoccupied_spawn_location() -> RobotSpawnLocation:
	if is_instance_valid(get_current_arena()):
		return currentArena.return_random_unoccupied_spawn_location();
	return null;

@export var maxAliveEnemies := 5; ## The max amount of enemies alowed to be alive at once.

func spawn_wave(numOfEnemies := 0):
	#return
	while numOfEnemies > 0 && roundEnemies > 0 && check_alive_enemies() <= maxAliveEnemies and ! at_enemy_capacity():
		var enemyScene = return_random_enemy();
		var pos = return_random_unoccupied_spawn_location();
		waveSpawnList.append(enemyScene)
		numOfEnemies -= 1;
	if at_enemy_capacity():
		waveSpawnList.clear();

## Spawns an enemy indiscriminately.
func spawn_single_random_enemy():
	var newEnemySpawner = return_random_unoccupied_spawn_location();
	if newEnemySpawner != null:
		var enemyScene = return_random_enemy();
		newEnemySpawner.assign_gameBoard(self);
		newEnemySpawner.assign_enemy_type_from_resource(enemyScene);
		newEnemySpawner.assign_enemy_type(enemyScene);
		var enemy = newEnemySpawner.start_spawn();
		enemiesSpawned.append(enemy);
		enemiesAlive.append(enemy);

func spawn_enemy_from_wave():
	if waveSpawnList.size() > 0 and ! at_enemy_capacity():
		var newEnemySpawner = return_random_unoccupied_spawn_location();
		if newEnemySpawner != null:
			var enemyScene = waveSpawnList.pop_front();
			newEnemySpawner.assign_gameBoard(self);
			#add_child(newEnemySpawner);
			newEnemySpawner.assign_enemy_type_from_resource(enemyScene);
			newEnemySpawner.assign_enemy_type(enemyScene);
			var enemy = newEnemySpawner.start_spawn();
			enemiesSpawned.append(enemy);
			enemiesAlive.append(enemy);
			roundEnemies -= 1;

func check_alive_enemies():
	var removals = [];
	for enemy in enemiesAlive:
		#print(enemy)
		var _continue = true
		if !is_instance_valid(enemy):
			removals.append(enemy);
			_continue = false
		if enemy == null && _continue:
			removals.append(enemy);
			_continue = false
		if _continue:
			if ! enemy.is_inside_tree(): ## REALLY Hasn't been spawned yet.
				_continue = false;
			if _continue:
				var checkedEnemy = get_node_or_null(enemy.get_path());
				if enemy.is_queued_for_deletion():
					_continue = false;
					removals.append(enemy);
				else:
					if _continue: ## If we've gotten to this point and it returns null, get rid of the thing.
						if checkedEnemy == null:
							removals.append(enemy);
							_continue = false;
					if _continue: ## Hasn't been spawned yet.
						if checkedEnemy.spawned == false:
							_continue = false;
						else:
							Utils.append_unique(enemiesSpawned, checkedEnemy);
	
	for enemy in removals:
		enemiesAlive.erase(enemy);
	
	return enemiesAlive.size();

## Returns true if the amount of enemies spawned this round has reached the round spawn amount number.
func at_enemy_capacity():
	return enemiesSpawned.size() >= roundEnemiesInit;

##Should give us the amount of enemies left after all spawning is completed
func check_round_completion() -> float:
	#print("Round enemies: ",roundEnemies);
	#print("Alive enemies: ",check_alive_enemies());
	#print("Initial round enemies: ",roundEnemiesInit);
	return float(get_enemies_left_for_wave()) / float(roundEnemiesInit);

func get_enemies_left_for_wave() -> int:
	return roundEnemies + check_alive_enemies();

func destroy_all_enemies(destroyPlayer := false):
	check_alive_enemies();
	
	for enemy in enemiesAlive:
		if enemy:
			enemy.call_deferred("die");
	
	if destroyPlayer:
		if is_instance_valid(player):
			player.destroy();
			player = null;

##Run only when GameState.pause() is called.
func pause(foo : bool):
	pause_all_robots_and_projectiles(foo);
	##TODO: Add in other pause functions for things like projectiles and stuff.

##Pauses all robots specifically.
func pause_all_robots_and_projectiles(foo : bool):
	#print("Pausing all FreezableEntities: ", str(foo))
	for thing in Utils.get_all_children("GameBoard pausing FreezableControl and FreezableEntity nodes",self):
		#print(thing)
		if thing is FreezableControl:
			thing.pause(foo, true);
		if thing is FreezableEntity:
			thing.pause(foo, true);

##Fired when the game is over.
func game_over():
	if not in_game_over_state(): return;
	var devCheatsEnabled = GameState.get_setting("devMode")
	if not devCheatsEnabled:
		var saveData = GameState.save_high_scores(GameState.get_round_number(), enemiesKilled, scrapGained)
		var highScoreRound = saveData["highScoreRound"]
		var highScoreKills = saveData["highScoreKills"]
		var highScoreScrap = saveData["highScoreScrap"]
		%GameOverStats.clear();
		%GameOverStats.append_text("[i][b]STATS[/b]");
		%GameOverStats.newline();
		if highScoreRound:
			%GameOverStats.append_text("[color=ff0000]")
		%GameOverStats.append_text("HIGHEST ROUND: " + str(GameState.get_round_number()));
		if highScoreRound:
			%GameOverStats.append_text(" ![/color]")
		%GameOverStats.newline();
		if highScoreKills:
			%GameOverStats.append_text("[color=ff0000]")
		%GameOverStats.append_text("ENEMIES KILLED: " + str(enemiesKilled));
		if highScoreKills:
			%GameOverStats.append_text(" ![/color]")
		%GameOverStats.newline();
		if highScoreScrap:
			%GameOverStats.append_text("[color=ff0000]")
		%GameOverStats.append_text("SCRAP GAINED: " + str(scrapGained));
		if highScoreScrap:
			%GameOverStats.append_text(" ![/color]")
		if highScoreRound or highScoreKills or highScoreScrap:
			%GameOverStats.newline();
			%GameOverStats.append_text("! NEW HIGH SCORE !");
	else:
		%GameOverStats.clear();
		%GameOverStats.append_text("[i][b]STATS[/b]");
		%GameOverStats.newline();
		%GameOverStats.append_text("HIGHEST ROUND: " + str(GameState.get_round_number()));
		%GameOverStats.newline();
		%GameOverStats.append_text("ENEMIES KILLED: " + str(enemiesKilled));
		%GameOverStats.newline();
		%GameOverStats.append_text("SCRAP GAINED: " + str(scrapGained));
		%GameOverStats.newline();
		%GameOverStats.append_text("[color=ff0000]( HIGH SCORES DISABLED BY CHEATS )[/color]");
	change_state(gameState.GAME_OVER);

@export var workshopArea : Node3D; ##@deprecated
## Caches the current arena, moves us to the workshop, then 
func move_player_to_workshop():
	arena_move_master("Workshop", "Base", "Base", cacheOpt.CACHE_OLD_AND_SET_INPUT_CURRENT);

func move_out_of_workshop():
	swap_current_arena_with_cache();
	swap_current_biome_with_cache();
	clear_cache();
	#arena_move_master("Workshop", "Base", "Base", cacheOpt.CACHE_INPUT_AND_SET_OLD_CACHE_CURRENT);

############## BUTTON CALLS
func _on_btn_play_pressed():
	change_state(gameState.INIT_NEW_GAME);
	pass # Replace with function body.
func _on_btn_menu_pressed():
	change_state(gameState.MAIN_MENU);
	pass # Replace with function body.
func _on_btn_credits_pressed():
	change_state(gameState.CREDITS);
	pass # Replace with function body.
func _on_btn_exit_pressed():
	GameState.quit_game();
	pass # Replace with function body.
func _on_btn_end_run_pressed():
	player.die();
	pass # Replace with function body.
func _on_btn_options_pressed():
	change_state(gameState.OPTIONS);
	pass # Replace with function body.


######################### DEATH TIMER MGMT
@export var deathTimer : DeathTimer;

func get_death_timer() -> DeathTimer:
	return deathTimer;


func _on_btn_editor_pressed():
	GameState.editor_mode_start();
	awaitingScreenTransition = true;
	pass # Replace with function body.
