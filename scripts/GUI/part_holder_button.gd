@icon("res://graphics/images/class_icons/engine_selected.png")
extends TextureButton

class_name PartHolderButton
## Used by the [PartsHolder_Engine] to allow you to place [Part]s into the engines of a selected [Piece].

@export var coordX : int; ## The X position of this button inside the [PartsHolder_Engine].
@export var coordY : int; ## The Y position of this button inside the [PartsHolder_Engine].
var inventory : InventoryPlayer; ## @deprecated: The inventory of the [Player].
var parent : PartsHolder_Engine; ## The [PartsHolder_Engine] that holds dominion over this.
var available := true; ## Whether this is at all able to have things placed on it; Usually set when the tile is empty or not.

func _ready():
	parent = get_parent();
	if ! is_connected("pressed", _on_pressed):
		connect("pressed", _on_pressed);
	pass # Replace wi

## What happens when you press this button. Emits [signal PartHolderButton.buttonPressed] using [member coordX] and [member coordY] on [member parent].
func _on_pressed():
	parent.buttonPressed.emit(coordX,coordY);
	pass # Replace with function body.

## Sets the availability and disables accordingly.
func set_availability(foo):
	available = foo;
	disable(!foo)
	update_gfx();

@export var GFX_selected : Texture2D = preload("res://graphics/images/HUD/engine/inv_selectedPlugIn.png"); ## The sprite for being selected.
@export var GFX_unselected : Texture2D = preload("res://graphics/images/HUD/engine/inv_unselectedPlugIn.png"); ## The sprite for being not selected.
@export var GFX_unselectable : Texture2D = preload("res://graphics/images/HUD/engine/inv_unselectablePlugIn.png"); ## The sprite for not having room to fit a Part.

## [param selectable]: True makes it visible and fancy, False makes it invisible.
func set_textures(selectable:bool): 
	if selectable and available:
		texture_normal = GFX_unselected;
		texture_pressed = GFX_selected;
		texture_hover = GFX_selected;
		texture_disabled = GFX_unselectable;
	else:
		texture_normal = null;
		texture_pressed = null;
		texture_hover = null;
		texture_disabled = null;

## Sets [member disabled] and calls [method update_gfx].
func disable(_disabled:bool):
	disabled = _disabled;
	if disabled: button_pressed = false;
	update_gfx();

## Updates the graphical state of this button based on its availability and whether you have a [Part] in move mode and whether it would be able to fit, etc.
func update_gfx():
	var hideme := false;
	if available:
		disabled = false;
		#inventory = GameState.get_inventory(); #gets the inventory
		
		var space = true;
		var free = true;
		var piece = parent.referenceCurrent if parent.referenceCurrent != null else null;
		if is_instance_valid(piece):
			if piece.assignedToSocket:
				var hostRobot = piece.get_host_robot();
				if is_instance_valid(hostRobot): 
					if is_instance_valid(hostRobot.partMovementPipette):
						space = piece.engine_is_there_space_for_part(hostRobot.partMovementPipette, Vector2i(coordX,coordY));
						free = piece.engine_is_slot_free(coordX, coordY, hostRobot.partMovementPipette);
			else:
				space = false;
				free = false;
		
		##Always visible if there's space. If there's no space, it 
		if space:
			z_index = 100;
			set_textures(true);
			mouse_filter = Control.MOUSE_FILTER_STOP;
		else:
			if free:
				z_index = 100;
				set_textures(true);
				mouse_filter = Control.MOUSE_FILTER_IGNORE;
				disabled = true;
			else:
				hideme = true;
	else:
		hideme = true;
	
	if hideme:
		hide()
		disabled = true;
		set_textures(false); #Sets the sprite invisible
		mouse_filter = Control.MOUSE_FILTER_IGNORE; #makes the mouse not wanna click it
		z_index = 0; #makes it not draw over other stuff

## Checks each frame to see if the door to [member parent] is open. Hides the button and disables it if it isn't.
func _process(delta):
	if is_instance_valid(parent):
		if parent.check_in_state([PartsHolder_Engine.doorStates.OPEN]) and is_instance_valid(GameState.get_player_part_movement_pipette()):
			if ! visible:
				show();
		else:
			if visible:
				hide();
				disabled = true;
	else:
		hide();
		disabled = true;
