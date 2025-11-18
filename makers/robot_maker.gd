extends MakerMode

class_name MakerMode_Robots

@export_category("Node Refs")
@export var manager : MakerModeManager;
@export var txt_botName : TextEdit;
@export var txt_botNameInternal : TextEdit;
@export_subgroup("Camera")

@export_subgroup("Labels")
@export var lbl_filepathName : Label;

@export_subgroup("Trees")
@export var tree_robot : Tree;
@export var tree_pieces : Tree;
@export var tree_parts : Tree;

@export_subgroup("Engine")
@export var engine : PartsHolder_Engine;
@export var inspector : Inspector;
@export var abilitiesManager : AbilitySlotManager;
@export var dataPanel : StatAdjusterDataPanel;

var curRobotData;

func _ready():
	initialize();

func initialize():
	get_robots();
	get_pieces();
	get_parts();

func exit():
	super();
	open_save_popup(false);
	clear_inspected_robot();
	pass;

func enter():
	super();
	initialize();

func enable_textEdits():
	txt_botName.editable = true;
	txt_botNameInternal.editable = true;
func disable_textEdits():
	txt_botName.editable = false;
	txt_botNameInternal.editable = false;

func _on_robot_tree_item_activated():
	var mousePos = get_viewport().get_mouse_position() - tree_robot.position
	var itemAtPos : TreeItem = tree_robot.get_item_at_position(mousePos);
	if is_instance_valid(itemAtPos):
		print(itemAtPos.get_text(0))
		print(itemAtPos.get_metadata(0))
		var data = itemAtPos.get_metadata(0)
		if data is Dictionary:
			print(data)
			##Clear out the old.
			clear_inspected_robot();
			#set_inspected_piece(data);
			##In with the new.
			curRobotData = data;
			spawn_inpspected_robot(data);
	pass # Replace with function body.

func refresh_current_robot():
	##Clear out the old.
	clear_inspected_robot();
	if is_instance_valid(curRobotData):
		spawn_inpspected_robot(curRobotData);

func _on_pieces_tree_item_activated():
	var mousePos = get_viewport().get_mouse_position() - tree_pieces.position
	var itemAtPos : TreeItem = tree_pieces.get_item_at_position(mousePos);
	print(itemAtPos.get_text(0))
	print(itemAtPos.get_metadata(0))
	var data = itemAtPos.get_metadata(0)
	if data is Dictionary:
		print(data)
		#set_inspected_piece(data);
		
		if is_instance_valid(botBeingInspected):
			if data.has("node"):
				var node = data.node;
				var path = data.filepath;
				var instance = node.instantiate();
				if instance is Piece:
					instance.filepathForThisEntity = path;
					botBeingInspected.add_something_to_stash(instance)
					regenerate_stash(PieceStash.modes.ALL);
					print(botBeingInspected.stashParts)
	
	pass # Replace with function body.

func _on_parts_tree_item_activated():
	pass # Replace with function body.

##Adds a Piece node to the tree. Needs the text, the node's PackedScene, and the original filepath.
func add_to_tree(tree : Tree, text, node, filepath):
	var child = tree.create_item()
	child.set_metadata(0, {"node" : node, "filepath" : filepath});
	child.set_text(0, str(text));

##Resets the list of viewed Pieces.
func get_pieces():
	
	tree_pieces.clear();
	var child = tree_pieces.create_item();
	child.set_text(0, "Pieces");
	child.set_metadata(0, generate_new_piece());
	
	var prefix = manager.filepathPrefixPieces
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
					add_to_tree(tree_pieces, file_name, loadedFile, fullName);
			file_name = dir.get_next()
			
	else:
		print("An error occurred when trying to access the path.")

func generate_new_piece():
	var newData = {
		"node" : manager.newPieceRef,
		"filepath" : "res://scenes/prefabs/objects/pieces/piece_test.tscn",
	}
	return newData;

func get_parts():
	##TODO: Parts rework
	pass;

