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
func OnDeath(thisBot : Robot, killer : Robot):
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

## Use to add a hook.[br]
## To use, we go to any file and call[br]
##[codeblock]
## Hooks.add("OnActiveUse", "OurImplementation", func (part: ActivePart):
## 	 print("We used an active item!")
## )
##[/codeblock]
func add(nodeRef:Node, hookName: String, instanceName: String, hookFunc: Callable):
	list[hookName][instanceName] = {"func":hookFunc, "source":nodeRef};
	#list[hookName][instanceName] = null;

## Returns a valid list of functions to loop through.
func getValidHooks(hookName:String):
	var ret = [];
	if list.has(hookName):
		for hookKey in list[hookName]:
			var hookFunc = list[hookName][hookKey];
			#print_rich("[color=blue]",hookKey)
			if is_instance_valid(hookFunc.source):
				ret.append(hookFunc.func);
				#print_rich("[color=blue]","Valid key");
			else:
				list[hookName].erase(hookKey);
	#print_rich("[color=purple]",hookName," ",list)
	print_rich("[color=purple]Hook called: ", hookName, "\nValid hooks: ",ret)
	return ret;
