extends Piece

class_name Piece_Swivel
## A [Piece] that will try to rotate a section of itself ([member swivelNode]) to [member targetRotation] on a set [member axisOfRotation].[br]
## No [Piece] should have this as their base script. Use [Piece_SwivelManual], [Piece_SwivelPointer], or extend to a new class.

var targetRotation := 0.0; ## The target rotation. Is lerp'd to each frame this [Piece] has energy.
@export var swivelNode : Node3D; ## The node that actually rotates each frame.
@export var rotationSpeed := 0.9; ## The base rotation speed for this Swivel.
@export var movingSockets : Array[Socket] = []; ## All sockets that are children of the [member swivelNode] need to be placed in here.
enum axes {
	X,
	Y,
	Z
}
@export var axisOfRotation := axes.Y; ## The axis to rotate [member swivelNode] on from [enum axes].
@export var deltaMultiplier := 30.0; ## How much [param phys_process_collision.delta] gets multiplied by when lerping.
@export var weightPenalty := 0.015; ## The amount of speed reduction per unit of [Piece.weightLoad] hanging off of each of the [member movingSockets].
@export var weightPenaltyBaseMult := 1.0; ## The amount of multiplier we start at before the [member weightPenalty] stuff goes down in [method get_swivel_rotation_speed_multiplier_based_on_weight].

## @hidden
func stat_registry():
	super();
	register_stat("RotationSpeed", rotationSpeed, StatHolderManager.statIconCooldown, StatHolderManager.statTags.Function);

## Extended from [Piece].[br]
## This is where the rotation happens. Wowza.
func phys_process_collision(delta):
	if !can_use_passive_any():
		targetRotation = 0.0;
	
	match axisOfRotation:
		axes.X:
			swivelNode.rotation.x = lerp_angle(swivelNode.rotation.x, targetRotation, delta * deltaMultiplier * get_stat("RotationSpeed") * get_swivel_rotation_speed_multiplier_based_on_weight())
		axes.Y:
			swivelNode.rotation.y = lerp_angle(swivelNode.rotation.y, targetRotation, delta * deltaMultiplier * get_stat("RotationSpeed") * get_swivel_rotation_speed_multiplier_based_on_weight())
		axes.Z:
			swivelNode.rotation.z = lerp_angle(swivelNode.rotation.z, targetRotation, delta * deltaMultiplier * get_stat("RotationSpeed") * get_swivel_rotation_speed_multiplier_based_on_weight())
	
	super(delta);

## It kinda says it on the tin, dunnit?[br]
## Slows down rotation when more things get added to any [member movingSockets].
func get_swivel_rotation_speed_multiplier_based_on_weight():
	var _load = 0.0;
	for socket in movingSockets:
		_load += get_socket_weight_load(socket);
	#print("WEIGHT LOAD: ",load);
	var speed = max(00.0, (1.0 - (_load * weightPenalty)));
	return speed;
