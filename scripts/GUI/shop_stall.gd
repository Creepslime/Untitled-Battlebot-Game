@icon("res://graphics/images/class_icons/shopStall.png")
extends Control
class_name ShopStall
## Holds the contents of the [ShopStation] this resides under, one [Piece] or [Part] at a time.

@export var leftDoor : TextureRect; ## The left-hand door node. 
@export var rightDoor : TextureRect; ## The right-hand door node.
@export var freezerDoor : TextureRect; ## The freezer door node.
@export var freezerBlinky : TextureRect; ## The light that blinks when contents are currently frozen.

var pieceRef : Piece; ## The currently referenced [Piece], if there is one in this stall.
var partRef : Part; ## The currently referenced [Part], if there is one in this stall.
var inventory : InventoryPlayer; ## @deprecated: The [Player]'s [Inventory].
var player : Robot_Player; ## The [Robot_Player] currently shopping.

var curState := ShopStall.doorState.NONE; ## The current [enum ShopStall.doorState] this stall is in.
var shopIsOpen := true; ## @experimental: Supposedly marks if the [ShopManager] this resides under is open; Doesn't do anything.

var doorsActuallyClosed := false; ## Not to be confused with [enum ShopStall.doorState.CLOSED]; This denotes whether the door to this stall is ACTUALLY closed, and reroll stuff is allowed to happen.[br]Gets set to true when the positions of the two doors reaches their fully closed ones during [enum ShopStall.doorState.CLOSED].

## The "ID" of this stall. Mainly used during [method set_up_piece_preview_pillar] to position [member node_PiecePreview], and by extension the titular pillar, in space correctly.
var stallID := -1:
	get:
		if stallID == -1:
			stallID = GameState.get_unique_shop_stall_id()
		return stallID;

@export var btn_buy : Button; ## The buy button.
@export var lbl_price : ScrapLabel; ## The [ScrapLabel] responsible for showing the current price.
@export var btn_freeze : Button; ## The button that freezes.

@export var bg_Piece : Control; ## Holds the background GFX for when a [Piece] is in the shop.
@export var node_PiecePreview : Node3D;
@export var btn_PieceSelect : Button;
var mousingOverPreview := false; ## Set to true if you've got your mouse over the preview; Makes [member rotisserie_socket] spin faster if it's a [Piece] in stock.
@export var lbl_name : Label; ## The label that displays the name of the object for sale.

@export var bg_Part : Control; ## Holds the background GFX for when a [Part] is in the shop.

enum doorState {
	NONE, ## Default value. Pretty much acts as [enum doorState.CLOSED].
	OPEN, ## The stall is "open".
	CLOSED, ## The stall is "closed". See [member doorsActuallyClosed].
	FROZEN, ## The stall has its contents frozen, and cannot be rerolled during normal gameplay.
}

## @experimental: Controls whether this stall shows the [Part] background or [Piece] background on startup.
@export var defaultPieceNotPart := false

## Changes door states, given that [param newState] != [member curState].
func changeState(newState:ShopStall.doorState):
	if curState != newState:
		##Before state change
		if curState == ShopStall.doorState.OPEN:
			#freezerBlinky.texture = load("res://graphics/images/HUD/blinkies/freezerblinky_off.png");
			doorsActuallyClosed = false;
			pass;
		if curState == ShopStall.doorState.CLOSED:
			doorsActuallyClosed = doors_actually_closed();
			#freezerBlinky.texture = load("res://graphics/images/HUD/blinkies/freezerblinky_off.png");
			pass;
		if curState == ShopStall.doorState.FROZEN:
			doorsActuallyClosed = false;
			#freezerBlinky.texture = load("res://graphics/images/HUD/blinkies/freezerblinky_on.png");
		
		curState = newState;
		##After state change
		if curState == ShopStall.doorState.OPEN:
			if is_instance_valid(partRef):
				partRef.disable(false);
			freezerBlinky.texture = load("res://graphics/images/HUD/blinkies/freezerblinky_off.png");
		if curState == ShopStall.doorState.CLOSED:
			if is_instance_valid(partRef):
				partRef.disable(true);
			deselect();
			freezerBlinky.texture = load("res://graphics/images/HUD/blinkies/freezerblinky_off.png");
		if curState == ShopStall.doorState.FROZEN:
			if is_instance_valid(partRef):
				partRef.disable(false);
			freezerBlinky.texture = load("res://graphics/images/HUD/blinkies/freezerblinky_on.png");

