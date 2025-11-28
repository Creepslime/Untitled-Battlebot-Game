extends Node

class_name SND

#Gets the physical SND node within the game board.
static func get_physical() -> SND:
	return GameState.get_physical_sound_manager();

# These are the types of players that can be in the game. COLLISION2
# through COLLISION8 exist solely for the world, at least at the
# moment. There are 8 COLLISION instances for the world, so multiple
# collision sounds can happen at the same without any of the other sounds
# being cut off.
enum Audio {
	MOVEMENT, AMBIENT, WEAPON, COLLISION, 
	COLLISION2, COLLISION3, COLLISION4, COLLISION5,
	COLLISION6, COLLISION7, COLLISION8,
}

enum AudioSrc {
	COMBATANT,
	WEPRANGED,
	WORLD,
	WEPMELEE
}

# Volume levels.
static var volumeLevelMusic := 1.0;
static func set_volume_music(inVol:=1.0):
	var mus = GameState.get_music();
	volumeLevelMusic = inVol;
	mus.set_volume(get_volume_music());
	
	GameState.set_setting("volumeLevelMusic", inVol);
static func get_volume_music():
	return volumeLevelMusic * get_volume_master();

static var volumeLevelUI := 1.0;

static func set_volume_UI(inVol:=1.0):
	volumeLevelUI = inVol;
	#print_rich("[color=green][b]", volumeLevelUI);
	
	GameState.set_setting("volumeLevelUI", inVol);
static func get_volume_UI():
	return volumeLevelUI * get_volume_master();

static var volumeLevelWorld := 1.0;
static func set_volume_world(inVol:=1.0):
	volumeLevelWorld = inVol;
	
	GameState.set_setting("volumeLevelWorld", inVol);
static func get_volume_world():
	return volumeLevelWorld * get_volume_master();

static var volumeLevelMaster := 1.0;
static func set_volume_master(inVol:=1.0):
	volumeLevelMaster = inVol;
	set_volume_world(volumeLevelWorld);
	set_volume_UI(volumeLevelUI);
	set_volume_music(volumeLevelMusic);
	
	GameState.set_setting("volumeLevelMaster", inVol);
static func get_volume_master():
	return volumeLevelMaster;

# All sounds in the game have a type assigned to them. Their type is determined
# by what the sounds are of. There are multiple keywords in a type, separated 
# with periods. From left to right, the description gets more and more specific.

# As this is a dictionary, the types are only the keys. The values are lists
# of different soundfiles of the type they belong to. When playing a sound,
# the game must use the pick_sound function to pick one sound out of the
# possibly multiple options.

