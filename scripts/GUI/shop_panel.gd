@icon("res://graphics/images/class_icons/scrap_green.png")
extends Control
class_name ShopPanel
@export var tabsControl : TabContainer;
var open := false;

func _on_shops_tab_changed(tab):
	var board = GameState.get_game_board();
	#if board.s
	if (! board.queuedShopLeave) and board.in_state_of_shopping(true):
		match tab:
			0: ##SHOPPING MODE
				GameState.set_game_board_state(GameBoard.gameState.SHOP)
				pass;
			1: ##BUILDING MODE
				GameState.set_game_board_state(GameBoard.gameState.SHOP_BUILD)
				pass;
			2: ##TESTING MODE
				GameState.set_game_board_state(GameBoard.gameState.SHOP_TEST)
				pass;
	pass # Replace with function body.

func change_tab(num:int):
	tabsControl.current_tab = 0;

func _process(delta: float) -> void:
	position.y = move_toward(position.y, 0 if open else -size.y, 120 * delta);