func _ready():
	if ! btn_freeze.is_connected("toggled", _on_freeze_button_toggled):
		btn_freeze.connect("toggled", _on_freeze_button_toggled);
	if ! btn_buy.is_connected("toggled", _on_buy_button_toggled):
		btn_buy.connect("toggled", _on_buy_button_toggled);
	
	#inventory = GameState.get_inventory();
	changeState(ShopStall.doorState.CLOSED);
	
	## Set up the rotisserie socket. Can't be done later.
	rotisserie_socket.remove_occupant(true);
	rotisserie_socket.shopStall = self;


var shopStallPillarMesh := preload("res://graphics/models/generated/shop_stall.tres"); ## The mesh which sits under a displayed Piece.
var piecePreviewSetupDone := false; ## If true, [method set_up_piece_preview_pillar] will return after removing [member rotisserie_socket]'s occupant.
## Clears the occupant of [member rotisserie_socket], then sets up the pillar beneath a [Piece] preview.[br]Returns after clearing the occupant if [member piecePreviewSetupDone] is [code]true[/code].
func set_up_piece_preview_pillar():
	## Remove the current occupant.
	rotisserie_socket.remove_occupant(true);
	
	## Don't continue further if the setup is already done.
	if piecePreviewSetupDone: return;
	piecePreviewSetupDone = true;
	
	## Set up the stall peg thing.
	var pillarMeshNode = MeshInstance3D.new();
	pillarMeshNode.set_layer_mask_value(1, false);
	pillarMeshNode.set_layer_mask_value(2, true);
	pillarMeshNode.set_mesh(shopStallPillarMesh);
	node_PiecePreview.add_child(pillarMeshNode);
	pillarMeshNode.position = Vector3(0,-1,0);
	pillarMeshNode.show();
	
	## Move the node into the proper position.
	node_PiecePreview.global_position.x = stallID * 20;
	node_PiecePreview.global_position.y = -20;

func _physics_process(delta):
	updatePrice();
	
	if clopenQueue >= 0:
		clopenQueue -= 1;
	if clopenQueue <= 0 and queuedClopen != null:
		if queuedClopen:
			open_stall();
			queuedClopen = null;
		else:
			close_stall();
			queuedClopen = null;
	
	if curState == ShopStall.doorState.CLOSED:
		freezerDoor.position.y = move_toward(freezerDoor.position.y, -144.0, delta * 200);
		if is_equal_approx(leftDoor.position.x/100, 0.0):
			leftDoor.position.x = 0;
			pass
		else:
			leftDoor.position.x = lerp(leftDoor.position.x, 0.0, delta * 10);
		if is_equal_approx(rightDoor.position.x/100, 0.0):
			rightDoor.position.x = 0;
			pass
		else:
			rightDoor.position.x = lerp(rightDoor.position.x, 0.0, delta * 10);
		
	elif curState == ShopStall.doorState.OPEN:
		leftDoor.position.x = lerp(leftDoor.position.x, -144.0, delta * 3);
		rightDoor.position.x = lerp(rightDoor.position.x, 144.0, delta * 3);
		freezerDoor.position.y = move_toward(freezerDoor.position.y, -144.0, delta * 200);
	elif curState == ShopStall.doorState.FROZEN:
		leftDoor.position.x = lerp(leftDoor.position.x, -120.0, delta * 3);
		rightDoor.position.x = lerp(rightDoor.position.x, 120.0, delta * 3);
		freezerDoor.position.y = move_toward(freezerDoor.position.y, 0.0, delta * 200);
	else:
		changeState(ShopStall.doorState.CLOSED);
	
	update_behavior_to_reflect_contents();

## Called when [member btn_freeze] gets toggled.
func _on_freeze_button_toggled(toggled_on):
	if ! has_ref() or buyQueued:
		toggled_on = false;
	freeze(toggled_on);
	pass # Replace with function body.

## Freezes the stall, making it immune to being rerolled under normal gameplay circumstances.
func freeze(toggled_on:=true):
	if (curState == ShopStall.doorState.OPEN) or (curState == ShopStall.doorState.FROZEN):
		if toggled_on:
			changeState(ShopStall.doorState.FROZEN);
			if GameState.get_in_state_of_play():
				SND.play_sound_nondirectional("Part.Select", 0.60, 0.5);
				SND.play_sound_nondirectional("Shop.Freezer.Close", 0.86, 0.15);
		else:
			if GameState.get_in_state_of_play() and curState == ShopStall.doorState.FROZEN:
				SND.play_sound_nondirectional("Part.Select", 0.60, 0.5);
			changeState(ShopStall.doorState.OPEN);
		#print("deseleccting from freeze?")
		deselect(true);
	elif curState == ShopStall.doorState.CLOSED:
		btn_freeze.button_pressed = false;

