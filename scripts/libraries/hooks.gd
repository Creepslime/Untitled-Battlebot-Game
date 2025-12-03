@icon("res://graphics/images/class_icons/hook.png")
extends Node;

# List of all hooks:
# Attack
#	OnFireProjectile
#	OnMeleeWeaponHit
#	OnMeleeWeaponSwing
#	OnActiveUse
#
# Physics
#	OnWallCollision
# 	OnEnemyCollision
# 	OnPlayerCollision
#	OnCollision

enum hookNames {
	OnFireProjectile,
	OnMeleeWeaponHit,
	OnMeleeWeaponSwing,
	OnActiveUse,
	OnHitWall,
	OnEnemyCollision,
	OnPlayerCollision,
	OnCollision,
	OnDeath,
	OnGainScrap,
	OnLand,
	OnChangeGameState,
	OnRerollShop,
	
	OnScreenTransition,
	OnLoadSettings
}

var list = {
	"OnFireProjectile": {}, #
	"OnMeleeWeaponHit": {}, #
	"OnMeleeWeaponSwing": {}, #
	"OnActiveUse": {}, #
	"OnHitWall": {}, #
	"OnEnemyCollision": {}, #
	"OnPlayerCollision": {},  #
	"OnCollision": {}, #
	"OnDeath": {}, #
	"OnGainScrap": {}, #
	"OnLand": {}, #
	"OnChangeGameState": {}, #
	"OnRerollShop": {}, #
	
	"OnScreenTransition": {}, #
	"OnLoadSettings": {},
};

var body;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass;

## Called when a part owner fires a projectile.
func OnFireProjectile(firer: PartActiveProjectile, projectile: Node3D):
	for hookFunc in getValidHooks("OnFireProjectile"):
		hookFunc.call(firer);
	
## Called when a melee weapon hits a combatant.
func OnMeleeWeaponHit(weapon: PartActiveMelee, victim: Node3D):
	for hookFunc in getValidHooks("OnMeleeWeaponHit"):
		hookFunc.call(weapon);

## @deprecated: Called when a melee weapon is swung or otherwise used.
func OnMeleeWeaponSwing(weapon: PartActiveMelee):
	for hookFunc in getValidHooks("OnMeleeWeaponSwing"):
		hookFunc.call(weapon);
	
## Called when something hits the wall.
func OnHitWall(collider: CollisionObject3D):
	for hookFunc in getValidHooks("OnHitWall"):
		hookFunc.call(collider);

## Called when something collides with an enemy.
func OnEnemyCollision(collider1: CollisionObject3D, collider2: CollisionObject3D):
	for hookFunc in getValidHooks("OnEnemyCollision"):
		hookFunc.call(collider1, collider2);

## Called when something collides with a player.
func OnPlayerCollision(collider: Node):
	for hookFunc in getValidHooks("OnPlayerCollision"):
		hookFunc.call(collider);

## @deprecated: Called when two things collide.
func OnCollision(collider1: CollisionObject3D, collider2: CollisionObject3D):
	for hookFunc in getValidHooks("OnCollision"):
		hookFunc.call(collider1, collider2);

## Called when an active part is used.
func OnActiveUse(activePart: PartActive):
	for hookFunc in getValidHooks("OnActiveUse"):
		activePart;

## Called when a combatant dies.
func OnDeath(thisBot : Robot, killer):
	for hookFunc in getValidHooks("OnDeath"):
		hookFunc.call(thisBot, killer);

## Called when the player gets richer.
func OnGainScrap(source: String, amount:int):
	print_rich("[color=yellow]Scrap amount change ", amount, " from source ",source, ". New amount: ",ScrapManager.get_scrap())
	for hookFunc in getValidHooks("OnGainScrap"):
		hookFunc.call(source, amount);

## Called when a Robot hits the floor.
func OnLand(thisBot: Robot, airtime: float):
	for hookFunc in getValidHooks("OnLand"):
		hookFunc.call(thisBot, airtime);

func OnRerollShop():
	for hookFunc in getValidHooks("OnRerollShop"):
		hookFunc.call();

func OnChangeGameState(oldState: GameBoard.gameState, newState: GameBoard.gameState):
	for hookFunc in getValidHooks("OnChangeGameState"):
		hookFunc.call(oldState, newState);

func OnScreenTransition(state : ScreenTransition.mode):
	for hookFunc in getValidHooks("OnScreenTransition"):
		hookFunc.call(state);

##Fired when settings are loaded.
func OnLoadSettings():
	for hookFunc in getValidHooks("OnLoadSettings"):
		hookFunc.call();

var hookID := -1;
func get_unique_hook_id() -> int:
	hookID += 1;
	return hookID;

## Use to add a hook.[br]
## To use, we go to any file and call like this:[br]
##[codeblock]
## Hooks.add(self, "OnActiveUse", "OurImplementation", func (part: ActivePart):
## 	 print("We used an active item!")
## , -1)
##
## ## When hook "OnActiveUse" is called, this node will print "We used an active item!", at a priority of -1 (which means it is called before anything with EX. priority 0.)
##[/codeblock]
func add(nodeRef:Node, hookName:String, instanceName: String, hookFunc: Callable, priority := 0):
	## Set up the dictionary for this hook.
	if ! list.has(hookName):
		list[hookName] = {};
	## If we already have a hook by the given name, then make the name unique.
	if list[hookName].has(instanceName):
		instanceName += str(get_unique_hook_id());
	## Put the hook into the sub-dict.
	list[hookName][instanceName] = {"func":hookFunc, "source":nodeRef, "priority":priority};
	pass;

## Identical to [method add], except [param _hookName] is a value from [enum hookNames] instead of a [String].
func add_enum(nodeRef:Node, _hookName:hookNames, instanceName: String, hookFunc: Callable, priority := 0):
	var hookName = hookNames.keys()[_hookName];
	add(nodeRef, hookName, instanceName, hookFunc);

## Returns a valid list of functions to loop through. Also sorts them by priority.
func getValidHooks(hookName:String) -> Array[Callable]:
	var ret : Array[Callable] = [];
	var preSortRet = [];
	if list.has(hookName):
		var badHooks = [];
		## Add valid hooks.
		for hookKey in list[hookName]:
			var hookFunc = list[hookName][hookKey];
			
			#if hookName == "OnChangeGameState":
				#prints(hookKey, hookFunc);
			
			if is_instance_valid(hookFunc.source):
				preSortRet.append(hookFunc);
			else:
				badHooks.append(hookKey);
		
		## Erase bad ones.
		for hookKey in badHooks:
			#print("INVALID HOOK IN %s: "%[hookName], hookKey)
			list[hookName].erase(hookKey);
	
	## Sort the hooks by priority.
	preSortRet.sort_custom(sort_hooks_by_priority);
	
	#if hookName == "OnChangeGameState":
		#print(preSortRet);
	
	for hookFunc in preSortRet:
		ret.append(hookFunc.func);
	
	return ret;

## Sort function; Sorts a given hook data list by priority. Negative priority means it will run first.
func sort_hooks_by_priority(hookDataA, hookDataB):
	return hookDataA.priority < hookDataB.priority;
