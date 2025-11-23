extends GridMap

class_name ArenaObstacleGrid

@export var wallPiecesSceneFolder := "res://scenes/prefabs/arenas/wall-pieces/"
var built := false;
var started := false;

var cells = [];
## Starts the building sequence. Returns the amount of cells to build.
func start_building_sequence() -> int:
	cells = get_used_cells();
	started = true;
	built = false;
	return cells.size() + 1;

func _process(_delta):
	if cells.size() > 0:
		built = false;
		var tileCoord = cells.pop_front();
		var tileIDX = get_cell_item(tileCoord);
		var tileName = mesh_library.get_item_name(tileIDX);
		var tileOrientation = get_cell_item_orientation(tileCoord);
		var fileNameToCheck = str(wallPiecesSceneFolder, tileName.to_snake_case(), ".tscn");
		if FileAccess.file_exists(fileNameToCheck):
			print("STATE: ADDING ", tileName, " WITH ORIENTATION ", tileOrientation);
			var newThing = load(fileNameToCheck).instantiate();
			set_cell_item(tileCoord, INVALID_CELL_ITEM);
			add_child(newThing);
			#newThing.rotation = tileOrientation;
			var pos = to_global(map_to_local(tileCoord));
			newThing.global_position = pos;
			Utils.rotate_using_gridmap_orientation(newThing, tileOrientation);
	else:
		if started:
			built = true;
