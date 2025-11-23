extends Camera

class_name GameCamera

@export_category("Adjustables and Stats")
@export var XRotInPlay = 20.0;
@export var rotXspeed := 0.0;
@export var rotYspeed := 0.0;
@export var zoomSpeed := 5.0;
var cameraOffset;
var targetPosition : Vector3;
var playerPosition : Vector3;
var targetRotationX := 0.0;
var currentRotationX := 0.0;
var targetRotationY := 0.0;
var currentRotationY := 0.0;
var targetRotationZ := 0.0;
@export var VOffsetInBuild := 6.0;
var vOffset := 0.0;
@export var zoomLevelBase := 1.0;
var targetZoomLevel := zoomLevelBase;
var currentZoomLevel := zoomLevelBase;
var zoomLevelMultiplier := 1.0;

var instantSpeedFrame := false
var instantSpeedFrames := 0;

var inputOffset : Vector3;
var targetInputOffset : Vector3;
var modInpVec : Vector3;
var modMouseVec : Vector3;
@export_category("Node Refs")
var playerBody : RigidBody3D;
var viewport : Viewport;
@export var marker : MeshInstance3D; ## @experimental: Used for showing where the mouse projection is landing while experimenting.
@export var ray : RayCast3D; ## @deprecated: Used to have a ray attached to the camera at all times. Don't now. May again, who knows.
@export var positionParent : Node;