##Resets the list of viewed Robots.
func get_robots():
	tree_robot.clear();
	var child = tree_robot.create_item();
	child.set_text(0, "Robots");
	child.set_metadata(0, generate_new_robot());
	
	var prefix = manager.filepathPrefixRobots
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
				if FileAccess.file_exists(fullName):
					var loadedFile = load(fullName);
					add_to_tree(tree_robot, file_name, loadedFile, fullName);
			file_name = dir.get_next()
			
	else:
		print("An error occurred when trying to access the path.")

func generate_new_robot():
	var newData = {
		"node" : manager.newRobotRef,
		"filepath" : "res://scenes/prefabs/objects/robots/buildingBlocks/robot_base.tscn",
	}
	return newData;

var botSceneFilePath : String;
var botSceneBeingInspected : PackedScene;
var botBeingInspected : Robot;

@export_subgroup("World")
@export var botSpawnPoint : Node3D;

## Given a [Dictionary]. Format is { "node" : [PackedScene], "filepath" : original filepath }
func spawn_inpspected_robot(data):
	#open_save_popup(false);
	
	var botRef = data.node;
	var botFilePath = data.filepath;
	if ! botRef is PackedScene: return;
	
	
	##Clear out the old.
	clear_inspected_robot();
	
	var newBot = botRef.instantiate();
	if newBot is Robot:
		
		##Set the new scene and bot.
		botSceneBeingInspected = botRef;
		botBeingInspected = newBot;
		botSceneFilePath = botFilePath;
		print("SCENE POATH ", botSceneFilePath);
		
		#print("SAVE: Loading Bot data: ", botBeingInspected.startupGenerator)
		#print("SAVE: Loading Bot data: ", botBeingInspected.startupGenerator)
		
		botBeingInspected.filepathForThisEntity = botFilePath;
		
		###Change the filepath text.
		lbl_filepathName.text = botFilePath;
		#
		###Change the piece name text.
		txt_botName.text = botBeingInspected.robotName;
		txt_botNameInternal.text = botBeingInspected.robotNameInternal;
		#txt_pieceDescription.text = newPiece.pieceDescription;
		
		if newBot is Robot_Player:
			newBot.engineViewer = engine;
		
		newBot.inspectorHUD = inspector;
		abilitiesManager.currentRobot = newBot;
		dataPanel.assign_new_thing(newBot);
		
		botSpawnPoint.add_child(botBeingInspected);
		##Show the thing.
		botBeingInspected.show();
		
		print("SAVE: Loading Bot data: ", botBeingInspected.startupGenerator)
		botBeingInspected.load_from_startup_generator();
	return botBeingInspected;


func clear_inspected_robot():
	botSceneFilePath = "";
	botSceneBeingInspected = null;
	if is_instance_valid(botBeingInspected):
		botBeingInspected.queue_free();
	botBeingInspected = null;
	lbl_filepathName.text = "[No Piece selected]";
	pass;

func get_inspected_robot() -> Robot:
	if is_instance_valid(botBeingInspected):
		return botBeingInspected;
	return null;

##Regenerates the stash viewer when called.
##@deprecated: The stash is updated by the robot pretty regularly, I [i]think...[/i]
func regenerate_stash(mode : PieceStash.modes):
	if is_instance_valid(botBeingInspected):
		inspector.regenerate_stash(botBeingInspected, mode);
	else:
		inspector.regenerate_stash(botBeingInspected, PieceStash.modes.NONE);

func _on_piece_stash_piece_button_clicked(tiedPiece):
	if is_instance_valid(botBeingInspected):
		botBeingInspected.prepare_pipette(tiedPiece);
	pass # Replace with function body.

func _on_piece_stash_part_button_clicked(tiedPart):
	pass # Replace with function body.


@export_subgroup("Confirm Save Popup")
@export var save_txt_newPath : TextEdit;
@export var save_txt_oldPath : TextEdit;
@export var save_lbl_success : Label;
@export var newPathPrefix : Label;
@export var ConfirmSavePopup : Control;
@export var btn_cancelSave : Button;
@export var btn_saveAs : Button;

var filepathPrefix = "res://scenes/prefabs/objects/robots/";


