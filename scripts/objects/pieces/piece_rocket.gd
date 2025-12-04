extends Piece

class_name Piece_Rocket
## Blasts the [Robot] this is equipped to in the direction it's facing while active.

var maxBlastTimer := 0.6;
var blastTimer := 0.0;
@export var firingOffsetNode : RayCast3D;
var firingOffset := Vector3.ZERO;
var firingAngle := Vector3.BACK;

func _ready():
	super();
	Hooks.add(self, "OnHitWall", "Rocket", (
		func(_other): 
			blastTimer = 0.0;
			#print("BONK!")
			)
	);

func blastoff():
	set("blastTimer", maxBlastTimer);

func phys_process_timers(delta):
	super(delta);

func phys_process_abilities(delta):
	super(delta);
	if not is_frozen() and blastTimer > 0 and hasHostRobot:
		blastTimer -= delta;
		
		var bot = hostRobot;
		#var kb = get_kickback_damage_data(0.0, get_kickback_force(), ), get_damage_types());
		
		#initiate_kickback(get_facing_direction(Vector3(0,0,-1), true));
		var kb = 2000 * (blastTimer / maxBlastTimer) * get_kickback_force() * (get_firing_direction());
		kb.y = 0;
		
		move_robot_with_force(kb);
		get_named_active("Blastoff").add_freeze_time(delta);
		
		#bot.take_damage_from_damageData(kb);
		#print(kb.get_knockback())
		#print(blastTimer);
		#print("Facing", get_facing_direction(Vector3(0,0,1)))

func get_firing_offset():
	if is_instance_valid(firingOffsetNode):
		return firingOffsetNode.global_position;
	return firingOffset + global_position;

func get_firing_direction() -> Vector3:
	var firingOffsetPos = firingOffsetNode.global_position;
	var firingOffsetTargetPos = firingOffsetNode.to_global(firingOffsetNode.target_position);
	firingAngle = firingOffsetTargetPos - firingOffsetPos;
	firingAngle = firingAngle.normalized();
	return firingAngle;
