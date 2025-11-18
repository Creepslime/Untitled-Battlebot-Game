extends MakerMode

class_name MakerMode_Pieces

func exit():
	clear_inspected_piece();

## A billion export variables.


@export_category("Node refs")

@export var manager : MakerModeManager;

@export_subgroup("Engine customizers")

@export var engine : PartsHolder_Engine;

@export var A1 : CheckBox;
@export var A2 : CheckBox;
@export var A3 : CheckBox;
@export var A4 : CheckBox;
@export var A5 : CheckBox;

@export var B1 : CheckBox;
@export var B2 : CheckBox;
@export var B3 : CheckBox;
@export var B4 : CheckBox;
@export var B5 : CheckBox;

@export var C1 : CheckBox;
@export var C2 : CheckBox;
@export var C3 : CheckBox;
@export var C4 : CheckBox;
@export var C5 : CheckBox;

@export var D1 : CheckBox;
@export var D2 : CheckBox;
@export var D3 : CheckBox;
@export var D4 : CheckBox;
@export var D5 : CheckBox;

@export var E1 : CheckBox;
@export var E2 : CheckBox;
@export var E3 : CheckBox;
@export var E4 : CheckBox;
@export var E5 : CheckBox;

@export_subgroup("Socket")
@export var pieceHolder : Socket;

var pieceSceneFilePath : String;
var pieceSceneBeingInspected : PackedScene;
var pieceBeingInspected : Piece;

@export var lbl_filepathName : Label;
@export_subgroup("Piece data")
@export var txt_pieceName : TextEdit;
@export var txt_pieceDescription : TextEdit;
@export var pieceDataPanel : StatAdjusterDataPanel;
@export_subgroup("Tree")
@export var tree : Tree;

## Given a [Dictionary]. Format is { "node" : [PackedScene], "filepath" : original filepath }
func set_inspected_piece(data):
	
	open_save_popup(false);
	
	var pieceRef = data.node;
	var pieceFilePath = data.filepath;
	if ! pieceRef is PackedScene: return;
	
	var newPiece = pieceRef.instantiate();
	if newPiece is Piece:
		##Clear out the old.
		clear_inspected_piece();
		
		##Set the new scene and piece.
		pieceSceneBeingInspected = pieceRef;
		pieceBeingInspected = newPiece;
		pieceSceneFilePath = pieceFilePath;
		
		##Show the thing.
		pieceBeingInspected.show();
		
		##Change the filepath text.
		lbl_filepathName.text = pieceFilePath;
		
		##Change the piece name text.
		txt_pieceName.text = newPiece.pieceName;
		txt_pieceDescription.text = newPiece.pieceDescription;
		
		pieceHolder.add_child(pieceBeingInspected);
		pieceHolder.add_occupant(pieceBeingInspected);
		pieceBeingInspected.force_visibility = true;
		generate_coordinates_from_piece(pieceBeingInspected);
		pieceDataPanel.assign_new_thing(pieceBeingInspected);
	return pieceBeingInspected;

func reset_inspected_piece():
	set_inspected_piece(pieceSceneBeingInspected);

func clear_inspected_piece():
	##Clear everything out.
	pieceHolder.remove_occupant(true);
	clear_coordinates();
	if is_instance_valid(pieceBeingInspected):
		pieceBeingInspected.queue_free();
	pieceSceneBeingInspected = null;
	lbl_filepathName.text = "[No Piece selected]";

var filepathPrefix = "res://scenes/prefabs/objects/pieces/"


func _on_piece_name_text_changed():
	if is_instance_valid(pieceBeingInspected):
		var text = txt_pieceName.text;
		pieceBeingInspected.name = "Piece_" + text;
		pieceBeingInspected.pieceName = text;
		
		var desc = txt_pieceDescription.text;
		if desc == "":
			desc = "No Description Found.";
		pieceBeingInspected.pieceDescription = desc;
	pass # Replace with function body.

@export_subgroup("Camera")
@export var camHolder : Node3D;
@export var makerCamera : MakerCamera;
@export var followerCamera : FollowerCamera;

func _on_piece_name_mouse_entered():
	manager.disable_camera();
	
	txt_pieceName.editable = true;
	txt_pieceDescription.editable = true;
	pass # Replace with function body.

