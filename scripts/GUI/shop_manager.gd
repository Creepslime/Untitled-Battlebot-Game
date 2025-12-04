extends NinePatchRect

class_name ShopManager

@export var spr_REC : Sprite2D;
var time = 0.0
@export var camScreenContents : Control;
var camFeedStartupTimer := 0.0;
var camFeedEndingTimer := 0.0;
var camFeedHProgress := 0.0;
var camFeedVProgress := 0.0;
var camFeedFlashAlpha := 1.0;
var camFeedBlackAlpha := 1.0;
@export var camScreenFlash : TextureRect;
@export var camScreenBlack : ColorRect;
var camScreenOn := false;
var initialized := false;
var transitionCalled := false;
var shops : Array[ShopStation];

@export var HUD_stations : Control;
@export var HUD_stationsParent : Control; ## Located on the main HUD. Makes the stations usable.
@export var HUD_stationsStepParent : Control; ## Located here. Hides the stations behind the screen transition.

var player : Robot_Player:
	get:
		return GameState.get_player();

func _ready():
	Hooks.add(self,"OnRerollShop", "ShopManager", _on_reroll_button_pressed);
	for shop in HUD_stations.get_children():
		if shop is ShopStation:
			shop.manager = self;
			shops.append(shop);
	update_health_button();

func _process(delta):
	HUD_stations.visible = is_visible_in_tree();
	
	if is_visible_in_tree():
		time += delta;
		
		camScreenContents.pivot_offset = Vector2(120,120);
		camScreenFlash.pivot_offset = Vector2(120,120);
		
		if camScreenOn:
			## Recording blinky.
			spr_REC.visible = fmod(time, floor(time)) >= 0.5;
			
			camFeedStartupTimer += delta;
			camFeedEndingTimer = 0.0;
			
			if camFeedStartupTimer > 0.0:
				camFeedVProgress += delta;
			else:
				camFeedVProgress = 0.0;
			
			if camFeedStartupTimer > 0.05:
				camFeedBlackAlpha -= delta * 6;
				camFeedHProgress += delta;
			else:
				camFeedHProgress = 0.0;
		else:
			camFeedStartupTimer = 0.0;
			camFeedEndingTimer += delta;
			spr_REC.visible = false;
			
			camFeedBlackAlpha += delta * 3;
			camFeedFlashAlpha -= delta * 6;
			
			if camFeedEndingTimer > 0.0:
				camFeedVProgress -= delta;
			
			if camFeedEndingTimer > 0.05:
				camFeedHProgress -= delta;
		
	else:
		camScreenContents.hide();
		camScreenFlash.hide();
	
	camFeedHProgress = clamp(camFeedHProgress, 0,1);
	camFeedVProgress = clamp(camFeedVProgress, 0,1);
	camFeedFlashAlpha  = clamp(camFeedFlashAlpha, 0,1);
	camFeedBlackAlpha  = clamp(camFeedBlackAlpha, 0,1);
	
	camScreenContents.scale.x = clamp(camFeedHProgress * 6, 0, 1);
	camScreenContents.scale.y = clamp(camFeedVProgress * 5, 0, 1);
	var flash_a = clamp(camFeedFlashAlpha, 0, 1)
	camScreenFlash.scale.x = flash_a;
	camScreenFlash.scale.y = flash_a;
	var black_a = clamp(camFeedBlackAlpha, 0, 1)
	var scrn_a = 1 - black_a;
	camScreenBlack.modulate.a = black_a;
	camScreenContents.modulate.a = scrn_a;
	
	if ! transitionCalled:
		var board = GameState.get_game_board()
		if GameState.get_in_state_of_shopping():
			if board.queuedShopLeave:
				if !is_visible_in_tree() or (black_a == 1 and camFeedHProgress <= 0 and camFeedVProgress <= 0) and all_shops_closed():
					GameState.set_game_board_state(GameBoard.gameState.LEAVE_SHOP)
					transitionCalled = true;
	
	update_health_button();


func all_shops_closed():
	for shop in shops:
		if ! shop.doorActuallyClosed:
			return false;
	return true;

func init_shop():
	for shop in shops:
		shop.player = player;
	pass;

func open_up_shop():
	turn_on_cam_feed();
	if ! initialized:
		initialized = true;
	HUD_stations.reparent(HUD_stationsParent);
	for shop in shops:
		shop.open_up_shop();
	
	pass;