@export var targetNode : Node3D;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super();
	cameraOffset = global_position; # the player always starts at 0, 0, 0 so we don't do any subtraction here
	position = Vector3(0,0,0)
	#playerBody = GameState.get_player_body();
	
	Hooks.add(self, "OnChangeGameState", "CameraChangePos", 
		func(oldState : GameBoard.gameState, newState : GameBoard.gameState) :
			if newState == GameBoard.gameState.INIT_NEW_GAME:
				targetRotationX = deg_to_rad(20.0);
				targetRotationY = 0.0;
			elif newState == GameBoard.gameState.MAIN_MENU:
				targetRotationX = 0.0;
			elif newState == GameBoard.gameState.LOAD_SHOP:
				targetRotationX = 0.0;
				currentZoomLevel = targetZoomLevel * zoomLevelMultiplier;
			elif newState == GameBoard.gameState.SHOP:
				if oldState == GameBoard.gameState.SHOP_BUILD:
					instantSpeedFrames = 3;
				elif oldState == GameBoard.gameState.SHOP_TEST:
					instantSpeedFrames = 3;
				targetRotationX = 0.0;
				targetZoomLevel = 0.3;
				currentZoomLevel = targetZoomLevel * zoomLevelMultiplier;
			elif newState == GameBoard.gameState.SHOP_BUILD:
				targetRotationX = 0.0;
				targetZoomLevel = 0.4;
				currentZoomLevel = targetZoomLevel * zoomLevelMultiplier;
			elif newState == GameBoard.gameState.SHOP_TEST:
				targetRotationX = 0.0;
				targetZoomLevel = 1.0;
				currentZoomLevel = 1.0;
			elif newState == GameBoard.gameState.LOAD_ROUND:
				targetRotationX = deg_to_rad(20.0);
				zoomLevelMultiplier = 1.0;
				targetZoomLevel = 1.0;
				currentZoomLevel = 1.0;
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_instance_valid(viewport):
		var mousePos = viewport.get_mouse_position();
		
		## Offset the camera when in the shop.
		if GameState.get_in_state_of_building(): ##TODO: Come up with a better, more exact state for this to happen.
			v_offset = lerp(v_offset, VOffsetInBuild, delta * 7.0);
		else:
			v_offset = lerp(v_offset, 0.0, delta * 7.0);
		pass
	else:
		viewport = get_viewport();

func _physics_process(delta):
	var snailMoveSpeed = 5. * delta;
	var slowMoveSpeed = 10. * delta;
	var midMoveSpeed = 15. * delta;
	var fastMoveSpeed = 30. * delta;
	if GameState.get_in_loading_state():
		instantSpeedFrame = true;
	else:
		#print(instantSpeedFrames)
		if instantSpeedFrames > 0:
			#print("instant cam")
			instantSpeedFrames -= 1;
			instantSpeedFrame = true;
	#instantSpeedFrame = true;
	if instantSpeedFrame:
		snailMoveSpeed = 1;
		slowMoveSpeed = 1;
		midMoveSpeed = 1;
		fastMoveSpeed = 1;
		pass;
	if is_node_ready():
		targetNode = GameState.get_camera_pointer();
		
		if is_instance_valid(targetNode) && is_instance_valid(viewport): 
			if ! in_camera_tilt_state(camTiltStates.NONE) and ! in_camera_tilt_state(camTiltStates.SHOP):
				var inp = GameState.get_player();
				if is_instance_valid(inp):
					var inpVec = inp.get_movement_vector(false);
					modInpVec = - Vector3(inpVec.x, 0, inpVec.y);
				var viewRect = viewport.get_visible_rect();
				var mousePos = Vector2(clamp(viewport.get_mouse_position().x, 0, viewRect.size.x), clamp(viewport.get_mouse_position().y, 0, viewRect.size.y));
				var mousePosMoved = (mousePos - (viewRect.size / 2)) / (viewRect.size / 2)
				var targetInputOffsetX = (-mousePosMoved.x);
				var targetInputOffsetZ = (-mousePosMoved.y);
				#targetRotationX = deg_to_rad(-64.3) +  (mousePosMoved.y / -15);sa
				#targetRotationZ = (mousePosMoved.x / -15);
				modMouseVec = Vector3(targetInputOffsetX, 0, targetInputOffsetZ)
				#modMouseVec = InputHandler.mouseProjectionRotation(self);
				
				targetInputOffset = modMouseVec + modInpVec;
				inputOffset = lerp (inputOffset, targetInputOffset, snailMoveSpeed)
				playerPosition = targetNode.get_global_position()
				targetPosition = get_camera_offset() + inputOffset + get_v_offset_vector();
			else:
				targetPosition = get_camera_offset() + get_v_offset_vector();
		else:
			viewport = get_viewport();
		
		position = lerp(position, targetPosition, slowMoveSpeed);
		positionParent.position = lerp(positionParent.position, playerPosition, slowMoveSpeed);
		
			#list[hookName][instanceName] = null;
		
		
		##Rotating the camera
		if not GameState.is_paused():
			if GameState.get_in_state_of_play():
				var pitching := false;
				var zooming := false;
				if (Input.is_action_pressed("CameraTiltModeKey") and (in_camera_tilt_state(camTiltStates.PLAY) or in_camera_tilt_state(camTiltStates.MAKER))):
					if Input.is_action_pressed("CameraPitchUp") or Input.is_action_pressed("CameraPitchDown"):
						if rotXspeed < 4: 
							rotXspeed += 0.1
					else:
						if rotXspeed > 0: 
							rotXspeed /= 3
				
				if Input.is_action_pressed("CameraZoomIn"):
					zooming = true;
					targetZoomLevel -= zoomSpeed * delta;
				if Input.is_action_pressed("CameraZoomOut"):
					zooming = true;
					targetZoomLevel += zoomSpeed * delta
				
				if in_camera_tilt_state(camTiltStates.PLAY) or in_camera_tilt_state(camTiltStates.MAKER):
					if Input.is_action_pressed("CameraPitchUp"):
						pitching = true;
						targetRotationX += rotXspeed * delta
					if Input.is_action_pressed("CameraPitchDown"):
						pitching = true;
						targetRotationX += -rotXspeed * delta
				elif in_camera_tilt_state(camTiltStates.SHOP):
					targetRotationX = lerp_angle(targetRotationX, XRotInPlay, midMoveSpeed);
				elif in_camera_tilt_state(camTiltStates.NONE):
					targetRotationX = lerp_angle(targetRotationX, XRotInPlay, midMoveSpeed);
				
				if in_camera_tilt_state(camTiltStates.SHOP):
					rotYspeed = 1;
					targetRotationY += rotYspeed * delta;
				else:
					if not (pitching or zooming or is_instance_valid(socketHovering)):
						if Input.is_action_pressed("CameraYawLeft") or Input.is_action_pressed("CameraYawRight"):
							if rotYspeed < 2: 
								rotYspeed = 2
							if rotYspeed < 10: 
								rotYspeed += 0.1
						else:
							if rotYspeed > 0: 
								rotYspeed /= 3
						
						if Input.is_action_pressed("CameraYawLeft"):
							targetRotationY += rotYspeed * delta
						if Input.is_action_pressed("CameraYawRight"):
							targetRotationY += -rotYspeed * delta
			else:
				targetRotationY += 0.1 * delta;
				targetRotationX = lerp_angle(targetRotationX, 0.0, 5.0 * delta);
		
		if in_camera_tilt_state(camTiltStates.MAKER):
			targetRotationX = clamp(targetRotationX, deg_to_rad(-30 -30 -30 -30 -30), deg_to_rad(30));
		elif in_camera_tilt_state(camTiltStates.SHOP):
			targetRotationX = clamp(targetRotationX, deg_to_rad(0), deg_to_rad(0));
		else:
			targetRotationX = clamp(targetRotationX, deg_to_rad(-30), deg_to_rad(30));
		
		positionParent.rotation.y = lerp_angle(positionParent.rotation.y, targetRotationY, fastMoveSpeed)
		
		positionParent.rotation.x = lerp_angle(positionParent.rotation.x, targetRotationX, fastMoveSpeed)
		
		
		currentRotationX = positionParent.rotation.x;
		currentRotationY = positionParent.rotation.y;
		
		zoomLevelMultiplier = 1.0;
		if in_camera_tilt_state(camTiltStates.MAKER):
			targetZoomLevel = clamp(targetZoomLevel, 0.25, 0.5);
			if targetNode is Piece:
				zoomLevelMultiplier = 0.75;
		elif in_camera_tilt_state(camTiltStates.SHOP):
			targetZoomLevel = 0.5;
			zoomLevelMultiplier = 0.75;
		else:
			targetZoomLevel = clamp(targetZoomLevel, 0.5, 1.15);
		currentZoomLevel = lerp(currentZoomLevel, targetZoomLevel * zoomLevelMultiplier, fastMoveSpeed);
	
	
	
		
		if GameState.get_in_state_of_building():
			##Hovering pieces.
			hover_socket();
	
			##Selecting pieces.
			if Input.is_action_just_pressed("Select"):
				click_on_piece();
		
		#print(currentZoomLevel)
	
	instantSpeedFrame = false;

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if GameState.get_in_state_of_play():
				if ! in_camera_tilt_state(camTiltStates.NONE) and ! in_camera_tilt_state(camTiltStates.SHOP):
					if Input.is_action_pressed("CameraZoomModeKey"):
						if event.button_index == MOUSE_BUTTON_WHEEL_UP:
							targetZoomLevel -= 0.1
							# call the zoom function
						# zoom out
						if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
							targetZoomLevel += 0.1
							# call the zoom function
					elif Input.is_action_pressed("CameraTiltModeKey"):
						if event.button_index == MOUSE_BUTTON_WHEEL_UP:
							targetRotationX += 0.1
							# call the zoom function
						# zoom out
						if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
							targetRotationX -= 0.1
							# call the zoom function
					else:
					# rotate around the Y
						if event.button_index == MOUSE_BUTTON_WHEEL_UP:
							targetRotationY += 0.1
							# call the zoom function
						# zoom out
						if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
							targetRotationY -= 0.1
							# call the zoom function

enum camTiltStates {
	PLAY, ## Main game loop.
	COMBAT, ## Overarching main game loop.
	SHOP, ## Main shop UI. Caching!
	MAKER, ## We're making stuff.
	MAKER_LOADING, ## We're loading the shop or in the shop.
	NONE, ## Uh oh.
}
var tiltState := camTiltStates.NONE;
func in_camera_tilt_state(state := camTiltStates.NONE) -> bool:
	calc_camera_tilt_state();
	return state == tiltState;

func calc_camera_tilt_state():
	if GameState.get_in_state_of_combat(false, true):
		tiltState = camTiltStates.COMBAT;
		return;
	if GameState.get_in_one_of_given_states([GameBoard.gameState.SHOP]):
		tiltState = camTiltStates.SHOP;
		return;
	if GameState.get_in_state_of_building():
		tiltState = camTiltStates.MAKER;
		return;
	if GameState.get_in_state_of_shopping(true):
		tiltState = camTiltStates.MAKER_LOADING;
		return;
	if GameState.get_in_state_of_play(true):
		tiltState = camTiltStates.PLAY;
		return;
	tiltState = camTiltStates.NONE;
	return;

func get_camera_offset():
	return cameraOffset * currentZoomLevel * zoomLevelMultiplier;

func get_v_offset_vector():
	return Vector3(vOffset, 0.0, 0.0).rotated(Vector3(0,1,0), currentRotationY);
