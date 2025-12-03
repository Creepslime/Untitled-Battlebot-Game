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
	if DisplayServer.get_screen_count() > 1:
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
	
	#ping_screen_transition();
	
	
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
	elif Input.is_action_just_pressed("dbg_ClearProfiler"):
		clear_profiler_pings();
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

## Gets whether the player has a "body piece" (like bodyCube)
func get_player_has_body_piece() -> bool:
	var ply = get_player()
	
	if is_instance_valid(ply):
		return ply.has_body_piece();
	return false;

func get_player_position():
	var bdy = get_player_body();
	
	if is_instance_valid(bdy):
		return bdy.global_position;
	return Vector3(0,0,0);

func get_player_selected_or_pipette():
	var ply = get_player()
	
	if is_instance_valid(ply):
		return ply.get_selected_or_pipette();
	return null
func get_player_selected_for_inspector():
	var ply = get_player()
	
	if is_instance_valid(ply):
		return ply.get_selected_for_inspector();
	return null

func get_player_selected_piece():
	var ply = get_player()
	
	if is_instance_valid(ply):
		return ply.get_selected_piece();
	return null

func get_player_selected_part():
	var ply = get_player()
	
	if is_instance_valid(ply):
		return ply.get_selected_part();
	return null

func get_player_pipette():
	var ply = get_player()
	
	if is_instance_valid(ply):
		return ply.get_current_pipette();
	return null
func get_player_ability_pipette():
	var ply = get_player()
	
	if is_instance_valid(ply):
		return ply.get_ability_pipette();
	return null
func get_player_part_movement_pipette():
	var ply = get_player()
	
	if is_instance_valid(ply):
		return ply.partMovementPipette;
	return null

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

## @deprecated
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

var statLog = []
func log_unique_stat(inStat : StatTracker):
	if inStat in statLog:
		#print_rich("[color=red][b]Duplicate stat being created.")
		pass;
	else:
		statLog.append(inStat);
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

var shopStallID := 0;

func get_unique_shop_stall_id() -> int:
	var ret = shopStallID;
	shopStallID += 1;
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
	StringName("RoundTimerRuns") : true,
	
	StringName("HiddenScreenTransitions") : false,
	StringName("ProfilerLabelsVisible") : false,
	StringName("EnemyGodMode") : false,
	
	StringName("renderShadows") : true,
}

func set_setting(settingName : StringName, settinginput : Variant):
	push_warning("Attempt to set setting ", settingName, " to a value of ", (settinginput));
	var setting = get_setting(settingName);
	if setting != null:
		if typeof(setting) == typeof(settinginput):
			#print (settings.has(StringName(settingName)))
			settings[settingName] = settinginput;
			pass
		else:
			push_warning("Attempt to set setting ", settingName, " to a value of the invalid type ", type_string(settinginput), ". Should be ", type_string(setting));
	
	#print(get_setting(settingName));
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
				#print("setting key found: ", key, " ", content[key])
			pass
	file.close()
	
	Hooks.OnLoadSettings();
	#prints("[b]Loading settings: ", settings)
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
	#print(board)
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
var waitingOnTransitionString = ""
func ping_screen_transition():
	profiler_ping_create("Waiting on Screen Transition")
	if screenTransition.is_on_center():
		hit_center();
	if screenTransition.is_on_right():
		hit_right();
	set("waitingOnTransitionString", "SCREEN TRANSITION: BEING WAITED ON...")

var totalPlayTime := 0.0;
var timeCounter = 0.;
var profilerFrames = 0;
var profilerFPS := 0;
var profilerPingCalls = {}
var profilerPingBanks = {}
var profilerPingTimers = {}
var profilerPingRecords = {}
const maxLoopsBeforeDeletionIfEmpty := 30;
func profiler_ping_create(reason := "unknown"):
	if !profilerRunning: return;
	
	if ! profilerPingCalls.has(reason):
		profilerPingCalls[reason] = 0;
	if ! profilerPingBanks.has(reason):
		profilerPingBanks[reason] = 0;
	profilerPingCalls[reason] += 1;
	profilerPingTimers[reason] = maxLoopsBeforeDeletionIfEmpty;

func profiler_ping_time_create(reason, time:float):
	if !profilerRunning: return;
	
	if ! profilerPingCalls.has(reason):
		profilerPingCalls[reason] = 0.;
	if ! profilerPingBanks.has(reason):
		profilerPingBanks[reason] = 0.;
	profilerPingCalls[reason] += time;
	profilerPingTimers[reason] = maxLoopsBeforeDeletionIfEmpty;

var profilerPingString := ""
## Gets a string representing all the profiler pings.
func get_profiler_ping_string(expensive:= false) -> String:
	if expensive:
		var s = "\n\nPROFILER PINGS:"
		var profilerPingBanksKeysSorted = profilerPingBanks.keys();
		profilerPingBanksKeysSorted.sort() ;
		
		for reason in profilerPingBanksKeysSorted:
			var timeSinceLastIncident = profilerPingTimers[reason];
			if timeSinceLastIncident > 0:
				var timelinessFactor = (float(timeSinceLastIncident) / float(maxLoopsBeforeDeletionIfEmpty)) + 0.3;
				var current = profilerPingBanks[reason];
				var r = 1.;
				var g = 1.;
				var b = 1.;
				
				## Log the peak amount of calls while the entry has been alive for > 30 seconds.
				if ! profilerPingRecords.has(reason):
					profilerPingRecords[reason] = current;
				var highest = profilerPingRecords[reason];
				if current > highest:
					b = 0.;
					profilerPingRecords[reason] = current;
				highest = profilerPingRecords[reason];
				
				var colorHexString = TextFunc.get_color_hex_string_from_rgba(r * timelinessFactor, g * timelinessFactor, b * timelinessFactor, 1.);
				s += "\n"
				s += "[color=" + colorHexString + "]"
				s += reason
				s += ": "
				s += str(current)
				s += " | ~"
				if profilerFPS > 0:
					s += TextFunc.get_decimal_string(current / profilerFPS, 4, true)
					s += "/frame"
				else:
					s += "0/frame"
				s += " | Peak: " + str(highest);
			elif timeSinceLastIncident == 0:
				var colorHexString = TextFunc.get_grey_hex_string(0.3);
				s += "\n"
				s += "[color=" + colorHexString + "]"
				s += reason
				s += ": Last ping too old, deleting..."
			else:
				## Reset the high-score.
				profilerPingRecords[reason] = 0;
				pass;
		
		profilerPingString = s;
	return profilerPingString;

