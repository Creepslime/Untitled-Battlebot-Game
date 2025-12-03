extends Label
class_name WeightLabel

func _process(delta):
	var robot = GameState.get_player();
	if is_instance_valid(robot):
		text = TextFunc.format_stat_num(robot.get_weight(), 2, "0");
	else:
		text = "";
