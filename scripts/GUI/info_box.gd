@icon ("res://graphics/images/class_icons/inspector.png")
extends Control

class_name InfoBox

@export var iconBase : TextureRect;
@export var lbl_partName : Label;
@export var rlbl_desc : RichTextLabel;
#@export var rlbl_desc : RichTextLabel;
var partRef : Part;
var pieceRef : Piece;
var data_ready := false;
signal sellPart(part:Part);
signal sellPiece(piece:Piece);

var icon_blank := preload("res://graphics/images/HUD/infobox/typeIcons/info_blank.png");
var icon_utility := preload("res://graphics/images/HUD/infobox/typeIcons/info_utility.png");
var icon_melee := preload("res://graphics/images/HUD/infobox/typeIcons/info_melee.png");
var icon_ranged := preload("res://graphics/images/HUD/infobox/typeIcons/info_ranged.png");
var icon_passive := preload("res://graphics/images/HUD/infobox/typeIcons/info_passive.png");
var icon_scrap := preload("res://graphics/images/HUD/infobox/typeIcons/info_scrap.png");
var icon_warning := preload("res://graphics/images/HUD/infobox/typeIcons/info_warning.png");
var icon_error := preload("res://graphics/images/HUD/infobox/typeIcons/info_error.png");
var icon_piece := preload("res://graphics/images/HUD/infobox/typeIcons/info_piece.png");
var icon_piece_unequipped := preload("res://graphics/images/HUD/infobox/typeIcons/info_piece_unequipped.png");
var icon_part := preload("res://graphics/images/HUD/infobox/typeIcons/info_part.png");
var icon_part_unequipped := preload("res://graphics/images/HUD/infobox/typeIcons/info_part_unequipped.png");
var init_ready := false;
func _ready():
	clear_info();
	init_ready = true;

func populate_info(thing):
	clear_info(thing);
	var good = false;
	if is_instance_valid(thing):
		if thing is Part:
			populate_info_part(thing);
			good = true;
		if thing is Piece:
			populate_info_piece(thing);
			good = true;
	return good;

func get_required_height() -> int:
	return int(max(calculatedHeight, requiredHeight));

var requiredHeight := 272.0;
func calculate_required_height():
	update_ability_height();
	requiredHeight = min(infoBoxMaxSize, calculatedHeight);
	return requiredHeight;

func populate_info_part(part:Part):
	partRef = part;
	lbl_partName.text = part.partName;
	btn_moveButton.show();
	if part.ownedByPlayer:
		lbl_sellButton.text = get_sell_string();
		lbl_sellButton.show();
	rlbl_desc.text = part.partDescription;
	
	if part._get_part_type() == Part.partTypes.UTILITY:
		$EnergyIcon/Label.text = TextFunc.format_stat(part.get_energy_cost(true));
		$EnergyIcon.show();
		$CooldownIcon/Label.text = TextFunc.format_stat(part.get_fire_rate(true));
		$CooldownIcon.show();
		iconBase.texture = icon_utility;
		
	elif part._get_part_type() == Part.partTypes.MELEE:
		$EnergyIcon/Label.text = TextFunc.format_stat(part.get_energy_cost(true));
		$EnergyIcon.show();
		$CooldownIcon/Label.text = TextFunc.format_stat(part.get_fire_rate(true));
		$CooldownIcon.show();
		
		iconBase.texture = icon_melee;
		$DamageIcon/Label.text = TextFunc.format_stat(part.get_damage(true));
		$DamageIcon.show();
		
	elif part._get_part_type() == Part.partTypes.RANGED:
		$EnergyIcon/Label.text = TextFunc.format_stat(part.get_energy_cost(true));
		$EnergyIcon.show();
		$CooldownIcon/Label.text = TextFunc.format_stat(part.get_fire_rate(true));
		$CooldownIcon.show();
		
		iconBase.texture = icon_ranged;
		$DamageIcon/Label.text = TextFunc.format_stat(part.get_damage(true));
		$DamageIcon.show();
		$MagazineIcon/Label.text = TextFunc.format_stat(part.get_magazine_size(true), 0);
		$MagazineIcon.show();
		
	elif part._get_part_type() == Part.partTypes.PASSIVE:
		iconBase.texture = icon_part;

