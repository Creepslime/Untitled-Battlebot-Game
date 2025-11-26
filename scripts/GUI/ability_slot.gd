@icon ("res://graphics/images/class_icons/abilitySlot.png")
extends Control
class_name AbilitySlot
## The visual representation on the [GameHUD] for each of the player's currently equipped Active Abilities ([member Robot.active_abilities]).[br]Holds the [AbilityData] for that ability and displays it with furvor.

enum modes {
	NONE,
	ASSIGNING,
}
var curMode : modes = modes.NONE;
@export var btn_assign : Button;
@export var prevSlot : AbilitySlot;
@export var nextSlot : AbilitySlot;
@export var manager : AbilitySlotManager;
@export var lbl_name : Label;
@export var lbl_thingname : Label;
@export var lbl_energy : Label;
@export var bar_cooldown : HealthBar;
@export var bar_energy : HealthBar;
@export var blinky_energy : TextureRect;
@export var blinky_usable : TextureRect;
@export var misc_energy : Control;
@export var energyCase : TextureRect;
@export var misc_ammo : Control;
@export var misc_magazine : MagazineSlicer;
@export var misc_text : Label;
@export var lbl_cooldownCurrent : Label;
#@export var lbl_cooldownSlash : Label;
#@export var lbl_cooldownStart : Label;
@export var blinky_cooldown : TextureRect;

@export var tr_icon : TextureRect;
@export var spr_icon : Sprite2D;
@export var btn_selectReference : Button;
@export var bg_icon : NinePatchRect;
const bgIconBaseY := 77.0;

var index : int;
var referencedAbility : AbilityData;
var inputActionString : String:
	get:
		return "Fire" + str(index);
var inputKeysString : String:
	get:
		return InputManager.get_action_string(inputActionString);

func _ready():
	focus_next = get_path_to(nextSlot);
	focus_previous = get_path_to(prevSlot);
	clear_assignment();

func set_index(in_index):
	index = in_index;
	update_base_tooltips();

func update_base_tooltips():
	var tooltip = str(inputKeysString,"\n","\n"if !is_instance_valid(referencedAbility) or !is_instance_valid(referencedAbility.assignedPieceOrPart) else lbl_thingname.text + "\n","Ability Slot Empty" if referencedAbility == null else referencedAbility.manager.abilityName)
	tooltip_text = tooltip;
	for child in Utils.get_all_children("Ability slot tooltip update",self, self):
		if child is Control:
			child.tooltip_text = tooltip;

func _process(delta):
	
	selectorButtonOffset = lerp(selectorButtonOffset, 0.0, 10 * delta);
	bg_icon.position.y = bgIconBaseY + selectorButtonOffset;
	
	update_ability(referencedAbility);
	
	match curMode:
		modes.NONE:
			btn_assign.visible = false;
			btn_assign.disabled = true;
			pass;
		modes.ASSIGNING:
			btn_assign.visible = true;
			btn_assign.disabled = false;
			pass;
		_:
			curMode = modes.NONE;
			pass;
	
	#print(inputKeysString)

func _on_assign_pressed():
	manager.button_pressed.emit(self);
	pass # Replace with function body.


func assign_ability(ability : AbilityData):
	if (ability == referencedAbility):
		return;
	if ! is_instance_valid(ability) or ! is_instance_valid(ability.assignedPieceOrPart):
		return;
	if is_instance_valid(ability) and ability is AbilityData:
		print("Ability assigned!")
		referencedAbility = ability;
		set_deferred("referencedAbility", ability);
		
		var mgr = ability.get_manager()
		
		## Change the icon data.
		spr_icon.texture = mgr.icon;
		
		
		lbl_name.text = mgr.abilityName;
		if ability.assignedPieceOrPart is Piece:
			lbl_thingname.text = ability.assignedPieceOrPart.pieceName;
			TextFunc.set_text_color(lbl_thingname, "lightred");
		if ability.assignedPieceOrPart is Part:
			lbl_thingname.text = ability.assignedPieceOrPart.partName;
			TextFunc.set_text_color(lbl_thingname, "lightgreen");
		
		btn_selectReference.disabled = false;
		
		update_ability(ability);
	else:
		print("Ability cleared.")
		clear_assignment();
	pass;

