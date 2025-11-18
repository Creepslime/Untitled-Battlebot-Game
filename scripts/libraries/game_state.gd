extends Node

# How quickly the player speeds up
var PLAYER_ACCELERATION = 6000;

# how fast enemies can go
var MAX_ENEMY_SPEED = 13

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_settings();
	load_data();
	
	## Cursor stuff!
	#Input.set_default_cursor_shape(Input.CURSOR_BUSY)
	#Input.set_custom_mouse_cursor(load("res://graphics/images/HUD/statIcons/scrapIconStriped.png"),Input.CURSOR_BUSY,Vector2(9.5,11.5));
	
	DisplayServer.window_set_current_screen.call_deferred(1);
	#get_tree().current_scene.ready.connect(_on_scenetree_ready);
	#pass;
#func _on_scenetree_ready():
	init_screen_transition();
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var dbg_prof = GameState.get_setting("ProfilerLabelsVisible");
	if dbg_prof:
		profiler(delta);
	
	ping_screen_transition();
	
	
	if Input.is_action_just_pressed("dbg_RestartGame"):
		print_debug("RESTARTING GAME (hit f4)")
		push_warning("RESTARTING GAME (hit f4)")
		GameState.change_scenes("res://scenes/levels/game_board.tscn");
	elif Input.is_action_just_pressed("dbg_ToggleScreenTransitions"):
		var dbg_hidden = get_setting("HiddenScreenTransitions");
		set_setting("HiddenScreenTransitions", !dbg_hidden)
		if !dbg_hidden:
			push_warning("Transition canvas being DISABLED (Hit f3)")
		else:
			push_warning("Transition canvas being ENABLED (Hit f3)")
	elif Input.is_action_just_pressed("dbg_ToggleProfiler"):
		var dbg_hidden = get_setting("ProfilerLabelsVisible");
		set_setting("ProfilerLabelsVisible", !dbg_hidden)
		if !dbg_hidden:
			push_warning("Profiler labels being DISABLED (Hit f5)")
		else:
			push_warning("Profiler labels being ENABLED (Hit f5)")
	pass


func quit_game():
	save_settings();
	get_tree().quit();

func get_game_board() -> GameBoard:
	var board = get_node_or_null("/root/GameBoard")
	
	if board == null:
		return null;
	
	return board;

func get_game_board_state():
	var maker = get_node_or_null("/root/Maker Modes");
	if maker != null:
		return GameBoard.gameState.MAKER;
	
	var board = get_game_board();
	if board == null:
		return GameBoard.gameState.INVALID;
	
	return board.curState;

func get_game_board_state_string() -> String:
	return GameBoard.gameState.keys()[GameState.get_game_board_state()];

func force_lighting_update():
	var board = get_game_board();
	if board != null:
		return board.update_lighting();

func get_round_number():
	var board = get_game_board();
	
	if board == null:
		return -1;
	
	return board.roundNum;

func get_round_completion():
	var board = get_game_board();
	
	return board.check_round_completion();

func get_wave_enemies_left():
	var board = get_game_board();
	
	return board.get_enemies_left_for_wave();



func get_in_one_of_given_states(states:Array[GameBoard.gameState])->bool:
	var currentState = GameState.get_game_board_state();
	return currentState in states;

func get_in_state_of_play(includeLoading := true) ->bool:
	var board = get_game_board();
	if is_instance_valid(board):
		return board.in_state_of_play(includeLoading);
	else:
		return false;
func get_in_state_of_building() ->bool:
	var maker = get_node_or_null("/root/Maker Modes");
	if maker != null:
		return true;
	
	var board = get_game_board();
	if is_instance_valid(board):
		return board.in_state_of_building();
	else:
		return true;
func get_in_state_of_shopping(includeLoading := false) ->bool:
	var board = get_game_board();
	if is_instance_valid(board):
		return board.in_state_of_shopping(includeLoading);
	else:
		return false;
