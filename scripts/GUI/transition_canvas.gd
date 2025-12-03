@icon("res://graphics/images/class_icons/screenTransitionCanvas.png")
extends CanvasLayer

class_name TransitionCanvas

@export var transition : ScreenTransition;
@export var loadingGear : TextureRect;
@export var logo : TextureRect;
@export var lbl_companyName : Label;
@export var modulator : CanvasModulate;

var dbg_hidden := false;
var dbg_prof := false;
@export var debug_canvas : CanvasLayer;
@export var lbl_profiler : RichTextLabel;
@export var margin_profiler : MarginContainer;


func initialize():
	initialize_logo();
	transition.bring_to_center(true, true);
	layer = 5;

func initialize_logo():
	logoTime = true;
	time = 0.4;
	textSequenceFlip = false;
	textSequenceStep = 0;
	lbl_companyName.modulate.a = 1.0;
	checkingForLeaveSplash = false;
	lbl_companyName.text = "";
	lbl_companyName.show();

var logoTime = false;
var time = 0.4;
const timeBetweenCharacters := 0.12;
const timeAfterNewline := 0.17;
const timeBetweenBlinky := 0.2;
var checkingForLeaveSplash := false;
var textSequenceFlip := false;
var textSequenceStep = 0 ##STEP THRU TEXT

func _process(delta):
	dbg_hidden = GameState.get_setting("HiddenScreenTransitions");
	
	dbg_prof = GameState.get_setting("ProfilerLabelsVisible");
	if dbg_prof:
		debug_canvas.visible = true;
		if is_instance_valid(lbl_profiler):
			var profLabel = GameState.get_profiler_label();
			lbl_profiler.text = str(profLabel);
	else:
		debug_canvas.hide();
	
	if ! GameState.get_in_one_of_given_states([GameBoard.gameState.MAKER]):
		show();
		if dbg_hidden:
			modulator.color.a = 0.15;
		else:
			modulator.color.a = 1;
		
		if logoTime:
			lbl_companyName.visible = true;
			time -= delta;
			if time < 0:
				if ! transition.is_on_center():
					logoTime = false;
				else:
					textSequenceStep += 1;
					if textSequenceFlip:
						textSequenceFlip = false;
					else:
						textSequenceFlip = true;
					draw_logo_text();
		else:
			lbl_companyName.modulate.a = max(lbl_companyName.modulate.a- delta * 20, 0.0);
			if lbl_companyName.modulate.a == 0:
				lbl_companyName.hide();
		
		if checkingForLeaveSplash:
			if ! transition.is_on_center():
				logoTime = false;
	else:
		hide();

const LOGO_STRING = "METAL CHIMERA\n\nPRESENTING"

func draw_logo_text():
	var counter = textSequenceStep - 2;
	var text = "> ";
	var lastCharacter = "";
	for char in LOGO_STRING:
		counter -= 1;
		if counter > 0:
			lastCharacter = char;
			text += char;
			if char == "\n":
				text += "> "
	## If the counter is > 0 (we've overflowed) and the last character wasn't empty (we haven't gotten to real text yet) then play a sound.
	
	if !(counter > 0) and !(lastCharacter == ""):
		text += "_";
		SND.play_sound_nondirectional("Bip",0.6, 0.8);
		var randomPitch = randf_range(0.9,1.1);
		var volume = 1.0;
		if lastCharacter == "\n" or lastCharacter == " ":
			randomPitch -= 0.25;
			volume = 0.9;
			time += timeAfterNewline;
		else:
			time += timeBetweenCharacters;
		SND.play_sound_nondirectional("Button.Press",volume, randomPitch);
	else:
		if !textSequenceFlip:
			text += "_";
		time += timeBetweenBlinky;
	
	if (counter > 0):
		checkingForLeaveSplash = true;
	
	lbl_companyName.text = text;