##Actually saves the stuff. Saves the scene as a Robot; deletes all Collision copies, hides it, saves it, then regenerates collision and shows it again.
func _on_save_changes_as_pressed():
	var savedPath = filepathPrefix + save_txt_newPath.text + ".tscn"
	
	if is_valid_to_save():
		var saveNode = PackedScene.new()
		var bot = get_inspected_robot();
		
		
		bot.filepathForThisEntity = savedPath;
		
		bot.name = "Robot_" + txt_botNameInternal.text;
		
		bot.prepare_to_save();
		
		#
		print("SAVE: Bot data: ", bot.startupGenerator)
		
		saveNode.pack(bot);
		#
		#
		ResourceSaver.save(saveNode, savedPath);
		#
		#
		refresh_current_robot();
		#pieceBeingInspected.show();
		#pieceBeingInspected.refresh_and_gather_collision_helpers();
		#
		get_robots();
		get_pieces();
		TextFunc.set_text_color(save_lbl_success, "utility");
		save_lbl_success.text = "Saved Successfully to " + savedPath
		save_lbl_success.show();
		#
		#
		pass;
	else:
		TextFunc.set_text_color(save_lbl_success, "melee");
		save_lbl_success.text = "Saved Unsuccessfully to " + savedPath
		save_lbl_success.show();
		pass;
	#
	#get_pieces();
	pass # Replace with function body.

var savePopupIsOpen
func is_valid_to_save():
	return (save_txt_oldPath.text != "" && save_txt_oldPath.text != null) and (get_inspected_robot() != null && botSceneFilePath != null);

func open_save_popup(open : bool):
	savePopupIsOpen = open;
	if open:
		##Old path text
		save_txt_oldPath.text = botSceneFilePath;
		print("OLD FILEPATH: ", botSceneFilePath)
		##New path text
		newPathPrefix.text = filepathPrefix;
		save_txt_newPath.text = "robot_test";
		btn_cancelSave.disabled = false;
		btn_saveAs.disabled = false;
		ConfirmSavePopup.show();
		save_lbl_success.hide();
		if not is_valid_to_save():
			TextFunc.set_text_color(save_lbl_success, "melee");
			save_lbl_success.text = "Robot cannot be saved. Check that you have a chassis spawned in.";
			save_lbl_success.show();
			btn_saveAs.disabled = true;
	else:
		ConfirmSavePopup.hide();
		save_lbl_success.hide();
		btn_cancelSave.disabled = true;
		btn_saveAs.disabled = true;
		refresh_current_robot();

func _on_cancel_save_pressed():
	open_save_popup(false);
	pass # Replace with function body.

##"Save" button. Opens a confirmation popup.
func _on_save_changes_pressed():
	
	open_save_popup(true);
	pass # Replace with function body.

@export_subgroup("Abilities")
@export var tree_abilities : Tree;

func update_abilities_tree():
	tree_abilities.clear();
	
	var child = tree_abilities.create_item();
	child.set_text(0, "Abilities");
	
	var bot = get_inspected_robot();
	if bot != null:
		#print("Updating ability viewer")
		for abilityKey in bot.active_abilities.keys():
			var ability = bot.active_abilities[abilityKey];
			var child2 = tree_abilities.create_item(child)
			var abilityText = "Slot " + str(abilityKey) + ": "
			if is_instance_valid(ability):
				abilityText += ability.abilityName;
			else:
				abilityText += "Empty";
			child2.set_text(0, abilityText);
	
		bot.update_hud(true);
		regenerate_stash(PieceStash.modes.ALL);

var abilityViewerRefresh := 0;
func _process(delta):
	abilityViewerRefresh -= 1;
	if abilityViewerRefresh < 0:
		abilityViewerRefresh = 20;
		update_abilities_tree();

func _on_robot_name_text_changed():
	var bot = get_inspected_robot();
	if bot != null:
		bot.robotName = txt_botName.text;
		bot.robotNameInternal = txt_botNameInternal.text;
		bot.name = "Robot_" + txt_botNameInternal.text;
	pass # Replace with function body.

func _on_copy_name_pressed():
	save_txt_newPath.text = botSceneFilePath.trim_prefix(filepathPrefix).trim_suffix(".tscn");
	pass # Replace with function body.
