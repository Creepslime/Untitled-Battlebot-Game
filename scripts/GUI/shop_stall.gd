extends Control

class_name ShopStall

@export var leftDoor : TextureRect;
@export var rightDoor : TextureRect;
@export var freezerDoor : TextureRect;
@export var freezerBlinky : TextureRect;

var pieceRef : Piece;
var partRef : Part;
var inventory : InventoryPlayer;
var player : Robot_Player

var curState := ShopStall.doorState.NONE;
var shopIsOpen := true;

var doorsActuallyClosed := false;

var stallID := -1;

@export var btn_buy : Button;
@export var lbl_price : ScrapLabel;
@export var btn_freeze : Button;

@export var bg_Piece : Control;
@export var node_PiecePreview : Node3D;
@export var btn_PieceSelect : Button;
var mousingOverPreview := false;
@export var lbl_name : Label;

@export var bg_Part : Control;

enum doorState {
	NONE,
	OPEN,
	CLOSED,
	FROZEN,
}

@export var defaultPieceNotPart := false

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
	
	node_PiecePreview.global_position.x = get_shop_stall_id() * 20;
	node_PiecePreview.global_position.y = -20;
	
	rotisserie_socket.remove_occupant(true);
	rotisserie_socket.shopStall = self;

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

func _on_freeze_button_toggled(toggled_on):
	if ! has_ref() or buyQueued:
		toggled_on = false;
	freeze(toggled_on);
	pass # Replace with function body.

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
	print("buy btn pressed")
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

var buyQueued = false
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

func deselect(deselectPart:=false):
	btn_buy.button_pressed = false;
	if update_player():
		#player.part_buy_mode_enable(false);
		if is_instance_valid(pieceRef):
			pieceRef.select_via_robot(player, false);
	if deselectPart && is_instance_valid(partRef):
		#print("Deselecting fromm shop stall")
		partRef.select(false);


var queuedClopen = null;
var clopenQueue = -1;
func queue_clopen(open : bool):
	if ! is_frozen() and clopenQueue < 0:
		clopenQueue = randi_range(0, 5);
		queuedClopen = open;
func open_stall():
	if !(curState == ShopStall.doorState.FROZEN):
		changeState(ShopStall.doorState.OPEN);
		if GameState.get_in_state_of_play():
			var pitchMod = randf_range(2.5,3.5)
			SND.play_sound_nondirectional("Shop.Door.Open", 0.85, pitchMod)

func close_stall():
	deselect()
	if !(curState == ShopStall.doorState.FROZEN):
		if curState != ShopStall.doorState.CLOSED and GameState.get_in_state_of_play():
			var pitchMod = randf_range(2.5,3.5)
			SND.play_sound_nondirectional("Shop.Door.Open", 0.85, pitchMod)
		changeState(ShopStall.doorState.CLOSED);

func doors_actually_closed() -> bool:
	if (curState == ShopStall.doorState.FROZEN):
		return true;
	elif (curState == ShopStall.doorState.CLOSED):
		if is_zero_approx(leftDoor.position.x) && is_zero_approx(rightDoor.position.x):
			return true
	return false;

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

@export var rotisserie_socket : Socket;
func add_piece(piece):
	rotisserie_socket.remove_occupant(true);
	pieceRef = piece;
	rotisserie_socket.add_occupant(pieceRef);
	pieceRef.inShop = true;
	pieceRef.shopStall = self;

func get_shop_stall_id():
	if stallID == -1:
		stallID = GameState.get_unique_shop_stall_id()
	return stallID;

signal thingSelected(stall : ShopStall)
func _on_btn_piece_select_pressed():
	if ref_is_piece() and update_player():
		thingSelected.emit(self);
		pieceRef.select_via_robot(player);
	pass # Replace with function body.

## Updates [member player] then returns true if it is valid.
func update_player() -> bool:
	player = GameState.get_player();
	return is_instance_valid(player);


func _on_btn_piece_select_mouse_entered():
	mousingOverPreview = true;
	pass # Replace with function body.

func _on_btn_piece_select_mouse_exited():
	mousingOverPreview = false;
	pass # Replace with function body.