var counter := 0.;
func update_ability(ability : AbilityData):
	counter += 1;
	if counter > 200:
		counter = 0;
	if ! is_instance_valid(ability):
		clear_assignment();
		return;
	var data = ability.get_ability_slot_data();
	if not data is Dictionary: ## If the data is invalid, no more of it.
		clear_assignment();
		return;
	
	## Icon and the button.
	var ref = referencedAbility.get_assigned_piece_or_part();
	var mgr = referencedAbility.get_manager();
	var iconBG = "res://graphics/images/HUD/screenGFX/screenBG.png";
	if is_instance_valid(ref):
		if ref is Piece:
			if ref.get_selected():
				iconBG = "res://graphics/images/HUD/screenGFX/screenBG_lightBlue.png";
			else:
				if selectorHovering or selectorFocused:
					iconBG = "res://graphics/images/HUD/screenGFX/screenBG_yellow.png";
				else:
					iconBG = "res://graphics/images/HUD/screenGFX/screenBG_piece.png";
		if ref is Part:
			if selectorHovering or selectorFocused:
				iconBG = "res://graphics/images/HUD/screenGFX/screenBG_yellow.png";
			else:
				iconBG = "res://graphics/images/HUD/screenGFX/screenBG_part.png";
	else:
		clear_assignment();
		return;
	tr_icon.texture = load(iconBG);
	
	
	## Energy. Deals with both the bar, as well as the energy icon in the misc window.
	var incomingEnergy = data.incomingPower;
	var requiredEnergy = data.requiredEnergy;
	var hasAvailableEnergy = incomingEnergy >= requiredEnergy;
	blinky_energy.visible = hasAvailableEnergy;
	bar_energy.set_health(min(incomingEnergy, requiredEnergy), requiredEnergy);
	bar_energy.set_alt_color(hasAvailableEnergy);
	var barTooltip = bar_energy.tooltip_text;
	misc_energy.tooltip_text = barTooltip;
	misc_energy.visible = true;
	energyCase.tooltip_text = barTooltip;
	
	var usable = data.usable;
	blinky_usable.visible = usable;
	TextFunc.set_text_color(lbl_name, "white" if usable else "scrap");
	
	## Miscellaneous text.
	var miscTextDat = "";
	if data.has("miscText"):
		miscTextDat = data["miscText"];
	misc_text.text = miscTextDat;
	misc_text.tooltip_text = miscTextDat;
	
	## Magazine.
	var showMagazine = false;
	if data.has("showMagazine"):
		if data["showMagazine"] == true:
			showMagazine = true;
			var magSize = data["magazineSize"];
			var magAmt = data["magazineAmt"];
			var cooldownTime = data["regenBulletCooldown"];
			var cooldownTimeStart = data["regenBulletCooldownStart"];
			#var cooldownPercent = data["regenBulletPercent"];
			#var cooldownPercent = 1.0;
			misc_magazine.update_contents(magSize, magAmt, cooldownTime, cooldownTimeStart);
	misc_magazine.visible = showMagazine;
	
	## Cooldown.
	var cooldownStartTime = data["cooldownStartTime"];
	if not (cooldownStartTime == 0.0 or is_zero_approx(cooldownStartTime)):
		var cooldownTime = data["cooldownTime"];
		var onCooldown = data["onCooldown"];
		blinky_cooldown.visible = onCooldown;
		lbl_cooldownCurrent.text = TextFunc.format_stat(cooldownTime, 2, false, true);
	else:
		blinky_cooldown.visible = true;
		lbl_cooldownCurrent.text = "     ";
	
	#lbl_cooldownStart.text = TextFunc.format_stat(cooldownStartTime, 2, false, true);
	#lbl_cooldownSlash.text = "/";

func clear_assignment():
	referencedAbility = null;
	lbl_name.text = "Ability Slot Empty";
	lbl_thingname.text = "";
	TextFunc.set_text_color(lbl_name, "lightred");
	bar_energy.set_health(0, 0);
	blinky_energy.visible = false;
	blinky_usable.visible = false;
	blinky_cooldown.visible = false;
	misc_magazine.visible = false;
	misc_magazine.update_contents(-1,-1,0,0);
	misc_energy.visible = false;
	misc_text.text = "";
	misc_text.tooltip_text = "";
	lbl_cooldownCurrent.text = "";
	#lbl_cooldownStart.text = "";
	#lbl_cooldownSlash.text = "";
	btn_selectReference.disabled = true;
	
	var iconBG = "res://graphics/images/HUD/screenGFX/screenBG.png";
	tr_icon.texture = load(iconBG);
	spr_icon.texture = null;
	pass;


func _on_select_reference_button_pressed():
	selectorButtonPressGFX();
	if is_instance_valid(referencedAbility):
		var ref = referencedAbility.get_assigned_piece_or_part();
		if is_instance_valid(ref):
			if ref is Piece:
				ref.select_via_robot();
				return;
			##TODO: Part support
	pass # Replace with function body.

var selectorFocused := false;
func _on_select_reference_button_focus_entered():
	selectorFocused = true;
	pass # Replace with function body.
func _on_select_reference_button_focus_exited():
	selectorFocused = false;
	pass # Replace with function body.


var selectorHovering := false;
func _on_select_reference_button_mouse_entered():
	selectorHovering = true;
	pass # Replace with function body.
func _on_select_reference_button_mouse_exited():
	selectorHovering = false;
	pass # Replace with function body.

var selectorButtonOffset := 0.0;
func selectorButtonPressGFX():
	selectorButtonOffset = 2;