func get_in_game_over_state() -> bool:
	return get_in_one_of_given_states([GameBoard.gameState.GAME_OVER]);
func get_in_loading_state() -> bool:
	var board = get_game_board();
	if is_instance_valid(board):
		return board.in_state_of_loading();
	else:
		return false;

func get_in_state_of_combat(includeLoading := false, includeTesting := false) ->bool:
	var board = get_game_board();
	if is_instance_valid(board):
		return board.in_state_of_combat(includeLoading, includeTesting);
	else:
		return false;

func set_game_board_state(state : GameBoard.gameState):
	var board = get_game_board();
	
	if board != null:
		board.change_state(state);

## Sets a state to be called when the screen transition shows up, then makes it show up.
func queue_center_transition_state(state := GameBoard.gameState.QUEUE_EMPTY, layer := 3, instantLeave := false):
	var board = get_game_board();
	if is_instance_valid(board):
		return board.queue_center_transition_state(state, layer, instantLeave);

## Sets a state to be called when the screen transition leaves, then makes it leave.
func queue_right_transition_state(state := GameBoard.gameState.QUEUE_EMPTY):
	var board = get_game_board();
	if is_instance_valid(board):
		return board.queue_right_transition_state(state);

func game_over():
	var board = get_game_board();
	
	if is_instance_valid(board):
		board.game_over();

func get_player() -> Robot_Player:
	var ply = get_node_or_null("/root/GameBoard/Robot_Player")
	
	if ply == null:
		return null;
	
	return ply;

func get_player_body() -> RigidBody3D:
	var ply = get_player()
	
	if is_instance_valid(ply):
		return ply.get_node_or_null("Body");
	return null;

func get_player_position():
	var bdy = get_player_body();
	
	if is_instance_valid(bdy):
		return bdy.global_position;
	return Vector3(0,0,0);

func get_camera_pointer() -> Node3D:
	var board = get_game_board();
	
	if board != null:
		return board.get_camera_pointer();
	return null;

func get_player_pos_offset(inGlobalPosition: Vector3):
	var pos = get_player_position();
	return pos - inGlobalPosition;

func get_len_to_player(inGlobalPosition: Vector3):
	var offset = get_player_pos_offset(inGlobalPosition);
	
	var lenToPlayer = offset.length();
	
	return lenToPlayer;

func is_player_in_range(inGlobalPosition:Vector3, range:float):
	var lenToPLayer = get_len_to_player(inGlobalPosition);
	
	return lenToPLayer <= range;

func is_player_alive():
	var CH = get_combat_handler();
	
	if is_instance_valid(CH):
		return CH.is_alive();
	return false;

func get_player_body_mesh():
	var bdy = get_player_body();
	
	if is_instance_valid(bdy):
		return bdy.get_node_or_null("BotBody");
	return null;

func get_input_handler():
	var ply = get_player();
	
	if is_instance_valid(ply):
		return ply.get_node_or_null("InputHandler");
	return null;

func get_combat_handler() -> CombatHandlerPlayer:
	var ply = get_player();
	
	if is_instance_valid(ply):
		return ply.get_node_or_null("CombatHandler");
	return null;

func get_hud():
	var board = get_game_board();
	
	if board != null:
		return board.get_node_or_null("HUDCanvas/HUD Viewport/SubViewport/HUD");

func get_game_hud() -> GameHUD:
	var hud = get_hud();
	
	if hud != null:
		#print("aa")
		return hud.get_node_or_null("GameHud");
	return null;

func get_bar_hp() -> HealthBar:
	var ghud = get_game_hud();
	
	if ghud != null:
		return ghud.get_node_or_null("LeftSide/HealthBarHolder/HealthBar");
	return null;

func get_bar_energy() -> HealthBar:
	var ghud = get_game_hud();
	
	if ghud != null:
		return ghud.get_node_or_null("RightSide/EnergyBarHolder/EnergyBar");
	return null;

