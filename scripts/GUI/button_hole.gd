@tool
extends TextureRect
class_name ButtonHole

@export_tool_button("Update Size") var updateAction = update

func _ready():
	update();
	
	var parent = get_parent();
	if ! parent is Button: 
		queue_free(); 
		return;
	
	parent.connect("resized", update);

func update():
	var parent = get_parent();
	if ! parent is Button: 
		queue_free(); 
		return;
	var targetSize = parent.size + Vector2(2, -4);
	size = targetSize;
	var targetPosition = parent.global_position + Vector2(-1, 4)
	global_position = targetPosition;
	z_index = -1;
