extends CollisionShape3D

class_name PieceCollisionBox

var colliderID : int = -1;
var originalHost : Piece;
var originalBox : PieceCollisionBox = self;
var originalOffset : Vector3;
var originalRotation : Vector3;
var copied : = false; ## If false, this box is able to be copied.
var copiedShapecast : = false; ## Set via [method make_shapecast].
var copiedByBody : = false; ##Set by the Robot when it's copied for the body.
@export var identifier : StringName;
@export var isPlacementBox := true; ##This collider is for placement validation.
@export var isHurtbox:= true; ##This collider is for detecting incoming attacks and impacts.
@export var isHitbox:= false;  ##This collider is for dishing out attacks.
var isOriginal = true;
var lastGlobalPosition : Vector3;

var copies : Array[PieceCollisionBox] = [];
var shapecasts : Array[ShapeCast3D] = [];

func _ready():
	get_collider_id();

func make_copy() -> PieceCollisionBox:
	if (not isOriginal) and (is_instance_valid(originalBox)): return originalBox.make_copy();
	copied = true;
	var newShape = shape.duplicate();
	var newBox : PieceCollisionBox = duplicate();
	newBox.shape = newShape;
	newBox.originalHost = originalHost;
	newBox.isOriginal = false;
	newBox.colliderID = get_collider_id();
	newBox.originalBox = self;
	copies.append(newBox);
	return newBox;

func make_shapecast():
	if copiedShapecast == true: return shapecasts[0]
	var shapeCastNew = ShapeCast3D.new();
	shapecasts.append(shapeCastNew);
	copied = true;
	
	add_child(shapeCastNew)
	
	var posNew = position;
	posNew = Vector3(0,0,0);
	shapeCastNew.set("position", posNew);
	shapeCastNew.set("scale", scale * 0.95);
	shapeCastNew.set("global_rotation", global_rotation);
	shapeCastNew.set("shape", shape);
	shapeCastNew.set("target_position", Vector3(0,0,0));	
	shapeCastNew.collide_with_areas = true;
	shapeCastNew.collide_with_bodies = true;
	shapeCastNew.enabled = true;
	shapeCastNew.debug_shape_custom_color = Color("af7f006b");
	shapeCastNew.set_collision_mask_value(1, false); ## Robot bodies no
	shapeCastNew.set_collision_mask_value(4, true); ## Piece hurtboxes yes
	shapeCastNew.set_collision_mask_value(5, false); ## Piece hitboxes no
	shapeCastNew.set_collision_mask_value(7, true); ## Placed piece hurtboxes yes
	shapeCastNew.set_collision_mask_value(11, true); ## Arena floors yes
	
	copiedShapecast = true;
	
	return shapeCastNew;

func erase_all_copies():
	for copy in copies:
		if is_instance_valid(copy):
			copy.queue_free();
	copies.clear();

func erase_all_shapecasts():
	for copy in shapecasts:
		if is_instance_valid(copy):
			copy.queue_free();
	shapecasts.clear();

func reset():
	erase_all_shapecasts();
	copiedShapecast = false;
	
	erase_all_copies();
	copiedByBody = false;
	
	copied = false;

func fix_positions_of_copies():
	for copy in copies:
		copy.global_position = global_position;
		copy.global_rotation = global_rotation;
		if isHitbox:
			print(copy.get_parent());
	for cast in shapecasts:
		cast.global_position = global_position;
		cast.global_rotation = global_rotation;

func get_collider_id():
	if colliderID == null or colliderID == -1:
		colliderID = GameState.get_unique_collider_id();
	return colliderID;

func get_piece() -> Piece:
	return originalHost;

var speedOfMovement : float;
var angleOfMovement : float;
var vector3OfMovement : Vector3;
var vector2OfMovement : Vector2;
func _physics_process(delta: float) -> void:
	vector3OfMovement = global_position - lastGlobalPosition;
	vector2OfMovement = Vector2(vector3OfMovement.x, vector3OfMovement.z);
	
	speedOfMovement = vector3OfMovement.length();
	
	angleOfMovement = vector2OfMovement.angle();
	
	lastGlobalPosition = global_position;

## Compares the XY velocity lengths of this box and another one, then returns a multiplier for damage/knockback. Factor is what the difference of differences is multiplied against for the multiplier.
func compared_projected_position(otherBox : PieceCollisionBox, factor := 1.0) -> float:
	var otherSpeed = otherBox.speedOfMovement;
	var speedDif = speedOfMovement - otherBox.speedOfMovement;
	
	var posDif = global_position.distance_to(otherBox.global_position) ## Get the length between this box and the other one.
	var posDifProjected = (global_position + vector3OfMovement).distance_to((otherBox.global_position + otherBox.vector3OfMovement)) ## Get the position difference between this box and the other one given that they move at the same velocity next frame.
	var posDifDif = posDif - posDifProjected; ## Get the difference bwetween current distance and projected distance.
	
	#var movingTowards = posDifDif < 0; ## If posDifDif < 0, then we're projected to be moving towards the other box.
	
	return maxf(0.0, posDifDif / factor)
