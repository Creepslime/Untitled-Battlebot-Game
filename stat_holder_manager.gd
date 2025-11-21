@icon("res://graphics/images/class_icons/statHolderManager.png")
extends Node
## The global node keeping track of all [StatHolder3D] and (TODO)[StatHolder2D] nodes.

var all_stat_holders : Dictionary[int, Node] = {}

var statHolderID := 0;

var freeIDS : Array[int]; ## An array of IDs that are no longer being used.

func get_unique_stat_holder_id() -> int:
	clear_invalid_stat_holders();
	if freeIDS.is_empty():
		var ret = statHolderID;
		statHolderID += 1;
		return ret;
	else:
		var ret = freeIDS.pop_front();
		return ret;

func register_stat_holder(object):
	clear_invalid_stat_holders();
	##Todo: Add StatHolder2D as a class for Parts to inherit from.
	if object is StatHolder3D:
		all_stat_holders[object.statHolderID] = object;
		print("Added ",object," as a StatHolder with ID ", object.statHolderID)
	#elif object is StatHolder2D:
		#pass;

## Clear out any invalid entries in the list and frees them up.
func clear_invalid_stat_holders():
	var idsToFree = []
	for id in all_stat_holders.keys():
		var holder = all_stat_holders[id];
		if !is_instance_valid(holder):
			idsToFree.append(id);
			pass;
	for id in idsToFree:
		AbilityDistributor.remove_id_from_abilities(id);
		all_stat_holders.erase(id);
		freeIDS.append(id)

func get_stat_holder_by_id(id):
	clear_invalid_stat_holders();
	if all_stat_holders.keys().has(id):
		return all_stat_holders[id];
	return null;
