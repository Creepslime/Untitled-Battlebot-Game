extends PartPassive

class_name PartFan

func mods_conditional():
	var spotsFree = 1;
	for mod in mods_get_all_with_tag("Fan"):
		var PAO =  mod.try_get_part_at_offset()
		if PAO == null:
			spotsFree += 1;
		else:
			if PAO is PartPassive:
				if PAO.is_in_group("Fan"):
					spotsFree += 1;
	var modStat = 1 - (spotsFree * 0.05);
	for mod in mods_get_all_with_tag("Fan"):
		mod.edit_stat("valueTimesMult", modStat);
	pass;
