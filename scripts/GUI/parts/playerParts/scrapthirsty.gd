extends PartPassive

class_name PartScrapthirsty

var healingAmount := 0.03;

func stat_registry():
	super();
	register_stat("HealingAmount", healingAmount, StatHolderManager.statIconHealing, StatHolderManager.statTags.Function, StatHolderManager.displayModes.ALWAYS);

func get_healing_amount():
	return get_stat("HealingAmount");


func _ready():
	super();
	Hooks.add(self, "OnGainScrap", "Scrapthirsty" + str(ageOrdering), 
	func(source:String, amt:int):
		if is_instance_valid(thisBot):
			if thisBot is Player:
				if ownedByPlayer:
					if source == "Kill":
						if amt > 0:
							thisBot.take_damage(-get_healing_amount() * amt);
		if is_instance_valid(hostRobot):
			if source == "Kill":
				if amt > 0:
					hostRobot.heal(get_healing_amount() * amt);
	)
	pass;