func _on_piece_name_mouse_exited():
	manager.enable_camera();
	
	txt_pieceName.editable = false;
	
	txt_pieceDescription.editable = false;
	var desc = txt_pieceDescription.text;
	if desc == "":
		txt_pieceDescription.text = "No Description Found.";
	pass # Replace with function body.

##Resets the list of viewed Pieces.
func get_pieces():
	tree.clear();
	var child = tree.create_item();
	child.set_text(0, "Pieces");
	child.set_metadata(0, generate_new_piece());
	
	var prefix = filepathPrefix
	var dir = DirAccess.open(prefix)
	var dirBase = DirAccess.open("res://")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				print("Found file: " + file_name)
				
				var fullName = prefix + file_name
				print(fullName)
				if (fullName.ends_with(".tscn")) and FileAccess.file_exists(fullName):
					var loadedFile = load(fullName);
					add_to_tree(file_name, loadedFile, fullName);
			file_name = dir.get_next()
			
	else:
		print("An error occurred when trying to access the path.")


func _ready():
	open_save_popup(false);
	get_pieces();
	##var tree = Tree.new()
	#var tree = tree
	#var root = tree.create_item()
	#tree.hide_root = true
	#var child1 = tree.create_item(root)
	#var child2 = tree.create_item(root)
	#var subchild1 = tree.create_item(child1)
	#subchild1.set_text(0, "Subchild1")


##Adds a Piece node to the tree. Needs the text, the node's PackedScene, and the original filepath.
func add_to_tree(text, node, filepath):
	var child = tree.create_item()
	child.set_metadata(0, {"node" : node, "filepath" : filepath});
	child.set_text(0, str(text));

func _on_tree_item_activated():
	var mousePos = get_viewport().get_mouse_position() - tree.position
	var itemAtPos : TreeItem = tree.get_item_at_position(mousePos);
	print(itemAtPos.get_text(0))
	print(itemAtPos.get_metadata(0))
	var data = itemAtPos.get_metadata(0)
	if data is Dictionary:
		set_inspected_piece(data);
	pass # Replace with function body.


@onready var coordinateMapper = {
	## Row 0
	A1 : Vector2i(0,0),
	A2 : Vector2i(1,0),
	A3 : Vector2i(2,0),
	A4 : Vector2i(3,0),
	A5 : Vector2i(4,0),
	## Row 1
	B1 : Vector2i(0,1),
	B2 : Vector2i(1,1),
	B3 : Vector2i(2,1),
	B4 : Vector2i(3,1),
	B5 : Vector2i(4,1),
	## Row 2
	C1 : Vector2i(0,2),
	C2 : Vector2i(1,2),
	C3 : Vector2i(2,2), 
	C4 : Vector2i(3,2),
	C5 : Vector2i(4,2),
	## Row 3
	D1 : Vector2i(0,3),
	D2 : Vector2i(1,3),
	D3 : Vector2i(2,3),
	D4 : Vector2i(3,3),
	D5 : Vector2i(4,3),
	## Row 4
	E1 : Vector2i(0,4),
	E2 : Vector2i(1,4),
	E3 : Vector2i(2,4),
	E4 : Vector2i(3,4),
	E5 : Vector2i(4,4),
}

func clear_coordinates():
	engine.close_and_clear();

##Fills the engine with the piece's engine slots.
func generate_coordinates_from_piece(inPiece : Piece):

	var tilesArray : Array[Vector2i] = [];
	print(inPiece.engineSlots);
	var piece_engine = inPiece.engineSlots;
	#if piece_engine[]
	for slot in coordinateMapper.keys():
		if slot is CheckBox:
			var coord = coordinateMapper[slot];
			slot.button_pressed = coord in piece_engine.keys();
			tilesArray.append(coord);
	#pieceRef.
	##pieceRef.
	
	##Engine setup.
	engine.open_with_new_piece(inPiece);
	pass;

var frameCounter = 5;
func _process(delta):
	if frameCounter > 0:
		frameCounter -= 1;
	else:
		frameCounter = 5;
		var checks = check_and_get_checks();
		#print(checks)
		set_engine_pattern(checks);