func get_profiler_label():
	var selectionColor = "gray"
	var selPipette = get_player_selected_or_pipette();
	if is_instance_valid(selPipette):
		if selPipette is Piece:
			selectionColor = TextFunc.get_color_hex_string("lightred")
		if selPipette is Part:
			selectionColor = TextFunc.get_color_hex_string("lightgreen")
		if selPipette is AbilityData:
			selectionColor = TextFunc.get_color_hex_string("lightblue")
	var selectionColor2 = "gray"
	var selPipette2 = get_player_selected_for_inspector();
	
	var currentlySelected := str("\n[color=",selectionColor,"]CURRENTLY SELECTED (Robot excluded): ",str(selPipette))
	currentlySelected += str("\n[color=white] - ", "[color="+(TextFunc.get_color_hex_string("scrap"))+"]" if selPipette2 is Robot else "[color=gray]", "ROBOT: ",str(get_player()) if selPipette2 is Robot else str(null))
	currentlySelected += str("\n[color=white] - ", "" if is_instance_valid(get_player_selected_piece()) else "[color=gray]", "PIECE: ",str(get_player_selected_piece()))
	currentlySelected += str("\n[color=white] - ", "" if is_instance_valid(get_player_selected_part()) else "[color=gray]", "PART: ",str(get_player_selected_part()))
	currentlySelected += str("\n[color=white] - ", "" if is_instance_valid(get_player_pipette()) else "[color=gray]", "PIECE PIPETTE: ",str(get_player_pipette()))
	currentlySelected += str("\n[color=white] - ", "" if is_instance_valid(get_player_part_movement_pipette()) else "[color=gray]", "PART MOVEMENT PIPETTE: ",str(get_player_part_movement_pipette()))
	currentlySelected += str("\n[color=white] - ", "" if is_instance_valid(get_player_ability_pipette()) else "[color=gray]", "ABILITY PIPETTE: ",str(get_player_ability_pipette()))
	currentlySelected += "[color=white]"
	var transitionString = waitingOnTransitionString;
	waitingOnTransitionString = "\nSCREEN TRANSITION: Chilling"
	
	var s = str("TOTAL PLAY TIME: ", TextFunc.format_time(totalPlayTime, 0, -1), "\nPROFILER UPDATE LOOP: ",TextFunc.format_stat(timeCounter),"\nFPS: ",profilerFPS,currentlySelected,"\nSTATE: ",get_game_board_state_string(),transitionString,"\nPAUSED: ", is_paused(), get_profiler_ping_string());
	
	return s;

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
		if ! is_paused():
			for reason in profilerPingTimers:
				profilerPingTimers[reason] -= 1;
		
		get_profiler_ping_string(true);
		
		profilerRunning = get_setting("ProfilerLabelsVisible");

var profilerRunning := true;
## Clears out the profiler until next frame.
func clear_profiler_pings():
	profilerPingBanks.clear();
	profilerPingCalls.clear();
	profilerPingRecords.clear();
	profilerPingTimers.clear();
	pTimeStartTable.clear();
	profilerRunning = false;

var pTimeStart := 0
var pTimeStartTable = {}
func profiler_time_usec_start(reason := "[Unnamed call]"):
	if !profilerRunning: return;
	
	if reason == "[Unnamed call]":
		pTimeStart = Time.get_ticks_usec()
	else:
		pTimeStartTable[reason] = Time.get_ticks_usec()

func profiler_time_usec_end(reason:String="[Unnamed call]", doPrint := false):
	if !profilerRunning: return;
	
	var end = Time.get_ticks_usec();
	var time_taken;
	if reason == "[Unnamed call]" or ! pTimeStartTable.has(reason):
		#time_taken = (end-pTimeStart)/1000000.0;
		time_taken = (end-pTimeStart);
	else:
		#time_taken = (end-pTimeStartTable[reason])/1000000.0;
		time_taken = (end-pTimeStartTable[reason]);
	if doPrint:
		print(reason," : ",time_taken);
	profiler_ping_time_create(reason + " (Usecs)", time_taken);

func profiler_time_msec_start(reason := "[Unnamed call]"):
	if !profilerRunning: return;
	
	if reason == "[Unnamed call]":
		pTimeStart = Time.get_ticks_msec()
	else:
		pTimeStartTable[reason] = Time.get_ticks_msec()

func profiler_time_msec_end(reason:String= "[Unnamed call]", doPrint := false):
	if !profilerRunning: return;
	
	var end = Time.get_ticks_msec();
	var time_taken;
	if reason == "[Unnamed call]" or ! pTimeStartTable.has(reason):
		#time_taken = (end-pTimeStart)/1000000.0;
		time_taken = (end-pTimeStart);
	else:
		#time_taken = (end-pTimeStartTable[reason])/1000000.0;
		time_taken = (end-pTimeStartTable[reason]);
	if doPrint:
		print(reason," : ",time_taken);
	profiler_ping_time_create(reason + " (Msecs)", time_taken);
