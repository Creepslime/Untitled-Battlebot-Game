extends Piece_Swivel

class_name Piece_SwivelManual
## A [Piece_Swivel] that recieves input from its abilities in order to change its [member targetRotation].

func rotate_clockwise():
	var physDelta = get_physics_process_delta_time();
	targetRotation += 10 * physDelta;
func rotate_counter_clockwise():
	var physDelta = get_physics_process_delta_time();
	targetRotation += -10 * physDelta;
	print(targetRotation, get_physics_process_delta_time());
