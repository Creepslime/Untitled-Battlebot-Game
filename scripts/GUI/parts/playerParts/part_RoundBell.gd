extends PartPassive

class_name Part_RoundBell

@export var healAmount := 0.25

func stat_registry():
	super();
	register_stat("HealingAmount", healAmount, StatHolderManager.statIconHealing, StatHolderManager.statTags.Function, StatHolderManager.displayModes.ALWAYS);

func get_healing_amount():
	return get_stat("HealingAmount");

func _ready():
	super();
	Hooks.add(self, "OnEndRound", "RoundBell", end_round_heal, 1);

func end_round():
	super();

func end_round_heal(_roundNumber : int):
	#thisBot.take_damage(-get_healing_amount());
	if hasHostRobot:
		hostRobot.heal(get_healing_amount());