func populate_info_piece(piece:Piece):
	pieceRef = piece;
	lbl_partName.text = piece.pieceName;
	rlbl_desc.text = piece.pieceDescription;
	
	btn_moveButton.hide();
	
	if piece.is_equipped():
		iconBase.texture = icon_piece;
		#btn_removeButton
	else:
		iconBase.texture = icon_piece_unequipped;
	
	populate_stats(piece);
	populate_abilities(piece);
	pass;

func clear_info(thingToCheck = null):
	if thingToCheck != get_ref():
		data_ready = false;
		calculatedHeight = 0;
		partRef = null;
		lbl_partName.text = "Nothing Selected";
		iconBase.texture = icon_blank;
		#$DamageIcon.hide();
		#$CooldownIcon.hide();
		#$EnergyIcon.hide();
		#$MagazineIcon.hide();
		#$SellButton/Label.hide();
		#$SellButton.disabled = true;
		#$MoveButton.button_pressed = false;
		#$MoveButton.disabled = true;
		btn_moveButton.disabled = true;
		btn_removeButton.disabled = true;
		btn_sellButton.disabled = true;
		#rlbl_desc.text = "[color=e0dede]No [color=ffffff]Description [color=e0dede]Found.";
		rlbl_desc.text = "[color=e0dede]Closing...";
		var col = TextFunc.get_color("lightred")
		print_rich("[color="+str(col.to_html())+"]test")
		
		clear_abilities();
		clear_stats();
		
		queueAbilityPostUpdateCounter = -1;
	sell_areYouSure = false;

var ref : Node:
	get: return get_ref();
func get_ref():
	if is_instance_valid(partRef): 
		ref = partRef;
		return partRef;
	if is_instance_valid(pieceRef): 
		ref = pieceRef;
		return pieceRef;
	ref = null;
	return null;
func ref_is_piece() -> bool:
	if is_instance_valid(get_ref()):
		return ref is Piece;
	return false;
func ref_is_part() -> bool:
	if is_instance_valid(get_ref()):
		return ref is Part;
	return false;
func get_ref_stat_id():
	if ref != null:
		return ref.statHolderID;
	return -1;

@export var btn_sellButton : Button;
@export var lbl_sellButton : Label;
@export var btn_moveButton : Button;
@export var btn_removeButton : Button;
var sell_areYouSure := false; ## 
func _on_sell_button_pressed():
	if ref_is_part():
		if is_instance_valid(partRef.hostShopStall):
			var txt = "SURE? "
			lbl_sellButton.text = txt + TextFunc.format_stat(partRef._get_sell_price(), 0);
		else:
			if sell_areYouSure:
				sellPart.emit(partRef);
				clear_info();
			else:
				sell_areYouSure = true;
				var txt = "SURE? "
				lbl_sellButton.text = txt + TextFunc.format_stat(partRef._get_sell_price(), 0);
	elif ref_is_piece():
		if pieceRef.is_buyable():
			pieceRef.try_buy_from_shop();
		else:
			if sell_areYouSure:
				sellPiece.emit(pieceRef);
				if pieceRef.try_sell():
					clear_info();
			else:
				sell_areYouSure = true;
				var txt = "SURE? "
				lbl_sellButton.text = txt + TextFunc.format_stat(pieceRef.get_sell_price(), 0);
	pass # Replace with function body.

var sellError = false; ## Whether [member lbl_sellButton] should be red or scrap yellow.
## Gets the string for the sell button and sets [member sellError].
func get_sell_string() -> String:
	var prefix = "SELL:\n"
	var number = "ERROR"
	if ref_is_part():
		if is_instance_valid(partRef.hostShopStall):
			prefix = "BUY\n"
			sellError = btn_sellButton.disabled;
			number = TextFunc.format_stat(partRef._get_buy_price(), 0)
		else:
			sellError = btn_sellButton.disabled;
			number = TextFunc.format_stat(partRef._get_sell_price(), 0)
	elif ref_is_piece():
		if pieceRef.inShop:
			prefix = "BUY:\n";
			sellError = !pieceRef.is_buyable();
			number = TextFunc.format_stat(pieceRef.get_buy_price(), 0)
		elif pieceRef.is_sellable():
			sellError = btn_sellButton.disabled;
			number = TextFunc.format_stat(pieceRef.get_sell_price(), 0)
		else:
			if pieceRef.removable:
				sellError = true;
				number = TextFunc.format_stat(pieceRef.get_sell_price(), 0)
			else:
				sellError = true;
				return "NOT FOR\nSALE"
	else:
		sellError = true;
	if sell_areYouSure and prefix == "SELL:\n":
		prefix = "SURE?\n"
	return prefix + number;