func get_engine_viewer() -> PartsHolder_Engine:
	var ghud = get_game_hud();
	
	if ghud != null:
		return ghud.get_node_or_null("LeftSide/PartsHolder_Engine");
	return null;


func get_inventory() -> InventoryPlayer:
	var ply = get_player();
	
	if is_instance_valid(ply):
		return ply.get_node_or_null("Inventory");
	return null;

func get_death_timer() -> DeathTimer:
	var board = get_game_board();
	
	if board != null:
		return board.get_death_timer();
	return null;

func add_death_time(time:float):
	var tmr = get_death_timer();
	
	if tmr != null:
		tmr.add_time(time);

func pause_death_timer(paused:=true):
	var tmr = get_death_timer();
	
	if tmr != null:
		tmr.pause(paused);

func start_death_timer(_startTime := 120.0, _reset := false):
	var tmr = get_death_timer();
	
	if tmr != null:
		tmr.start(_startTime, _reset)

func get_death_time() -> float:
	var tmr = get_death_timer();
	
	if tmr != null:
		tmr.get_time();
	return -999.0;

func get_camera() -> Camera:
	var brd = get_game_board();
	
	if brd != null:
		return brd.get_main_camera();
	return null;

func cam_unproject_position(world_point:Vector3) -> Vector2:
	var cam = get_camera();
	
	if cam != null:
		return cam.unproject_position(world_point);
	return Vector2(0.0,0.0);

func get_music() -> MusicHandler:
	var board = get_game_board();
	
	if board != null:
		return board.get_node_or_null("BGM2");
	return null;

func get_physical_sound_manager() -> SND:
	var board = get_game_board();
	
	if board != null:
		return board.get_node_or_null("SoundManager");
	return null;

var partAge := 0;

func get_unique_part_age() -> int:
	var ret = partAge;
	partAge += 1;
	return ret;

var statID := 0;

func get_unique_stat_id() -> int:
	var ret = statID;
	statID += 1;
	return ret;

var colliderID := 0;

func get_unique_collider_id() -> int:
	var ret = colliderID;
	colliderID += 1;
	return ret;

var statHolderID := 0;

func get_unique_stat_holder_id() -> int:
	var ret = statHolderID;
	statHolderID += 1;
	return ret;

var abilityID := 0;

func get_unique_ability_id() -> int:
	var ret = abilityID;
	abilityID += 1;
	return ret;

############ SETTINGS AND SAVE DATA

static var settings := {
	StringName("volumeLevelMusic") : 1.0,
	StringName("volumeLevelUI") : 0.8,
	StringName("volumeLevelWorld") : 0.9,
	StringName("volumeLevelMaster") : 1.0,
	
	StringName("inventoryDisableShooting") : true,
	StringName("sawbladeDrone") : true,
	
	StringName("devMode") : false,
	StringName("startingScrap") : 0,
	StringName("godMode") : false,
	StringName("killAllKey") : false,
	
	StringName("HiddenScreenTransitions") : false,
	StringName("ProfilerLabelsVisible") : false,
	
	StringName("renderShadows") : true,
}

func set_setting(settingName : StringName, settinginput : Variant):
	push_warning("Attempt to set setting ", settingName, " to a value of ", (settinginput));
	var setting = get_setting(settingName);
	if setting != null:
		if typeof(setting) == typeof(settinginput):
			print (settings.has(StringName(settingName)))
			settings[settingName] = settinginput;
			pass
		else:
			push_warning("Attempt to set setting ", settingName, " to a value of the invalid type ", type_string(settinginput), ". Should be ", type_string(setting));
	
	print(get_setting(settingName));
	save_settings();

func get_setting(settingName : StringName):
	if settings.has(settingName):
		var setting = settings[settingName];
		return setting;
	push_warning("Attempted to access invalid setting ", settingName, " ");
	return null;

func save_settings():
	var file = FileAccess.open("user://settings.dat", FileAccess.WRITE)
	file.store_var(settings)
	file.flush()
	prints("[b]Saving settings.")