## Returns an array of all the coordinates currently checked by the engine checkboxes.
func check_and_get_checks()->Array[Vector2i]:
	var checkedButtonArray : Array[Vector2i] = [];
	for slot in coordinateMapper.keys():
		#print(slot)
		if slot is CheckBox:
			var coord = coordinateMapper[slot];
			if slot.button_pressed:
				checkedButtonArray.append(coord);
	return checkedButtonArray;

func _on_reset_tree_pressed():
	get_pieces();
	pass # Replace with function body.


func _on_clear_preview_pressed():
	clear_inspected_piece();
	engine.close();
	pass # Replace with function body.

##"Save" button. Opens a confirmation popup.
func _on_save_changes_pressed():
	open_save_popup(true);
	pass # Replace with function body.


@export_subgroup("Confirm Save Popup")
@export var save_txt_newPath : TextEdit;
@export var save_txt_oldPath : TextEdit;
@export var save_lbl_success : Label;
@export var newPathPrefix : Label;
@export var ConfirmSavePopup : Control;
@export var btn_cancelSave : Button;
@export var btn_saveAs : Button;

##Actually saves the stuff. Saves the scene as a Piece; deletes all Collision copies, hides it, saves it, then regenerates collision and shows it again.
func _on_save_changes_as_pressed():
	var savedPath = filepathPrefix + save_txt_newPath.text + ".tscn"
	if pieceBeingInspected != null && pieceSceneFilePath != null:
		var saveNode = PackedScene.new()
		
		pieceBeingInspected.reset_collision_helpers();
		pieceBeingInspected.hide();
		pieceBeingInspected.name = "Piece_" + txt_pieceName.text;
		
		
		saveNode.pack(pieceBeingInspected);
		
		
		ResourceSaver.save(saveNode, savedPath);
		
		
		pieceBeingInspected.show();
		pieceBeingInspected.refresh_and_gather_collision_helpers();
		
		get_pieces();
		TextFunc.set_text_color(save_lbl_success, "utility");
		save_lbl_success.text = "Saved Successfully to " + savedPath
		save_lbl_success.show();
		
		
	else:
		TextFunc.set_text_color(save_lbl_success, "melee");
		save_lbl_success.text = "Saved Unsuccessfully to " + savedPath
		save_lbl_success.show();
	
	get_pieces();
	pass # Replace with function body.

var savePopupIsOpen

func open_save_popup(open : bool):
	savePopupIsOpen = open;
	if open:
		##Old path text
		save_txt_oldPath.text = pieceSceneFilePath;
		##New path text
		newPathPrefix.text = filepathPrefix;
		save_txt_newPath.text = "piece_test";
		btn_cancelSave.disabled = false;
		btn_saveAs.disabled = false;
		ConfirmSavePopup.show();
		save_lbl_success.hide();
	else:
		ConfirmSavePopup.hide();
		save_lbl_success.hide();
		btn_cancelSave.disabled = true;
		btn_saveAs.disabled = true;

func _on_cancel_save_pressed():
	open_save_popup(false);
	pass # Replace with function body.

func _on_copy_name_pressed():
	save_txt_newPath.text = pieceSceneFilePath.trim_prefix(filepathPrefix).trim_suffix(".tscn");
	pass # Replace with function body.

func set_engine_pattern(tilesArray : Array[Vector2i]):
	engine.queue_pattern(tilesArray);
	if is_instance_valid(pieceBeingInspected):
		pieceBeingInspected.engineSlots = {}
		for tile in tilesArray:
			pieceBeingInspected.engineSlots[tile] = null;

##Creates a new piece from the void.
func _on_new_piece_pressed():
	set_inspected_piece(generate_new_piece());
	pass # Replace with function body.

func generate_new_piece():
	var newData = {
		"node" : manager.newPieceRef,
		"filepath" : "res://scenes/prefabs/objects/pieces/piece_test.tscn",
	}
	return newData;


func _on_select_unselect_all_pressed():
	var check = check_and_get_checks();
	if len(check) > 0:
		for slot in coordinateMapper.keys():
			if slot is CheckBox:
				slot.button_pressed = false;
	else:
		for slot in coordinateMapper.keys():
			if slot is CheckBox:
				slot.button_pressed = true;
		
	pass # Replace with function body.