## Returns true if the stall is in state [enum ShopStall.doorState.FROZEN].
func is_frozen() -> bool:
	return (curState == ShopStall.doorState.FROZEN);

## Returns true if there's nothing inside OR the stall is frozen.
func is_empty() -> bool:
	return not is_frozen() and ! has_ref();

## Returns true if there's something in here.
func has_ref() -> bool:
	return ref_is_part() or ref_is_piece();

## Returns true if the thing in here is a part.
func ref_is_part() -> bool:
	return is_instance_valid(partRef);

## Returns true if the thing in here is a piece.
func ref_is_piece() -> bool:
	return is_instance_valid(pieceRef);

## Updates the price label to match the current contents and state.
func updatePrice():
	var price = get_price();
	
	lbl_price.update_amt(price);
	
	if curState == doorState.CLOSED:
		TextFunc.set_text_color(lbl_price, "unaffordable");
	else:
		if is_affordable():
			if curState == doorState.FROZEN:
				TextFunc.set_text_color(lbl_price, "ranged");
			else:
				TextFunc.set_text_color(lbl_price, "scrap");
		else:
			TextFunc.set_text_color(lbl_price, "unaffordable");

## Gets the price of the ref, or -1 if no ref. -1 makes the scrap counter zero out.
func get_price():
	if buyQueued: return -1;
	var price = -1;
	if ref_is_part():
		price = partRef._get_buy_price();
	elif ref_is_piece():
		price = pieceRef.get_buy_price();
	return price;

## Returns true if the player can afford this thing, using [method ScrapManager.is_affordable] with [get_price()] as [param ScrapManager.is_affordable.amt].
func is_affordable() -> bool:
	return ScrapManager.is_affordable(get_price());

## Called when the buy button is pressed.
func _on_buy_button_toggled(toggled_on):
	#print("buy btn pressed")
	if update_player():
		if (curState == ShopStall.doorState.OPEN):
			player.deselect_everything();
			if ref_is_part():
				if toggled_on:
					try_buy_part();
			elif ref_is_piece():
				if toggled_on:
					try_buy_piece();
			else:
				btn_buy.button_pressed = false;
		else:
			btn_buy.button_pressed = false;
	else:
		btn_buy.button_pressed = false;
	pass # Replace with function body.


var buyQueued = false ## Denotes whether a buy is queued.
## Tries to buy the [Piece] on sale, then returns the result. See also [method Piece.start_buying].
func try_buy_piece() -> bool:
	if buyQueued:
		return false;
	if ref_is_piece():
		if ScrapManager.try_spend_scrap(get_price(), "Piece Purchase"):
			pieceRef.start_buying(player);
			buyQueued = true;
			btn_buy.button_pressed = true;
			return true;
		else:
			btn_buy.button_pressed = false;
	return false;
## Tries to buy the [Part] on sale, then returns the result. See also [method Part.start_buying].
func try_buy_part() -> bool:
	if buyQueued:
		return false;
	if ref_is_part():
		if ScrapManager.try_spend_scrap(get_price(), "Part Purchase"):
			buyQueued = true;
			partRef.start_buying(player);
			btn_buy.button_pressed = true;
			return true;
		else:
			btn_buy.button_pressed = false;
	return false;

## Deselects the contents of this stall.
func deselect(deselectPart:=false):
	btn_buy.button_pressed = false;
	if update_player():
		#player.part_buy_mode_enable(false);
		if is_instance_valid(pieceRef):
			pieceRef.select_via_robot(player, false);
	if deselectPart && is_instance_valid(partRef):
		#print("Deselecting fromm shop stall")
		partRef.select(false);

## The currently queued closed/open state.[br]
## When set to [code]true[/code], an opening is queued.[br]
## When set to [code]false[/code], a closing is queued.[br]
## When set to [code]null[/code], nothing happens. This is what it gets set to after the queued action takes place.[br]
var queuedClopen = null;
var clopenQueue = -1; ## A frame-timer that prevents too many [member queuedClopen] changes in quick succession and also staggers the stall openings a bit.
## Changes [queuedClopen] to the input, and sets [member clopenQueue] to an [int] between 0-5.
func queue_clopen(open : bool):
	if ! is_frozen() and clopenQueue < 0:
		clopenQueue = randi_range(0, 5);
		queuedClopen = open;