##Updates the sell button string.
func update_sell_string():
	var col = TextFunc.get_color("scrap");
	lbl_sellButton.text = get_sell_string();
	if sellError:
		TextFunc.set_text_color(lbl_sellButton, "unaffordable")
	else:
		TextFunc.set_text_color(lbl_sellButton, "scrap")

##### ABILITIES BOX
@export var abilityInfoboxScene := preload("res://scenes/prefabs/objects/gui/active_ability_infobox.tscn");
@export var abilityScrollContainer : ScrollContainer;
@export var abilityHolder : VBoxContainer;
func populate_abilities(thing):
	clear_abilities();
	var effectiveSize := 0;
	if thing is Piece:
		var abilities = thing.get_all_abilities(true);
		for ability in abilities:
			if is_instance_valid(ability) and ability is AbilityManager:
				var newBox = abilityInfoboxScene.instantiate();
				if newBox is AbilityInfobox:
					newBox.populate_with_ability(ability, thing);
					abilityHolder.add_child(newBox);
					effectiveSize += 1;
	abilityScrollContainer.visible = effectiveSize > 0;
	set_queue_ability_post_update();
	if abilityScrollContainer.visible:
		for child in abilityHolder.get_children():
			child.queue_show();

var queueAbilityPostUpdateCounter = -1;

func set_queue_ability_post_update():
	queueAbilityPostUpdateCounter = 4;
@export var abilityBoxMaxSize := 200;
@export var infoBoxMaxSize := 400;
@export var almightyHolder : Control;
@export var almightyScroller : ScrollContainer;
var spaceBeforeDescription = 32;
var spaceAfterDescription = 2;

var spaceAfterAbilityContainer = 2;

var spaceAfterStatContainer = 2;
var spaceAfterButton = 4;

var spaceAfterStats = 4;

const maxButtonPosY = 366.0;

var calculatedHeight = 0;
func update_ability_height():
	var v = 0;
	for child in abilityHolder.get_children():
		v += child.size.y;
	
	var descHeight = rlbl_desc.get_content_height();
	
	abilityScrollContainer.custom_minimum_size.y = min(abilityBoxMaxSize - descHeight, v + 10)
	abilityScrollContainer.size.y = abilityScrollContainer.custom_minimum_size.y
	
	var abilityPosY = descHeight + spaceAfterDescription + spaceBeforeDescription;
	abilityScrollContainer.position.y = abilityPosY;
	var abilityH = abilityScrollContainer.custom_minimum_size.y;
	if not abilityScrollContainer.visible:
		abilityH = 0;
	var statY = abilityH + abilityPosY + spaceAfterAbilityContainer;
	statScrollContainer.position.y = statY;
	statScrollContainer.size.y = min(fix_stat_array_holder_height(), statContainerHeight);
	var buttonPosY = statY + statScrollContainer.size.y + spaceAfterStatContainer;
	
	var almightySize = btn_sellButton.size.y + buttonPosY + spaceAfterButton;
	almightyHolder.size.y = almightySize
	almightyScroller.size.y = min(almightySize, infoBoxMaxSize - btn_sellButton.size.y)
	
	btn_sellButton.position.y = min(maxButtonPosY, buttonPosY);
	btn_moveButton.position.y = min(maxButtonPosY, buttonPosY);
	btn_removeButton.position.y = min(maxButtonPosY, buttonPosY);
	calculatedHeight = btn_sellButton.size.y + btn_sellButton.position.y + spaceAfterButton;
	pass;