func load_settings():
	if not FileAccess.file_exists("user://settings.dat"):
		save_settings()
	
	var file = FileAccess.open("user://settings.dat", FileAccess.READ )
	var content : Dictionary = file.get_var()
	
	if content != null:
		for key in content.keys():
			if key in settings:
				settings[key] = content[key]
				print("setting key found: ", key, " ", content[key])
			pass
	file.close()
	
	Hooks.OnLoadSettings();
	prints("[b]Loading settings: ", settings)
	return settings

static var saveData = {
	StringName("Highest Round") : 0,
	StringName("Most Enemies Killed") : 0,
	StringName("Most Scrap Earned") : 0,
	}

func reset_data():
	saveData = {
	StringName("Highest Round") : 0,
	StringName("Most Enemies Killed") : 0,
	StringName("Most Scrap Earned") : 0,
	};
	save_data();

func save_data():
	var file = FileAccess.open("user://savedata.dat", FileAccess.WRITE)
	file.store_var(saveData)
	file.flush()

func save_high_scores(roundNum, enemiesKilled, scrapGained):
	var highScoreRound = false
	if saveData[StringName("Highest Round")] < roundNum:
		saveData[StringName("Highest Round")] = roundNum
		highScoreRound = true
	
	var highScoreKills = false
	if saveData[StringName("Most Enemies Killed")] < enemiesKilled:
		saveData[StringName("Most Enemies Killed")] = enemiesKilled
		highScoreKills = true
	
	var highScoreScrap = false
	if saveData[StringName("Most Scrap Earned")] < scrapGained:
		saveData[StringName("Most Scrap Earned")] = scrapGained
		highScoreScrap = true
	
	save_data();
	
	return { 
		"highScoreRound":highScoreRound, 
		"highScoreKills":highScoreKills, 
		"highScoreScrap":highScoreScrap
		};

func load_data():
	if not FileAccess.file_exists("user://savedata.dat"):
		reset_data()
	
	var file = FileAccess.open("user://savedata.dat", FileAccess.READ )
	var content : Dictionary = file.get_var()
	
	if content != null:
		for key in content.keys():
			if key in saveData:
				saveData[key] = content[key]
				#print("data key found: ", key, " ", content[key])
			pass
	
	file.close()
	
	#prints("[b]Loading data: ", saveData)
	
	return saveData

############ STATE CONTROL
var paused := false;

func pause(foo : bool = not is_paused()):
	#print("GameState.pause() attempt. New: ", str(foo), " Old: ", str(paused))
	if paused == foo: return;
	#print("GameState.pause() attempt was successful.")
	paused = foo;
	var board = get_game_board();
	print(board)
	if board != null: board.pause(paused);

func is_paused():
	return paused;

var windowFocus := true;
#func _notification(what):
	#match what:
		#MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			#if windowFocus:
				#windowFocus = false;
				#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;
		#MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			#if !windowFocus:
				#windowFocus = true;
				#Input.mouse_mode = Input.MOUSE_MODE_HIDDEN;

func was_fire_action_just_pressed():
	return Input.is_action_just_pressed("Fire0") or Input.is_action_just_pressed("Fire1") or Input.is_action_just_pressed("Fire2") or Input.is_action_just_pressed("Fire3") or Input.is_action_just_pressed("Fire4") or Input.is_action_just_pressed("Select");
func is_fire_action_being_pressed():
	return Input.is_action_pressed("Fire0") or Input.is_action_pressed("Fire1") or Input.is_action_pressed("Fire2") or Input.is_action_pressed("Fire3") or Input.is_action_pressed("Fire4") or Input.is_action_pressed("Select");

func editor_mode_start():
	queue_change_scenes("res://makers/maker_mode.tscn");

func reset_to_main_menu():
	queue_change_scenes("res://scenes/levels/game_board.tscn");