func close_up_shop():
	turn_off_cam_feed();
	initialized = false;
	
	for shop in shops:
		shop.new_round(GameState.get_round_number() + 1);
	
	HUD_stations.reparent(HUD_stationsStepParent);

func turn_on_cam_feed():
	camScreenOn = true;
	
	camScreenContents.show();
	camScreenFlash.hide();
	camFeedStartupTimer = 0.0;
	camFeedHProgress = 0.0;
	camFeedVProgress = 0.0;
	camFeedBlackAlpha = 1.0;

func turn_off_cam_feed():
	camScreenOn = false;
	transitionCalled = false;
	camScreenFlash.show();
	camFeedEndingTimer = 0.0;
	camFeedFlashAlpha = 1.0;
	camFeedHProgress = 1/6;
	camFeedVProgress = 1/6;

## All the prices increment.
func set_closing_values():
	rerollPriceIncrementPermanent += 0.5;
	rerollPriceIncrement = rerollPriceIncrementPermanent;
	healPriceIncrementPermanent += 0.5;
	healPriceIncrement = healPriceIncrementPermanent;

## Resets all shop values to their defaults. Used at the start of a new game only.
func reset_shop():
	for shop in shops:
		shop.new_round(-1);
	
	rerollPriceIncrementPermanent = 0;
	rerollPriceIncrement = 0;
	healPriceIncrementPermanent = 0;
	healPriceIncrement = 0;

## Reroll button stuff.
var rerollPriceBase := 5.0;
var rerollPricePressIncrement := 1.0;
var rerollPriceIncrement := 0.0;
var rerollPriceIncrementPermanent := 0.0;

func get_reroll_price():
	return floori((rerollPriceBase + rerollPriceIncrement) * ScrapManager.get_discount_for_type(ScrapManager.priceTypes.REROLL));

##Increments reroll pricing.
func _on_reroll_button_pressed():
	ScrapManager.remove_scrap(get_reroll_price(), "ShopReroll");
	rerollPriceIncrement += rerollPricePressIncrement;
	rerollPriceIncrementPermanent += 0.25;
	pass # Replace with function body.

## Healing button stuff.
var healAmountBase := 0.5;
var healAmountModifier := 1.0;
var healPriceBase := 4.0;
var healPricePressIncrement := 2.0;
var healPriceIncrement := 0.0;
var healPriceIncrementPermanent := 0.0;
@export var btn_heal : Button;
@export var lbl_healAmount : Label;
@export var lbl_healPrice : ScrapLabel_Shop;


func update_health_button():
	if is_instance_valid(player):
		lbl_healAmount.text = "HEAL\n"+TextFunc.format_stat(get_heal_amount()) + " HP"
		lbl_healPrice.update_amt(get_heal_price());
		var healTooltip = "HEAL "+TextFunc.format_stat(get_heal_amount()) + " HP\nCOST: " + str(get_heal_price())
		if is_instance_valid(player) && ScrapManager.is_affordable(get_heal_price()) && ! player.at_max_health():
			TextFunc.set_text_color(lbl_healPrice, "scrap");
		else:
			if ! ScrapManager.is_affordable(get_heal_price()):
				healTooltip += "\n(Not affordable!)"
			if player.at_max_health():
				healTooltip += "\n(Robot is at max health!)"
			TextFunc.set_text_color(lbl_healPrice, "unaffordable");
		
		btn_heal.tooltip_text = healTooltip;
	else:
		lbl_healAmount.text = "HEAL\n??? HP";
		lbl_healPrice.update_amt(get_heal_price());

func get_heal_amount():
	if is_instance_valid(player):
		return (healAmountBase * healAmountModifier) * player.get_max_health();
	return (healAmountBase * healAmountModifier) * 3;
func get_heal_price():
	return ceili((healPriceBase + healPriceIncrement) * ScrapManager.get_discount_for_type(ScrapManager.priceTypes.HEALING));

func _on_heal_button_pressed():
	if _shop_heal():
		SND.play_sound_nondirectional("Shop.Chaching", 1, randf_range(0.90,1.1));;
	pass # Replace with function body.

func _shop_heal():
	if is_instance_valid(player):
		if ScrapManager.is_affordable(get_heal_price()):
			if ! player.at_max_health():
				ScrapManager.remove_scrap(get_heal_price(), "ShopHeal");
				healPriceIncrement += healPricePressIncrement;
				player.heal(get_heal_amount());
				healPriceIncrementPermanent += 0.5;
				return true;