func _physics_process(delta):
	if ! init_ready: return;
	var removeDisabled = true;
	var moveDisabled = true;
	var sellDisabled = true;
	if GameState.get_in_one_of_given_states([GameBoard.gameState.SHOP, GameBoard.gameState.SHOP_BUILD]):
		if ref_is_piece():
			if pieceRef.is_removable():
				removeDisabled = false;
			if pieceRef.is_sellable():
				sellDisabled = false;
			if pieceRef.is_buyable():
				sellDisabled = false;
		elif ref_is_part():
			moveDisabled = false;
			removeDisabled = false;
			sellDisabled = false;
	
	if is_instance_valid(btn_removeButton):
		btn_removeButton.disabled = removeDisabled;
	if is_instance_valid(btn_moveButton):
		btn_moveButton.disabled = moveDisabled;
	if is_instance_valid(btn_sellButton):
		## Sell but
		btn_sellButton.disabled = sellDisabled;
		update_sell_string();
	
	
	if queueAbilityPostUpdateCounter == 1:
		data_ready = true;
		pass;
	if queueAbilityPostUpdateCounter == 2:
		calculate_required_height();
		pass;
	if queueAbilityPostUpdateCounter == 3:
		#queueAbilityPostUpdate2 = false;
		#queueAbilityPostUpdate3 = true;
		pass;
	if queueAbilityPostUpdateCounter == 4:
		#queueAbilityPostUpdate1 = false;
		pass;
	
	if queueAbilityPostUpdateCounter >= 0:
		queueAbilityPostUpdateCounter -= 1;
	pass;

func clear_abilities():
	##Clear out the abilities.
	for ability in abilityHolder.get_children():
		ability.queue_free();

## STATS
@export var statScrollContainer : ScrollContainer;
@export var statHolder : VBoxContainer;
@export var statArrayTemplate = preload("res://scenes/prefabs/objects/gui/stat_array.tscn");

var statContainerHeight = 0:
	get:
		return min(statHolder.size.y, 90) if statScrollContainer.visible else 0;
const statContainerHeightWhenFull = 40.0;
func populate_stats(thing):
	clear_stats();
	
	if is_instance_valid(thing):
		if thing is Piece:
			for stat in thing.statCollection.values():
				add_stat_icon(stat);
		elif thing is Part:
			for stat in thing.statCollection.values():
				add_stat_icon(stat);
	
	var statTagArraysOrganized = statTagsCategorized.values();
	statTagArraysOrganized.sort_custom(func(a : StatArrayDisplay, b : StatArrayDisplay):
		return a.statTag < b.statTag;)
	for statArray in statTagArraysOrganized:
		statHolder.add_child(statArray);
	
	statTagsCategorized.clear();
	statScrollContainer.visible = statHolder.get_child_count() > 0;
	statScrollContainer.scroll_vertical = 0;
	abilityScrollContainer.scroll_vertical = 0;

var statTagsCategorized : Dictionary[StatHolderManager.statTags, StatArrayDisplay] = {}
func add_stat_icon(stat:StatTracker):
	if stat.should_be_displayed(get_ref_stat_id()):
		var tag = stat.statTag;
		var statArray : StatArrayDisplay;
		if !statTagsCategorized.has(tag):
			statArray = statArrayTemplate.instantiate();
			statTagsCategorized[tag] = statArray;
		else:
			statArray = statTagsCategorized[tag];
		statArray.add_stat_icon(stat);

func fix_stat_array_holder_height():
	var totalHeight = 0;
	var count = 0;
	for statArray in statHolder.get_children():
		## Add in the margin.
		count += 1;
		if count < statHolder.get_child_count():
			totalHeight += statHolder.get("theme_override_constants/separation")
		totalHeight += statArray.recalc_height();
	var newSpacer = Control.new()
	newSpacer.size.y = spaceAfterStats;
	statHolder.add_child(newSpacer);
	return totalHeight + spaceAfterStats;

## Removes the piece or part we're inspecting.
func _on_remove_button_pressed():
	if ref_is_piece():
		pieceRef.remove_and_add_to_robot_stash(pieceRef.get_host_robot(), true);
	elif ref_is_part():
		pass;
	pass # Replace with function body.

## TODO: Recreate Part moving logic.
func _on_move_button_toggled(toggled_on):
	if ref_is_part():
		if toggled_on:
			pass;
		else:
			pass;
	pass # Replace with function body.

##Clear out the stats.
func clear_stats():
	statTagsCategorized.clear();
	for stat in statHolder.get_children():
		stat.queue_free();
