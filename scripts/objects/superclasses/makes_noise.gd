class_name MakesNoise;
extends Node3D;

var PLAYER_PARENT;
@export var AudioSourceType: Sound.AudioSrc;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	return
	PLAYER_PARENT = %_AudioStreamPlayers;
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# plays a sound assigned to a specific soundID
func play_sound(soundID, audioplayer = null):
	# if an audioplayer wasn't given, we need to figure out ourselves what
	# channel it will use.
	if !audioplayer:
		# The first keyword in the soundID corresponds to the audiostreamplayer
		# the sound plays on, so we need to get that keyword.
		var idSplit = soundID.split(".");
		match idSplit[0]:
			"Movement":
				audioplayer = PLAYER_PARENT.get_node("Movement");
			"Ambient":
				audioplayer = PLAYER_PARENT.get_node("Ambient");
			"Weapon":
				audioplayer = PLAYER_PARENT.get_node("Weapon");
			"Collision":
				# there can be multiple collision audioplayers, so we need to
				# find a free one.
				for i in range(1, 8):
					var audioplayerNode;
					if i == 1:
						audioplayerNode = PLAYER_PARENT.get_node("Collision");
					else:
						audioplayerNode = get_node("Collision" + str(i));
						
					# if there isn't a numerical collision with the current number,
					# there's not gonna be one with the next.
					if !audioplayerNode: break;
					
					var playbackPosition = audioplayerNode.get_playback_position();
					
					# we need to check if it's either 1. never played a sound, or
					# 2. has finished the last sound it played.
					if !playbackPosition || playbackPosition >= 1: 
						audioplayer = audioplayerNode;
						break;
						
		if !audioplayer:
			assert("tried to play sound on nonexistent channel");
		else:
			var audioStream = SND.pick_sound(soundID);
			audioplayer.set_stream(audioStream);
			audioplayer.play();

func stop_sound(audioplayer):
	get_node(audioplayer).stop();
