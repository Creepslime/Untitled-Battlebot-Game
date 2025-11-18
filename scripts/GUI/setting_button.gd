extends CheckButton
class_name SettingCheckButton
## Provides a simple self-contained button for "on-or-off" type settings, with support for number setting so that setting "startingScrap" can use it.

@export var settingName : StringName;
var loading = true;
@export var numValueWhenTrue := 99999999;
@export var numValueWhenFalse := 0;

func _ready():
	Hooks.add(self, "OnLoadSettings", settingName, load_setting)
	load_setting();
	
	call_deferred("connect", "toggled", _on_toggled);

func _process(delta):
	disabled = loading;

func load_setting():
	loading = true;
	var settingValue = GameState.get_setting(settingName);
	if settingValue is bool:
		set_pressed_no_signal(settingValue);
	elif settingValue is float or settingValue is int:
		set_pressed_no_signal(settingValue != 0);
	draw.emit();
	loading = false;

func _on_toggled(toggled_on : bool):
	var settingValue = GameState.get_setting(settingName);
	if settingValue is bool:
		GameState.set_setting(settingName, toggled_on);
	elif settingValue is float or settingValue is int:
		if toggled_on:
			GameState.set_setting(settingName, numValueWhenTrue);
		else:
			GameState.set_setting(settingName, numValueWhenFalse);
	draw.emit();
