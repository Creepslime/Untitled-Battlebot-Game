extends Node
## Utility functions.

var nodesChecked = []
var loopCounter := 0;
##Returns an array of every single child and grandchild of a Node.
func get_all_children(reason:String, node, ownerToCheck : Node = null, init := true) -> Array:
	if init:
		GameState.profiler_ping_create("get_all_children init: "+reason);
	GameState.profiler_ping_create("get_all_children loop: "+reason);
	if init: 
		nodesChecked = []; 
		loopCounter = 0;
	#print("ALL CHILDREN LOOPS: ", loopCounter)
	loopCounter += 1;
	var nodes : Array = [];
	#print(node.owner)
	if node is not Node: return [];
	
	for N in node.get_children():
		if N in nodesChecked: return nodes;
		##In theory this bit here will allow to check only nodes from the thing's original scene...
		if ownerToCheck != null:
			#print("Checking if " , ownerToCheck ," is owner of ", N)
			if N.owner != ownerToCheck:
				#print("Not owner, returning")
				return nodes;
			#print("Is owner, continuing")
		
		if N.get_child_count() > 0:
			append_unique(nodes, N);
			append_array_unique(nodes, get_all_children(reason, N, ownerToCheck, false));
		else:
			append_unique(nodes, N);
	return nodes;

##Returns an array of every single child of a certain type.[br]
##If you just want to iterate over children of a certain type, this is probably less efficent than just running over get_all_children() and then checking if the node is the Class you want to check for.
func get_all_children_of_type(reason:String, node, type : Object = Node, ownerToCheck : Node = null) -> Array:
	var nodes : Array = [];
	var all = get_all_children(reason, node, ownerToCheck);
	
	for child in all:
		if is_instance_of(child, type):
			nodes.append(child);
	return nodes;

##Appends an item to a given [Array] only if the array does not already contain that item.[br]
##Returns the array as well, if you need it.
func append_unique(hostArray : Array, input : Variant):
	if !hostArray.has(input):
		hostArray.append(input);
	return hostArray;

##Appends all items in the [param inputArray] into [param hostArray], except for items [param hostArray] already contains.[br]
##Returns the array as well, if you need it.
func append_array_unique(hostArray : Array, inputArray):
	for item in inputArray:
		append_unique(hostArray, item);
	return hostArray;

## Appends an item to a given [Array] only if the array does not already contain that item.[br]
## If the input is an [Array], it runs this function again on each item within it.[br]
## This essentially unfurls every array and creates one massive one.
func append_recursive_unique(hostArray : Array, input : Variant):
	if input is Array:
		for item in input:
			append_recursive_unique(hostArray, input);
	else:
		append_unique(hostArray, input);
	return hostArray;

## Returns the [param hostArray] but removes any duplicate entries.
func array_duplicates_removed(inputArray : Array):
	var ret := inputArray.duplicate();
	ret.clear();
	for item in inputArray:
		append_unique(ret, item);
	inputArray = ret;
	return inputArray;

##Takes an angle in Degrees and then returns a Radian equivalent between -360 and 360 degrees.
func fix_angle_deg_to_rad(inAngle : float) -> float:
	while inAngle > 360.0:
		inAngle -= 360.0;
	while inAngle < -360.0:
		inAngle += 360.0; 
	return deg_to_rad(inAngle);

##Takes an angle in Radians and then returns a Radian equivalent between -360 and 360 degrees.
func fix_angle_rad_to_rad(inAngle : float) -> float:
	inAngle = rad_to_deg(inAngle);
	while inAngle > 360.0:
		inAngle -= 360.0;
	while inAngle < -360.0:
		inAngle += 360.0; 
	return deg_to_rad(inAngle);

##Returns the angle of difference between angle A and angle B, relative to A and wrapping around the circle.[br]
func angle_difference_relative(A, B):
	if A < -PI / 2:
		if B > 0:
			B -= PI * 2;
	if A > PI / 2:
		if B < 0:
			B += PI * 2;
	
	return angle_difference(A, B);