static var SOUNDS = {
	"Collision.Combatant.Metal": [
		preload("res://sounds/collision/Metal_Light_01.wav"),
		preload("res://sounds/collision/Metal_Light_02.wav"),
		preload("res://sounds/collision/Metal_Light_03.mp3")
	],
	
	"Collision.Combatant.Plastic": [
		preload("res://sounds/collision/Plastic_Light_01.wav"),
		preload("res://sounds/collision/Plastic_Light_02.mp3"),
		preload("res://sounds/collision/Plastic_Light_03.wav"),
	],
	
	"Collision.Combatant.Concrete": [
		preload("res://sounds/collision/Metal_Light_01.wav"),
		preload("res://sounds/collision/Metal_Light_02.wav"),
		preload("res://sounds/collision/Metal_Light_03.mp3")
	],
	
	"Collision.Combatant.Sawblade": [
		preload("res://sounds/collision/Metal_Light_01.wav"),
		preload("res://sounds/collision/Metal_Light_02.wav"),
		preload("res://sounds/collision/Metal_Light_03.mp3")
	],
	
	"Collision.Combatant.Combatant": [
		preload("res://sounds/collision/Metal_Light_01.wav"),
		preload("res://sounds/collision/Metal_Light_02.wav"),
		preload("res://sounds/collision/Metal_Light_03.mp3")
	],
	
	"Collision.Projectile.Metal": [
		preload("res://sounds/collision/Metal_Light_01.wav"),
		preload("res://sounds/collision/Metal_Light_02.wav"),
		preload("res://sounds/collision/Metal_Light_03.mp3")
	],
	
	"Collision.Projectile.Plastic": [
		preload("res://sounds/collision/Plastic_Light_01.wav"),
		preload("res://sounds/collision/Plastic_Light_02.mp3"),
		preload("res://sounds/collision/Plastic_Light_03.wav"),
	],
	
	"Collision.Projectile.Concrete": [
		preload("res://sounds/collision/Concrete_Bullet_01.wav"),
		preload("res://sounds/collision/Concrete_Bullet_02.wav"),
		preload("res://sounds/collision/Concrete_Bullet_03.wav")
	],
	
	"Collision.Projectile.Combatant": [
		preload("res://sounds/collision/Metal_Light_01.wav"),
		preload("res://sounds/collision/Metal_Light_02.wav"),
		preload("res://sounds/collision/Metal_Light_03.mp3")
	],
	
	"Collision.MeleeWeapon.Metal": [
		preload("res://sounds/collision/Metal_Light_01.wav"),
		preload("res://sounds/collision/Metal_Light_02.wav"),
		preload("res://sounds/collision/Metal_Light_03.mp3")
	],
	
	"Collision.MeleeWeapon.Plastic": [
		preload("res://sounds/collision/Plastic_Light_01.wav"),
		preload("res://sounds/collision/Plastic_Light_02.mp3"),
		preload("res://sounds/collision/Plastic_Light_03.wav"),
	],
	
	"Collision.MeleeWeapon.Sawblade": [
		preload("res://sounds/collision/Metal_Ting_01.wav"), 
		preload("res://sounds/collision/Metal_Ting_02.wav")
	], 
	
	"Collision.MeleeWeapon.Concrete": [
		preload("res://sounds/collision/Metal_Light_01.wav"),
		preload("res://sounds/collision/Metal_Light_02.wav"),
		preload("res://sounds/collision/Metal_Light_03.mp3")
	],
	
	"Collision.Sawblade.Metal": [
		preload("res://sounds/collision/Metal_Ting_01.wav"), 
		preload("res://sounds/collision/Metal_Ting_02.wav")
	], 
	"Collision.Sawblade.Concrete": [
		preload("res://sounds/collision/Metal_Ting_01.wav"), 
		preload("res://sounds/collision/Metal_Ting_02.wav")
	], 
	
	"Collision.World.Metal": [
		preload("res://sounds/collision/Metal_Light_01.wav"),
		preload("res://sounds/collision/Metal_Light_02.wav"),
		preload("res://sounds/collision/Metal_Light_03.mp3")
	],
	
	"Collision.World.Plastic": [
		preload("res://sounds/collision/Plastic_Light_01.wav"),
		preload("res://sounds/collision/Plastic_Light_02.mp3"),
		preload("res://sounds/collision/Plastic_Light_03.wav"),
	],
	
	"Collision.World.Concrete": [
		preload("res://sounds/collision/Concrete_Bullet_01.wav"),
		preload("res://sounds/collision/Concrete_Bullet_02.wav"),
		preload("res://sounds/collision/Concrete_Bullet_03.wav")
	],
	
	"Weapon.Shoot.Heavy": [preload("res://sounds/CannonFire01.wav")],
	"Weapon.Shoot.Light": [preload("res://sounds/HigherPitchedShot.wav")],
	"Weapon.Sawblade.Drone": [preload("res://sounds/SawbladeDrone01.wav")],
	"Weapon.Sawblade.Parry": [
		preload("res://sounds/collision/Metal_Ting_01.wav"), 
		preload("res://sounds/collision/Metal_Ting_02.wav")
	],
	
	"Movement.Drone": [preload("res://sounds/Movement_Drone.ogg")],
	"Movement.Dash": [preload("res://sounds/Toaster.wav")],
	"Movement.Whoosh": [
		preload("res://sounds/Whoosh01.wav"),
		preload("res://sounds/Whoosh02.wav")
		],
	
	"Button.Press": [preload("res://sounds/PickupClick.wav")],
	
	"Bip": [preload("res://sounds/bip.ogg")],
	
	"Part.Select": [preload("res://sounds/PickupClick.wav")],
	"Part.Place": [preload("res://sounds/Toaster.wav")],
	
	"Piece.Select": [preload("res://sounds/zaps/shortzap_3.ogg")],
	"Piece.Place": [preload("res://sounds/zaps/shortzap_3.ogg")],
	
	"Metal.Ting": [
		preload("res://sounds/collision/Metal_Ting_01.wav"), 
		preload("res://sounds/collision/Metal_Ting_02.wav")
	],
	"Metal.Thump": [
		preload("res://sounds/collision/Metal_Light_01.wav"),
		preload("res://sounds/collision/Metal_Light_02.wav"),
		preload("res://sounds/collision/Metal_Light_03.mp3")
	],
	"Zap.Short": [
		preload("res://sounds/zaps/shortzap_1.ogg"),
		preload("res://sounds/zaps/shortzap_2.ogg"),
		preload("res://sounds/zaps/shortzap_3.ogg"),
		preload("res://sounds/zaps/shortzap_4.ogg")
	],
	
	"Shop.Door.Open": [
		preload("res://sounds/Shopdoor.wav")
	],
	"Shop.Door.Thump": [
		preload("res://sounds/collision/Metal_Light_03.mp3")
	],
	"Shop.Chaching": [
		preload("res://sounds/BuynSell01.wav"),
		preload("res://sounds/BuynSell02.wav"),
	],
	"Shop.Freezer.Close": [preload("res://sounds/Toaster.wav")],
	
	"Inventory.Open": [
		preload("res://sounds/Whoosh01.wav")
	],
	"Inventory.Close": [
		preload("res://sounds/Whoosh02.wav")
	],
	
	"Combatant.Die": [
		preload("res://sounds/DeathNoise01.wav"),
		preload("res://sounds/DeathNoise02.wav"),
		preload("res://sounds/DeathNoise03.wav"),
		preload("res://sounds/DeathNoise04.wav"),
	]
}

