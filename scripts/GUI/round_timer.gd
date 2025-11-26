extends Label

class_name DeathTimer

var blinkCycle := 0.0;
var blinkTimer := 0.0;

var time := 120.0;
var paused := true;

@export var TimerBlinky : TextureRect;

func _process(delta):
	var isPaused = GameState.is_paused() or paused or !(GameState.get_game_board_state() == GameBoard.gameState.PLAY) or ! GameState.get_setting("RoundTimerRuns");
	
	
	if GameState.get_in_state_of_play():
		text = TextFunc.format_time(time);
		if not visible:
			show();
		if not isPaused:
			if GameState.get_in_state_of_combat(false):
				if time > 0:
					time -= delta;
				else:
					time = 0.0;
			
			if blinkTimer > 0:
				blinkTimer -= delta;
				TimerBlinky.visible = true;
			else:
				TimerBlinky.visible = false;
			
			blinkCycle -= delta;
			if blinkCycle < 0:
				if time <= 90.0:
					blink();
					blinkCycle = max(0.1, time / 60)
					#if time <= 91.0:
						#blinkCycle = 5.0;
					#if time <= 61.0:
						#blinkCycle = 1.0;
					#if time <= 31.0:
						#blinkCycle = 0.5;
					#if time <= 11.0:
						#blinkCycle = 0.25;
					#if time <= 6:
						#blinkCycle = 0.15;
					if time <= 0:
						GameState.get_player().die();
						pause();
	else:
		text = "";
		TimerBlinky.visible = false;

func blink():
	if GameState.get_in_state_of_play():
		SND.play_sound_nondirectional("Bip", 1.15);
		blinkTimer = 0.10;
		var player = GameState.get_player();
		var particlePos := Vector3(randf_range(0.5,-0.5),randf_range(0.5,-0.5),randf_range(0.5,-0.5));
		particlePos += player.body.global_position;
		ParticleFX.play("SmokePuffSingleDark", GameState.get_game_board(), particlePos);
		TextFunc.flyaway(text, particlePos, "inaffordable")

func add_time(_time:float):
	time += _time;

func pause(enable:=true):
	paused = enable;

func start(_startTime := 120.0, _reset := false):
	pause(true);
	if _reset:
		time = 0.0;
	add_time(_startTime);
	pause(false);

func get_time() -> float:
	return time;
