extends Control

class_name PartButtonHolder;

var part : Part;
@export var buttonPrefab : PackedScene;
var selected;

signal on_select(foo:bool)

func _process(delta):
	for button in get_children():
		button.selectGFXon = selected;

func set_pressed(foo:bool, doSignal := true):
	for button in get_children():
		button.select(foo);
	selected = foo;
	if doSignal:
		on_select.emit(foo);

func disable(_disabled:=true):
	for button in get_children():
		button.disabled = _disabled;

func move_mode_enable(enable:bool):
	for button in get_children():
		if button is PartButton:
			if enable:
				button.mouse_filter = Control.MOUSE_FILTER_IGNORE;
			else:
				button.mouse_filter = Control.MOUSE_FILTER_STOP;
