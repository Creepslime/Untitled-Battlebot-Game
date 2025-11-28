extends Node2D

var timer := 0.0;
var timerMax := 5.
var timerMin := 3.

func _process(delta):
	timer -= delta;
	if timer <= 0:
		#print("timer go off")
		timer = randf_range(timerMax, timerMin);
