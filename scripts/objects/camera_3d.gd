extends Camera3D

class_name Camera



var socketHovering : Socket;
var pieceHovering : Piece;

func click_on_piece():
	if GameState.get_in_state_of_building():
		var collisionMask = 8;
		
		var raycastHit = RaycastSystem.get_raycast_hit_object(collisionMask, Vector2(0,0), self);
		
		#print(raycastHit)
		if is_instance_valid(raycastHit): 
			print("RAY HITQ", raycastHit)
			if raycastHit is HurtboxHolder:
				print("RAY HITQ2", raycastHit)
				raycastHit.select_piece();

func hover_socket():
	if GameState.get_in_state_of_building():
		##Remove "hovered socket" if nothing is selected or in the pipette.
		var ply = GameState.get_player();
		if is_instance_valid(ply):
			if not (ply.is_piece_selected() or ply.is_pipette_loaded()):
				socketHovering = null;
				pieceHovering = null;
		
		var collisionMask = 32 + 128;
		
		var raycastHit = RaycastSystem.get_raycast_hit_object(collisionMask, Vector2(0,0), self);
		#print(raycastHit)
		if is_instance_valid(raycastHit): 
			#print(raycastHit, pieceHovering)
			if raycastHit is Socket and raycastHit.is_valid():
				pieceHovering = raycastHit.hover_from_camera(self);
				if pieceHovering != null:
					socketHovering = raycastHit;
			if raycastHit == pieceHovering and is_instance_valid(socketHovering): 
				socketHovering.hover_from_camera(self);
				
		else:
			if is_instance_valid(socketHovering):
				socketHovering.hover(false);
				socketHovering = null;


func get_rotation_to_fake_aiming(firingOrigin:=Vector3(0.0,0.0,0.0), return_0_if_invalid := false):
	var collisionMask = 256;
	
	#print(collisionMask);
	var raycastPos = RaycastSystem.get_mouse_world_position(collisionMask);
	if raycastPos: 
		#print(raycastPos);
		#print("ray hit something")
		##Get the offset.
		var Yoffset = raycastPos.y - firingOrigin.y;
		var raycastPosYAdjusted = Vector3(raycastPos.x, raycastPos.y + Yoffset, raycastPos.z)
		##Unproject the raycast position.
		var unproject = unproject_position(raycastPosYAdjusted);
		#print(get_viewport().get_mouse_position())
		#print(unproject)
		##Get the offset.
		var raycastPos2 = RaycastSystem.get_mouse_world_position(collisionMask, unproject);
		if raycastPos2:
			#print("ray hit floor")
			var firingOriginV2 = Vector2(firingOrigin.x, firingOrigin.z);
			var raycastPos2V2 = Vector2(raycastPos2.x, raycastPos2.z);
			#var rot = firingOriginV2.direction_to(raycastPos2V2);
			var offset = raycastPos2V2 - firingOriginV2;
			#var lookAt = Vector3(rot.x, 0, rot.y);
			var rot := firingOriginV2.angle_to_point(raycastPos2V2);
			return -rot + deg_to_rad(90.0);
	#print("ray hit nothing.")
	if return_0_if_invalid: return 0.0;
	return null;
