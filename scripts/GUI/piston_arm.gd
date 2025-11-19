@tool
extends NinePatchRect
class_name ButtonPistonArm

@export_tool_button("Update") var updateAction = update

func _ready():
	if ! get_parent() is Button:
		queue_free();
		return;
	get_parent().connect("button_down", button_down);
	get_parent().connect("button_up", button_up);
	get_parent().connect("pressed", pressed);
	get_parent().connect("toggled", toggled);
	global_position.y = get_parent().global_position.y + get_parent().size.y - 2;
	
	update();

func button_down():
	update();

func button_up():
	update();

func pressed():
	update();

func toggled(toggled_on:bool):
	update();


const visibleStates = [
	Button.DrawMode.DRAW_NORMAL,
	Button.DrawMode.DRAW_HOVER,
]

func update():
	var parent = get_parent();
	if ! parent is Button:
		queue_free();
		return;
	
	visible = parent.get_draw_mode() in visibleStates;
	
	var targetPosY = parent.size.y - 2;
	position.y = targetPosY;
