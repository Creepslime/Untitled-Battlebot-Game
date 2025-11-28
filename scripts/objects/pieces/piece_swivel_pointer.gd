extends Piece_Swivel

class_name Piece_SwivelPointer
## On a [Robot_Player], points at your crosshair.[br]
## On a [Robot], points at the player, or another target that's been manually plugged in.[br]
## Will not function if it is not sitting roughly vertically relative to the ground.

var cam : GameCamera;
var pointerLocation := Vector3.ZERO;

func can_use_passive(passiveAbility):
	if passiveAbility.abilityName == "Target":
		var result = super(passiveAbility) and isVertical;
		if ! result: targetRotation = 0;
		return result;
	return super(passiveAbility);

var verticalCheckTimer := 15;
var isVertical := false;
var needsCam := false;

func _ready():
	super();

func phys_process_pre(delta):
	super(delta);
	needsCam = has_robot_host() and hostRobot is Robot_Player;
	if needsCam and !is_instance_valid(cam):
		cam = GameState.get_camera();
	
	verticalCheckTimer -=1;
	
	if verticalCheckTimer == 1:
		var rot = global_rotation_degrees;
		isVertical = (rot.x < 5.0 and rot.x > -5.0 and rot.z < 5.0 and rot.z > -5.0);
		verticalCheckTimer = 15;

func target():
	var prevRotation = targetRotation;
	var bot = get_host_robot();
	if is_instance_valid(bot):
		if bot is Robot_Player:
			var rot = cam.get_rotation_to_fake_aiming(global_position);
			
			if rot != null:
				targetRotation = rot - get_host_robot().get_global_body_rotation().y - get_host_socket().rotation.y;
			else:
				targetRotation = prevRotation;
		elif bot is Robot_Enemy:
			pointerLocation = bot.pointerTarget;
			targetRotation = Vector2(pointerLocation.x, pointerLocation.z).angle() - get_host_socket().rotation.y - global_rotation.y;
	else:
		pass;