############# SCREEN TRANSITION STUFF
var screenTransitionScene = preload("res://scenes/prefabs/objects/gui/transition_canvas.tscn");
var screenTransition : ScreenTransition;
var transitionCanvas : TransitionCanvas;
func init_screen_transition():
	var canvas = screenTransitionScene.instantiate();
	canvas.layer = 5;
	add_child(canvas);
	
	transitionCanvas = canvas;
	
	screenTransition = canvas.transition;
	
	init_screen_transition_vanity();

func init_screen_transition_vanity():
	transitionCanvas.initialize();
	screenTransition.bring_to_center(true,true);
	screenTransition.show();
	if !screenTransition.is_connected("hitCenter", hit_center):
		screenTransition.connect("hitCenter", hit_center);
	if !screenTransition.is_connected("hitRight", hit_right):
		screenTransition.connect("hitRight", hit_right);

var targetScene = null;
func queue_change_scenes(_targetScene):
	targetScene = _targetScene;
	make_screen_transition_arrive(5);

func change_scenes(_targetSceneOverride = null):
	if _targetSceneOverride != null:
		if _targetSceneOverride is String:
			if FileAccess.file_exists(_targetSceneOverride):
				targetScene = _targetSceneOverride;
	if targetScene != null:
		get_tree().change_scene_to_file(targetScene);
		targetScene = null;
		make_screen_transition_leave();

func hit_center():
	Hooks.OnScreenTransition(ScreenTransition.mode.CENTER);
	
	var brd = get_game_board();
	if brd != null:
		brd.screen_transition(ScreenTransition.mode.CENTER);
	
	change_scenes();
func hit_right():
	Hooks.OnScreenTransition(ScreenTransition.mode.RIGHT);
	
	var brd = get_game_board();
	if brd != null:
		brd.screen_transition(ScreenTransition.mode.RIGHT);

func make_screen_transition_leave():
	if !screenTransition.is_connected("hitRight", hit_right):
		screenTransition.connect("hitRight", hit_right);
	screenTransition.primeASignal;
	screenTransition.leave();
func make_screen_transition_arrive(layer := 3):
	transitionCanvas.layer = layer;
	if !screenTransition.is_connected("hitCenter", hit_center):
		screenTransition.connect("hitCenter", hit_center);
	screenTransition.primeASignal;
	screenTransition.comeIn();
func ping_screen_transition():
	if screenTransition.is_on_center():
		hit_center();
	if screenTransition.is_on_right():
		hit_right();

var totalPlayTime := 0.0;
var timeCounter = 0.;
var profilerFrames = 0;
var profilerFPS := 0;
var profilerPingCalls = {}
var profilerPingBanks = {}
func profiler_ping_create(reason := "unknown"):
	if ! profilerPingCalls.has(reason):
		profilerPingCalls[reason] = 0;
	if ! profilerPingBanks.has(reason):
		profilerPingBanks[reason] = 0;
	profilerPingCalls[reason] += 1;

func get_profiler_string() -> String:
	var s = "\n\nPROFILER PINGS:"
	for reason in profilerPingBanks:
		s += "\n"
		s += reason
		s += ": "
		s += str(profilerPingBanks[reason])
		s += " | ~"
		if profilerFPS > 0:
			s += str(profilerPingBanks[reason] / profilerFPS)
			s += "/frame"
		else:
			s += "0/frame"
	return s;

func get_profiler_label():
	return str("TOTAL PLAY TIME: ", TextFunc.format_time(totalPlayTime, 0, -1), "\nPROFILER UPDATE TIME: ",TextFunc.format_stat(timeCounter),"\nFPS: ",profilerFPS,"\nSTATE: ",get_game_board_state_string(),get_profiler_string());
	

func profiler(delta):
	timeCounter += delta;
	totalPlayTime += delta;
	profilerFrames += 1;
	if timeCounter > 1:
		timeCounter -= 1;
		profilerFPS = profilerFrames;
		profilerFrames = 0;
		
		for reason in profilerPingBanks:
			profilerPingBanks[reason] = profilerPingCalls[reason];
		for reason in profilerPingCalls:
			profilerPingCalls[reason] = 0;