##Runs look_at() only if the target and node do not share a position.
func look_at_safe(node : Node3D, target : Vector3, up := Vector3(0,1,0)):
	if node.global_transform.origin.is_equal_approx(target): return;
	node.look_at(target, up);

## Prints the input only when the boolean value is true.
func print_if_true(printable, boolean : bool):
	if boolean: print(printable);

const gridMapRotationSequences = {
	0:"",
	1:"Z-",
	2:"Z-Z-",
	3:"Z+",
	4:"X+",
	5:"X+Z-",
	6:"Y-Y-X+",
	7:"X+Z+",
	8:"Z-Z-Y-Y-",
	9:"Z+X-X-",
	10:"Y+Y+",
	11:"Y+Y+Z-",
	12:"X-",
	13:"X-Z-",
	14:"X-Z+Z+",
	15:"Z+Y-",
	16:"Y+",
	17:"Y+Y+Z-X+",
	18:"Y+X-X-",
	19:"X+Y-",
	20:"Z-Z-Y-",
	21:"Y-Y-X+Y-",
	22:"Y-",
	23:"Y+Z-",
}

var gridMapRotations : Dictionary[int,Vector3] = {};

func rotate_using_gridmap_orientation(object : Node3D, orientation : int):
	if orientation == 0: return;
	if orientation in gridMapRotations:
		object.rotation = gridMapRotations[orientation];
		return;
	else:
		var stringToParse = gridMapRotationSequences[orientation];
		var axisStorage = ""
		for char in stringToParse:
			match char:
				"X":
					axisStorage = "X";
				"Y":
					axisStorage = "Y";
				"Z":
					axisStorage = "Z";
				"+":
					match axisStorage:
						"X":
							object.rotate_x(PI/2)
						"Y":
							object.rotate_y(PI/2)
						"Z":
							object.rotate_z(PI/2)
					axisStorage = "";
				"-":
					match axisStorage:
						"X":
							object.rotate_x(-PI/2)
						"Y":
							object.rotate_y(-PI/2)
						"Z":
							object.rotate_z(-PI/2)
					axisStorage = "";
		
		gridMapRotations[orientation] = object.rotation;

## Turns the given number into a color-compatible [int] from 0-255.[br]If the input is an [int] already, it just clamps it.[br]If the input is a [float], its bounds are 0.0-1.0; it multiplies it by 255.0, then performs roundi on it.
func convert_num_to_rgba_int(num):
	if num is int:
		return clampi(num, 0, 255);
	if num is float:
		return clampi(roundi(num * 255.0), 0, 255);

## Returns the given [Vector3] as a [Vector2], with in.x -> out.x and in.z -> out.y.
func vec3_to_vec2(inVec : Vector3) -> Vector2:
	return Vector2(inVec.x, inVec.z);

## Returns the given [Vector2] as a [Vector3], with out.y = 0, in.x -> out.x, and in.y -> out.z.
func vec2_to_vec3(inVec : Vector2) -> Vector3:
	return Vector3(inVec.x, 0.0, inVec.y);

## Returns whether X and Y of the two input [Vector2]s are roughly equal to the others'.
func is_equal_approx_vector2(inVecA : Vector2, inVecB : Vector2) -> bool:
	return is_equal_approx(inVecA.x, inVecB.x) and is_equal_approx(inVecA.y, inVecB.y);
## Returns whether X, Y and Z of the two input [Vector3]s are roughly equal to the others'.
func is_equal_approx_vector3(inVecA : Vector3, inVecB : Vector3) -> bool:
	return is_equal_approx(inVecA.x, inVecB.x) and is_equal_approx(inVecA.y, inVecB.y) and is_equal_approx(inVecA.z, inVecB.z);
## Returns whether W, X, Y and Z of the two input [Vector4]s are roughly equal to the others'.
func is_equal_approx_vector4(inVecA : Vector4, inVecB : Vector4) -> bool:
	return is_equal_approx(inVecA.w, inVecB.w) and is_equal_approx(inVecA.x, inVecB.x) and is_equal_approx(inVecA.y, inVecB.y) and is_equal_approx(inVecA.z, inVecB.z);