# When two things collide, what noise do we make? If the sawblade hits the
# world, do we hear the metallic sawblade, or the concrete of the world? This
# is part of how we figure it out. The higher value a key has, the more
# priority it has in being played.
static var COLLIDER_PRIORITIES = {
	"Combatant": 1,
	"Projectile": 2,
	"World": 3,
	"MeleeWeapon": 4,
	"Sawblade": 5,
	"Other": 0
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Picks one of multiple .wav file options for a given sound.
static func pick_sound(soundType:String):
	if soundType in SOUNDS:
		var soundOptions = SOUNDS[soundType];
		
		var rand = RandomNumberGenerator.new();
		rand.randomize();
		
		return soundOptions[rand.randi_range(0, len(soundOptions) - 1)];
	print("No sound type called ", soundType)
	return null;

# Takes two objects that collided with each other, and returns the proper sound
# that should be played for the collision.
static func get_proper_collision_sound_string(collider1: Node3D, collider2: Node3D):
	if not (is_instance_valid(collider1) and is_instance_valid(collider2)): return null;
	var collider1Audiosrc = "Other";
	var collider2Audiosrc = "Other";
	
	if collider1.is_in_group("Combatant"):
		collider1Audiosrc = "Combatant"
	elif collider1.is_in_group("Sawblade"):
		collider1Audiosrc = "Sawblade"
	elif collider1.is_in_group("MeleeWeapon"):
		collider1Audiosrc = "MeleeWeapon"
	elif collider1.is_in_group("World"):
		collider1Audiosrc = "World"
	elif collider1.is_in_group("Projectile"):
		collider1Audiosrc = "Projectile";
	
	if collider2.is_in_group("Combatant"):
		collider2Audiosrc = "Combatant"
	elif collider1.is_in_group("Sawblade"):
		collider1Audiosrc = "Sawblade"
	elif collider2.is_in_group("MeleeWeapon"):
		collider2Audiosrc = "MeleeWeapon"
	elif collider2.is_in_group("World"):
		collider2Audiosrc = "World"
	elif collider2.is_in_group("Projectile"):
		collider2Audiosrc = "Projectile";
		
	var collider1Priority = COLLIDER_PRIORITIES[collider1Audiosrc];
	var collider2Priority = COLLIDER_PRIORITIES[collider2Audiosrc];
	
	# the node that will be making the sound.
	var soundMaker;
	var soundMakerAudiosrc
	if collider1Priority > collider2Priority:
		soundMaker = collider1;
		soundMakerAudiosrc = collider1Audiosrc;
	else:
		soundMaker = collider2;
		soundMakerAudiosrc = collider2Audiosrc;
		
	var material;
	if soundMaker.is_in_group("Metal"):
		material = "Metal"
	elif soundMaker.is_in_group("Concrete"):
		material = "Concrete"
	elif soundMaker.is_in_group("Plastic"):
		material = "Plastic"
	
	var result = "Collision." + str(soundMakerAudiosrc) + "." + str(material)
	#print(result);
	return result;

static func get_proper_collision_sound(collider1: Node3D, collider2: Node3D):
	var sndString = get_proper_collision_sound_string(collider1, collider2);
	if sndString == null: return;
	var snd = pick_sound(sndString)
	if is_instance_valid(snd):
		return snd;
	
	#print("Sound unavailable: ", sndString);
	return;

static var sound3DScene := preload("res://scenes/prefabs/utilities/sound3D.tscn");
static var sound2DScene := preload("res://scenes/prefabs/utilities/sound_2d.tscn");
static var sound1DScene := preload("res://scenes/prefabs/utilities/sound1D.tscn");

##For playing a sound in 3D worldspace.
static func play_sound_at(inSound, inGlobalPosition:Vector3, parent = GameState.get_game_board(), inVolume := 1.0, inPitch := 1.0):
	var snd;
	if inSound is String: 
		snd = pick_sound(inSound);
	elif inSound is AudioStream:
		snd = inSound;
	else:
		return;
	
	var newSound = sound3DScene.instantiate();
	if is_instance_valid(parent):
		parent.add_child(newSound);
	else:
		return;
	newSound.global_position = inGlobalPosition;
	newSound.volume_db = linear_to_db(inVolume * get_volume_world());
	newSound.pitch_scale = inPitch;
	newSound.set_and_play_sound(snd);
	return newSound;

##For playing a sound in 2D worldspace.
static func play_sound_2D(inSound, inGlobalPosition:=Vector2(0,0), parent = GameState.get_hud(), inVolume := 1.0, inPitch := 1.0):
	var snd;
	if inSound is String: 
		snd = pick_sound(inSound);
	elif inSound is AudioStream:
		snd = inSound;
	else:
		return;
	
	var newSound = sound2DScene.instantiate();
	if is_instance_valid(parent):
		parent.add_child(newSound);
	else:
		return;
	newSound.global_position = inGlobalPosition;
	newSound.volume_db = linear_to_db(inVolume * get_volume_UI());
	newSound.pitch_scale = inPitch;
	newSound.set_and_play_sound(snd);
	return newSound;

##For playing a sound without any panning.
static func play_sound_nondirectional(inSound, inVolume := 1.0, inPitch := 1.0):
	var snd;
	var parent = GameState.get_hud();
	if inSound is String: 
		snd = pick_sound(inSound);
	elif inSound is AudioStream:
		snd = inSound;
	else:
		return;
	
	var newSound = sound1DScene.instantiate();
	if is_instance_valid(parent):
		parent.add_child(newSound);
	else:
		return;
	
	newSound.volume_db = linear_to_db(inVolume * get_volume_UI());
	#print_rich("[color=green][b]", get_volume_UI());
	newSound.pitch_scale = inPitch;
	newSound.set_and_play_sound(snd);
	return newSound;

static func play_purchase_sound(inVolume := 1.0):
	var randomSpeed = randf_range(0.9, 1.05);
	play_sound_nondirectional("Shop.Chaching", inVolume, randomSpeed)

static func play_collision_sound(collider1: Node3D, collider2: Node3D, inGlobalPositionOffset:=Vector3.ZERO, inVolume := 1.0, inPitch := 1.0):
	if not (is_instance_valid(collider1) and is_instance_valid(collider2)): return null;
	var sound = get_proper_collision_sound(collider1, collider2);
	var playPos = ((collider1.global_position + collider2.global_position) / 2) + inGlobalPositionOffset;
	if collider1 is StaticBody3D:
		playPos= (collider2.global_position) + inGlobalPositionOffset;
	if collider2 is StaticBody3D:
		playPos= (collider1.global_position) + inGlobalPositionOffset;
	play_sound_at(sound, playPos, GameState.get_game_board(), inVolume, inPitch);
