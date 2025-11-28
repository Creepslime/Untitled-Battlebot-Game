extends Piece

class_name Piece_Rocket
## Blasts the [Robot] this is equipped to in the direction it's facing while active.

var maxBlastTimer := 0.6;
var blastTimer := 0.0;

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
	if not is_frozen():
		blastTimer -= delta;
		#print("WTF")

func phys_process_abilities(delta):
	super(delta);
	if blastTimer > 0:
		var bot = get_host_robot();
		if is_instance_valid(bot):
			#var kb = get_kickback_damage_data(0.0, get_kickback_force(), ), get_damage_types());
			
			#initiate_kickback(get_facing_direction(Vector3(0,0,-1), true));
			var kb = 2000 * (blastTimer / maxBlastTimer) * get_kickback_force() * (get_facing_direction(Vector3(0,0,1), false));
			kb.y = 0;
			
			move_robot_with_force(kb);
			get_named_active("Blastoff").add_freeze_time(delta);
			
			#bot.take_damage_from_damageData(kb);
			#print(kb.get_knockback())
			#print(blastTimer);
			#print("Facing", get_facing_direction(Vector3(0,0,1)))