## Opens the stall, unless frozen.
func open_stall():
	if !(curState == ShopStall.doorState.FROZEN):
		changeState(ShopStall.doorState.OPEN);
		if GameState.get_in_state_of_play():
			var pitchMod = randf_range(2.5,3.5)
			SND.play_sound_nondirectional("Shop.Door.Open", 0.85, pitchMod)
## Closes the stall, unless frozen.
func close_stall():
	deselect()
	if !(curState == ShopStall.doorState.FROZEN):
		if curState != ShopStall.doorState.CLOSED and GameState.get_in_state_of_play():
			var pitchMod = randf_range(2.5,3.5)
			SND.play_sound_nondirectional("Shop.Door.Open", 0.85, pitchMod)
		changeState(ShopStall.doorState.CLOSED);
## Gets whether the doors are actually closed; i.e, their position.x are both approximately 0.
func doors_actually_closed() -> bool:
	if (curState == ShopStall.doorState.FROZEN):
		return true;
	elif (curState == ShopStall.doorState.CLOSED):
		if is_zero_approx(leftDoor.position.x) && is_zero_approx(rightDoor.position.x):
			return true
	return false;

## Destroys whatever is being shown for sale.
func destroy_contents(ignoreFrozen := false):
	var destroyme = false;
	if ! ignoreFrozen:
		destroyme = true;
	else:
		if ! is_frozen():
			destroyme = true;
	
	if destroyme:
		if is_instance_valid(partRef):
			partRef.destroy();
		partRef = null;
		if is_instance_valid(pieceRef):
			pieceRef.destroy();
		pieceRef = null;

## Updates the background if there is something in the stall. If there is nothing in the stall, nothing happens, as to keep the illusion of an empty stall.
func update_behavior_to_reflect_contents():
	if has_ref():
		if ref_is_piece():
			bg_Piece.show();
			bg_Part.hide();
			btn_PieceSelect.disabled = buyQueued;
			lbl_name.text = pieceRef.pieceName;
			TextFunc.set_text_color(lbl_name, "white");
		elif ref_is_part():
			bg_Part.show();
			bg_Piece.hide();
			btn_PieceSelect.disabled = true;
			lbl_name.text = partRef.partName;
			TextFunc.set_text_color(lbl_name, "utility");
	else:
		btn_PieceSelect.disabled = true;
		lbl_name.text = "OUT OF STOCK";
		TextFunc.set_text_color(lbl_name, "unaffordable");
	
	btn_buy.disabled = !(curState == doorState.OPEN and has_ref() and is_affordable() and !buyQueued and clopenQueue == -1)
	
	btn_freeze.disabled = !((curState == doorState.OPEN or curState == doorState.FROZEN) and has_ref() and !buyQueued and clopenQueue == -1)
	
	if (! has_ref()) or buyQueued:
		freeze(false);

## The [Socket] which holds [Piece]s for sale.
@export var rotisserie_socket : Socket;
## Adds a piece to the sale window.
func add_piece(piece):
	set_up_piece_preview_pillar();
	pieceRef = piece;
	rotisserie_socket.add_occupant(pieceRef);
	pieceRef.inShop = true;
	pieceRef.shopStall = self;

## Emitted when the thing that is for sale is selected.
signal thingSelected(stall : ShopStall)
## Emitted when the player clicks on the Piece preview window.
func _on_btn_piece_select_pressed():
	if ref_is_piece() and update_player():
		thingSelected.emit(self);
		pieceRef.select_via_robot(player);
	pass # Replace with function body.

## Updates [member player] then returns true if it is valid.
func update_player() -> bool:
	player = GameState.get_player();
	return is_instance_valid(player);

## Called when you mouse over the [Piece] preview window; Sets [member mousingOverPreview] to [code]true[/code].
func _on_btn_piece_select_mouse_entered():
	mousingOverPreview = true;
	pass # Replace with function body.

## Called when you stop mousing over the [Piece] preview window; Sets [member mousingOverPreview] to [code]false[/code].
func _on_btn_piece_select_mouse_exited():
	mousingOverPreview = false;
	pass # Replace with function body.
