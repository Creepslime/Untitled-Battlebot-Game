extends Resource

class_name DamageData

var attackerRobot : Robot;
var damageAmount := 1.0;
var knockbackAmount := 0.0;
var damageDirection := Vector3.ZERO;
var targetDamagePosition := Vector3.ZERO;
var attackerDamagePosition := Vector3.ZERO;
enum damageTypes {
	BLUDGEONING,
	PIERCING,
	HEATED,
	CORROSIVE,
	EXPLOSIVE,
}
var tags : Array[damageTypes] = [];

func create(_damageAmount, _knockback, _direction := Vector3.ZERO, _damageTypes : Array[damageTypes] = [damageTypes.BLUDGEONING]):
	damageAmount = _damageAmount;
	knockbackAmount = _knockback;
	damageDirection = _direction;
	tags = _damageTypes;
	return self;

func make_copy():
	var copy = duplicate(true);
	return copy;

func get_damage():
	return damageAmount;

func get_knockback():
	return knockbackAmount * damageDirection;

func calc_damage_direction_based_on_targets(_attackerPos : Vector3, _targetPos = null, towardsAttacker := false):
	attackerDamagePosition = _attackerPos;
	if _targetPos is Vector3:
		#print("valid, ", _targetPos)
		targetDamagePosition = _targetPos; ## Set it to this just to be safe.
	else:
		targetDamagePosition = _attackerPos; ## Set it to this just to be safe.
	if towardsAttacker:
		damageDirection = (attackerDamagePosition - targetDamagePosition).normalized();
	else:
		damageDirection = (targetDamagePosition - attackerDamagePosition).normalized();
	
	return damageDirection;

func get_damage_position_local(forTarget := true):
	if forTarget:
		return targetDamagePosition - attackerDamagePosition;
	else:
		return attackerDamagePosition - targetDamagePosition;

func has_type(tag : damageTypes):
	return tags.has(tag);
