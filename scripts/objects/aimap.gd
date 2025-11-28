extends Node3D
class_name AIMap;

# Array of Vector3s, points where the raycasts collide with the arena floor.
# These points are actually the nodes. The raycasts are just meant to find
# the exact point on the ground.
var ai_nodes = [];
var ainode = preload("res://scenes/prefabs/utilities/ainode.tscn");

func _ready() -> void:
	var castContainer = get_node("Raycasts");
	var raycasts = castContainer.get_children();
			
func _process(delta : float) -> void:
	# doing this on _ready dosn't work
	var castContainer = get_node("Raycasts");
	var raycasts = castContainer.get_children();
	if raycasts.size() > 0:
		for raycast in raycasts:
			#print("RAYCAST LOOP ", raycast.is_colliding(), " ", raycast.is_enabled())
			if raycast.is_enabled() && raycast.is_colliding():
				var newAinode = ainode.instantiate();
				add_child(newAinode);
				newAinode.reparent(self);
				newAinode.set_position(raycast.get_collision_point())
				#print("we've made an instance!!sssa")
				raycast.queue_free();
				raycast.set_enabled(false);
