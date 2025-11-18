@icon("res://graphics/images/class_icons/scrap_green.png")
extends Control
class_name ShopPanel

func _on_shops_tab_changed(tab):
	var board = GameState.get_game_board();
	#if board.s
	if ! board.queuedShopLeave:
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
