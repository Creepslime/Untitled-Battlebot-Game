@icon("res://graphics/images/class_icons/partButton.png")
extends Control

class_name PartButtonHolder;

var part : Part;
@export var buttonPrefab : PackedScene;
var selected;
var regenButtons := false;
var buttons : Array[PartButton]:
	get:
		if buttons.is_empty() or regenButtons:
			var buttonID = 0;
			regenButtons = false;
			var children = get_children();
			var ret : Array[PartButton] = [];
			for child in children:
				if child is PartButton:
					ret.append(child);
					child.buttonHolder = self;
					child.ID = buttonID;
					buttonID += 1;
			buttons = ret;
		return buttons;

signal on_select(foo:bool)

func clear_buttons():
	for button in buttons:
		if is_instance_valid(button):
			button.queue_free();
	buttons.clear();

func _process(delta):
	for button in buttons:
		button.selectGFXon = selected;

func set_pressed(foo:bool, doSignal := true):
	for button in buttons:
		button.select(foo);
	selected = foo;
	if doSignal:
		#prints("BUTTON HOLDER FOO:", foo)
		on_select.emit(foo);

func disable(_disabled:=true):
	for button in buttons:
		button.disabled = _disabled;

func move_mode_enable(enable:bool):
	for button in buttons:
		button.move_mode(enable, true);
		if enable:
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE;
		else:
			button.mouse_filter = Control.MOUSE_FILTER_STOP;
