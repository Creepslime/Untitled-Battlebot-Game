extends MotionHandler

class_name MotionHandlerPlayer

var inputHandler;
var combatHandler;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super();
	pass # Replace with function body.

func _process(delta: float) -> void:
	super(delta);
	
	if !GameState.get_player().closestAiNode:
		var curScale = %RadiusCheck.get_scale();
		# the scaling is uniform for RadiusCheck, so we just need to check 1 component
		if curScale.x < 100:
			%RadiusCheck.set_scale(Vector3(curScale.x + 1, curScale.y + 1, curScale.z + 1));
	pass;

func grab_references():
	thisBot = GameState.get_player();
	super();
	if thisBot:
		inputHandler = thisBot.get_node("InputHandler");
		combatHandler = thisBot.get_node("CombatHandler");
	

# custom physics handling for player movement. regular movement feels flat and boring.
func _physics_process(delta):
	super(delta);
		
	var movementVector = Vector2.ZERO;
	if GameState.get_in_state_of_play() and combatHandler.health > 0:
		movementVector = inputHandler.get_movement_vector(true);
	
	##Rotating the body mesh towards the movement vector
	var rotatedMV = movementVector.rotated(deg_to_rad(90));

	if InputHandler.is_inputting_movement():
		bodyRotationAngle = lerp(bodyRotationAngle, movementVector.rotated(deg_to_rad(90)), delta * 10)
	
	var rotateVector = Vector3(bodyRotationAngle.x, 0, bodyRotationAngle.y) + botBodyMesh.global_position

	look_at_safe(botBodyMesh, rotateVector)
	
	var forceVector = Vector3.ZERO
	forceVector += body.global_transform.basis.x * movementVector.x * -GameState.PLAYER_ACCELERATION;
	forceVector += body.global_transform.basis.z * movementVector.y * -GameState.PLAYER_ACCELERATION;
	body.apply_central_force(forceVector);
	clamp_speed();

	pass;

func _on_collision(other:PhysicsBody3D, this:PhysicsBody3D=%Body):
	super(%Body, other)
	Hooks.OnPlayerCollision(other);
	#print("COLLISION HERE");
	#print(other, other.is_in_group("Combatant"), other.get_groups())
	#if other.is_in_group("Combatant") && 
	#if (other.is_in_group("Projectile") && other.get_attacker() != thisBot) || other.is_in_group("MeleeWeapon") || other.is_in_group("Combatant"):
		##print(other.get_attacker())
		#combatHandler.take_damage(1);

func _on_radius_check_area_entered(newNode) -> void:
	if newNode is AINode:
		var nodesInRadius = %RadiusCheck.get_overlapping_areas();
		var ply = GameState.get_player()
		
		if nodesInRadius.size() > 1:
			var closestNode
			var closestNodePos
			var distanceSqr
			var playerPos = ply.get_global_body_position();
			
			for aiNode in nodesInRadius:
				#print_rich("[color=darkorange] ", newNode is AINode, " ", aiNode is AINode, " [/color]")
				if !closestNode:
					closestNode = aiNode;
					closestNodePos = closestNode.get_global_position();
					distanceSqr = closestNodePos.distance_squared_to(playerPos);
				else:
					var newPos = aiNode.get_global_position()
					var newDist = newPos.distance_squared_to(playerPos)
					if newDist < distanceSqr:
						closestNode = aiNode;
						closestNodePos = newPos;
						distanceSqr = newDist;
						
			#print("CLOSEST NODE", closestNode.get_parent(), closestNode)
			
			ply.closestAiNode = closestNode as AINode;
		else:
			ply.closestAiNode = newNode as AINode;
			
		%RadiusCheck.set_scale(Vector3(7, 7, 7))
