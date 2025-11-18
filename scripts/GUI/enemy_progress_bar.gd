extends Control

class_name EnemyProgressBar

var updateTimer := 0.0;
var progress := 0.0;
var progressBarTargetX := 24.0;
@onready var length := float(size.x);
var isOnRight := false;

var buttonModeSwitchCounter = 0;
var buttonMode:= true;
var buttonScreenOff = preload("res://graphics/images/HUD/nextRound/screen_off.png");
var buttonScreenOnA = preload("res://graphics/images/HUD/nextRound/screen_on.png");
var buttonScreenOnB = preload("res://graphics/images/HUD/nextRound/screen_onB.png");
var buttonScreenOnLoadShop = preload("res://graphics/images/HUD/nextRound/screen_on_shopping.png");
var buttonScreenOnLoadShopB = preload("res://graphics/images/HUD/nextRound/screen_on_shoppingB.png");
var buttonScreenOnGameOver = preload("res://graphics/images/HUD/nextRound/screen_on_gameOver.png");
var buttonScreenOnGameOverB = preload("res://graphics/images/HUD/nextRound/screen_on_gameOverB.png");

@export var nextWaveButton_gfx : TextureButton;
@export var nextWaveButton_big : Button;
@export var progressBar : TextureRect;
@export var Lbl_EnemiesLeft : Label;
@export var Lbl_NextRound : Label;

func _process(delta):
	if updateTimer > 0:
		updateTimer -= delta;
	else:
		updateTimer = 0.10
		#prints(progress)
		update();
	
	
	progress = clamp(progress, 0.0, 1.0);
	progressBarTargetX = (1.0 - progress) * -length;
	progressBar.position.x = move_toward(progressBar.position.x, progressBarTargetX, delta * 340);

func update():
	isOnRight = is_equal_approx(progressBar.position.x, 0);
	#print(progressBar.position.x)
	
	##Makes the 'go' button flash fancy-like
	if buttonModeSwitchCounter >= 2:
		if buttonMode:
			buttonMode = false;
		else:
			buttonMode = true;
		buttonModeSwitchCounter = 0;
	else:
		buttonModeSwitchCounter +=1;
	
	if GameState.get_in_state_of_play():
		progressBar.visible = true;
		#print(length)
		#print(progress)
		if GameState.get_in_state_of_shopping(false):
			nextWaveButton_gfx.disabled = false;
			nextWaveButton_big.disabled = false;
			
		
			##Makes the 'go' button flash fancy-like
			if buttonMode:
				nextWaveButton_gfx.set_deferred("texture_normal", buttonScreenOnB)
			else:
				nextWaveButton_gfx.set_deferred("texture_normal", buttonScreenOnA)
			
			var board = GameState.get_game_board();
			if nextWaveButton_big.button_pressed or board.queuedShopLeave:
				progress = 1.0;
				
				if isOnRight and not board.queuedShopLeave:
					go_to_next_round();
				
				Lbl_NextRound.text = ">>>>>>>>>>>>>>>>>>>> ONTO ROUND";
				Lbl_EnemiesLeft.text = str(GameState.get_round_number() + 1);
				
			else:
				progress = 0.0;
				Lbl_NextRound.text = "ONTO ROUND";
				Lbl_EnemiesLeft.text = str(GameState.get_round_number() + 1);
		elif GameState.get_in_one_of_given_states([GameBoard.gameState.GOTO_SHOP]):
			progress = 0;
			nextWaveButton_gfx.disabled = true;
			nextWaveButton_big.disabled = true;
			
			nextWaveButton_gfx.set_deferred("texture_normal", buttonScreenOnLoadShopB)
			nextWaveButton_gfx.set_deferred("texture_disabled", buttonScreenOnLoadShopB)
			
			Lbl_NextRound.text = "";
			Lbl_EnemiesLeft.text = "";
		elif GameState.get_in_one_of_given_states([GameBoard.gameState.INIT_SHOP]):
			progress = 0;
			nextWaveButton_gfx.disabled = true;
			nextWaveButton_big.disabled = true;
			
			nextWaveButton_gfx.set_deferred("texture_normal", buttonScreenOnLoadShop)
			nextWaveButton_gfx.set_deferred("texture_disabled", buttonScreenOnLoadShop)
			
			Lbl_NextRound.text = "";
			Lbl_EnemiesLeft.text = "";
		elif GameState.get_in_one_of_given_states([GameBoard.gameState.LOAD_SHOP]):
			progress = 0;
			nextWaveButton_gfx.disabled = true;
			nextWaveButton_big.disabled = true;
			
			nextWaveButton_gfx.set_deferred("texture_normal", buttonScreenOnLoadShopB)
			nextWaveButton_gfx.set_deferred("texture_disabled", buttonScreenOnLoadShopB)
			
			Lbl_NextRound.text = "";
			Lbl_EnemiesLeft.text = "";
		elif GameState.get_in_state_of_combat(true): ## Main game mode.
			progress = GameState.get_round_completion();
			nextWaveButton_gfx.disabled = true;
			nextWaveButton_big.disabled = true;
			var enemiesLeft = GameState.get_wave_enemies_left();
			
			Lbl_NextRound.text = "ENEMIES REMAINING:";
			Lbl_EnemiesLeft.text = str(enemiesLeft);
			
			nextWaveButton_gfx.set_deferred("texture_disabled", buttonScreenOff);
	elif GameState.get_in_game_over_state():
		nextWaveButton_gfx.disabled = true;
		nextWaveButton_big.disabled = true;
		Lbl_EnemiesLeft.text = "";
		Lbl_NextRound.text = "";
		progress = 0;
		if buttonMode:
			nextWaveButton_gfx.set_deferred("texture_disabled", buttonScreenOnGameOverB)
		else:
			nextWaveButton_gfx.set_deferred("texture_disabled", buttonScreenOnGameOver)
	else:
		nextWaveButton_gfx.disabled = true;
		nextWaveButton_big.disabled = true;
		nextWaveButton_gfx.set_deferred("texture_disabled", buttonScreenOff);
		Lbl_EnemiesLeft.text = "";
		Lbl_NextRound.text = "";
		progress = 0;
	

var nextWaveButtonPressed := false;
##@deprecated: 
func _on_next_wave_button_pressed():
	#go_to_next_round()
	pass # Replace with function body.

func _on_next_wave_button_button_down():
	pass # Replace with function body.

func _on_next_wave_button_button_up():
	pass # Replace with function body.

func go_to_next_round():
	var board = GameState.get_game_board();
	board.queue_shop_exit();
