extends TextureRect

class_name ActiveSlotTab

var partRef : PartActive;

var backBlank = preload("res://graphics/images/HUD/activeTab/screenBlank.png");
var backPassive = preload("res://graphics/images/HUD/activeTab/screenPassive.png");
var backUtility = preload("res://graphics/images/HUD/activeTab/screenUtility.png");
var backMelee = preload("res://graphics/images/HUD/activeTab/screenMelee.png");
var backRanged = preload("res://graphics/images/HUD/activeTab/screenRanged.png");

var iconBlank = preload("res://graphics/images/HUD/parts/Icons/Empty.png");

var targetY := 265.0;


func _process(delta):
	update_displays();
	if is_node_ready():
		position.y = lerp(position.y, targetY, delta * 20);


func _on_mouse_entered():
	#print(partRef)
	pass # Replace with function body.

func update_displays():
	if is_instance_valid(partRef):
		##The screen backing/cooldown effect
		var backTex = backBlank;
		var textColor = TextFunc.textColors["grey"];
		if partRef._get_part_type() == Part.partTypes.PASSIVE: ##which should be impossible but it's checked anyway
			backTex = backPassive;
		if partRef._get_part_type() == Part.partTypes.MELEE: 
			backTex = backMelee;
			textColor = TextFunc.textColors["melee"];
		if partRef._get_part_type() == Part.partTypes.RANGED: 
			backTex = backRanged;
			textColor = TextFunc.textColors["ranged"];
		if partRef._get_part_type() == Part.partTypes.UTILITY: 
			backTex = backUtility;
			textColor = TextFunc.textColors["utility"];
		if ! partRef.can_fire():
			backTex = backPassive;
		$ScreenHolder/ScreenBack.texture = backTex;
		$ScreenHolder/ScreenBack.position.x = clampf(partRef.get_cooldown() * -30, -30, 0);
		targetY = clampf(234.0 + (partRef.get_cooldown() * 6), 234.0, 240.0);
		##Energy cost
		if $EnergyCost.text != format_stat(partRef.get_energy_cost()):
			$EnergyCost.text = format_stat(partRef.get_energy_cost());
		if partRef.energy_affordable():
			TextFunc.set_text_color($EnergyCost, "ranged");
		else:
			TextFunc.set_text_color($EnergyCost, "unaffordable");
		pass
		##Magazine counter
		var magStr = "∞";
		if partRef is PartActiveProjectile:
			var magAmt = partRef.recountMagazine();
			magStr = ""
			magStr += str(magAmt);
			magStr += "/"
			magStr += str(partRef.get_magazine_size());
			if magAmt > 0:
				TextFunc.set_text_color($AmmoCounter, "ranged")
			else:
				TextFunc.set_text_color($AmmoCounter, "unaffordable")
		if partRef.ammoAmountOverride != null and partRef.ammoAmountOverride != "":
			magStr = str(partRef.ammoAmountOverride);
			TextFunc.set_text_color($AmmoCounter, partRef.ammoAmountColorOverride)
		if $AmmoCounter.text != str(magStr):
			$AmmoCounter.text = str(magStr);
		##Name
		if $PartName.text != str(partRef.partName):
			$PartName.text = str(partRef.partName);
		TextFunc.set_text_color($PartName, textColor);
		##Icon
		if $PartIcon.texture != partRef.partIcon:
			$PartIcon.texture = partRef.partIcon;
		
	else:
		partRef = null;
		targetY = 265;
		$ScreenHolder/ScreenBack.texture = backBlank;
		$EnergyCost.text = "";
		$AmmoCounter.text = "";
		$PartName.text = "Empty";
		TextFunc.set_text_color($PartName, "grey");
		$PartIcon.texture = iconBlank;

func format_stat(num:float):
	var text = str((floor(num * 100.0)) / 100.0)
	return text;
