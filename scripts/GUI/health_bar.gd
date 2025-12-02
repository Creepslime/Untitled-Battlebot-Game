@tool
@icon ("res://graphics/images/class_icons/healthbar.png")
extends SubViewportContainer

class_name HealthBar
## Displays a fancy bar with a minimum and maximum value.

@export_subgroup("Numbers")
@export var resourceName := "HP"; ## The name of this bar, used in the tooltip.
@export var width := 163.0; ## How wide this bar is.
@export var height := 72.0; ## How high this bar is.
var realLength := 0.; ## Calculated based on the current padding and width/height.
@export var offset := 0.0; ##@deprecated: An offset from the start of the bar... if it wasn't deprecated. Does nothing.
@export var paddingStart := 0.0; ## Padding for the bar on the left if horizontal, and top if vertical.
@export var paddingEnd := 0.0; ## Padding for the bar on the right if horizontal, and bottom if vertical.
@onready var targetPos := width; ## Set by code. The position [member lerpPosX] tries to lerp to.
@onready var lerpPosX := width; ## Set by code. The lerp'd position for the bar.
@export var currentAmt := 0.0; ## The current minimum amount for this bar. Set by code outside of the editor.
@export var currentMax := 0.0; ## The current maximum amount for this bar. Set by code outside of the editor.
@export var EDITOR_fillAmt := -1.; ## Controls how full the bar appears in the editor; Clamps up to [member currentMax].[br]When set to -1., the bar will cycle from its minimum to maximum inside the editor.
@export_subgroup("Textures")
@export var maskTexture :CompressedTexture2D = preload("res://graphics/images/HUD/Health_EmptyOverlayMask.png"); ## The texture that masks the [member emptyTexture] when it goes beyond the bounds.[br]This texture should be a black&white image, where white is fully visible, and black is fully masked. I'm pretty sure grey pizels will result in some transparency.
@export var fullTexture := preload("res://graphics/images/HUD/Health_FullOverlay.png"); ## The texture used in the BG to convey a full bar.
@export var emptyTexture := preload("res://graphics/images/HUD/Health_EmptyOverlay.png") ## The texture used in the foreground by [member emptyBar] to depict the empty portion of the bar.
@export var emptyBar : TextureRect; ## The [TextureRect] node that displays the empty portion of the bar.
enum directions {
	FILL_TO_RIGHT, ## The bar fills from left to right.
	FILL_TO_LEFT, ## The bar fills from right to left.
	FILL_TO_TOP, ## The bar fills from bottom to top.
	FILL_TO_BOTTOM, ## The bar fills from top to bottom.
}
@export var direction : directions = directions.FILL_TO_RIGHT; ## The direction the bar fills, from [enum directions].
var vertical; ## Set by code as true if [member direction] is set to [enum directions.FILL_TO_TOP] or [enum directions.FILL_TO_BOTTOM].
@export_subgroup("Label Settings")
@export var label : Label; ## The label that depicts the number.
@export var colorBase := "lightred"; ## The color the bar is typically displayed with. See [member colorAlt].
@export var colorAlt := "scrap"; ## The "alt color". Used when [member altColorOn] is [code]true[/code] over [member colorBase].
var altColorOn : bool = false; ## Set via [method set_alt_color] outside this node.[br]If [code]true[/code], the color being used for the number is [member colorBase].[br]If [code]false[/code], the color being used for the number is [member colorAlt].
@export var hasLabel := true; ## Whether the bar displays the amount.
@export var addSpaces := true; ## Whether empty decimal places after the amount should be filled with spaces.
@export var addZeroes := false; ## Whether empty decimal places after the amount should be filled with zeroes.
@export var decimalPlaces := 2; ## How many decimal places for the amounts to display with.


func _ready():
	%FullHealth.texture = fullTexture;
	%EmptyHealth.texture = emptyTexture;
	
	material.set("shader_parameter/mask", maskTexture);
	
	if not hasLabel:
		$%Lbl_Health.hide();
	else:
		if label == $%Lbl_Health:
			$%Lbl_Health.set_deferred("size", size);
		else:
			$%Lbl_Health.hide();
	
	currentAmt = 0.0;
	currentMax = 3.0;
	
	if Engine.is_editor_hint():
		currentMax = 100.

## Ultimately sets [member targetPos] using the given [param _amt] as the current amount and [param _max] as the maximum. 
func set_health(_amt: float, _max: float):
	var percentage : float = _amt/_max;
	if is_equal_approx(_amt, _max):
		percentage = 1.0;
	if is_equal_approx(_amt, 0):
		percentage = 0.0;
	match direction:
		directions.FILL_TO_RIGHT:
			targetPos = paddingStart;
			vertical = false;
			realLength = width - paddingEnd - paddingStart;
			targetPos += percentage * (realLength);
			pass;
		directions.FILL_TO_LEFT:
			targetPos = paddingEnd;
			vertical = false;
			realLength = width - paddingEnd - paddingStart;
			targetPos += -percentage * (realLength);
			pass;
		directions.FILL_TO_TOP:
			targetPos = -paddingEnd;
			vertical = true;
			realLength = height - paddingEnd - paddingStart;
			targetPos += -percentage * (realLength);
			pass;
		directions.FILL_TO_BOTTOM:
			targetPos = -height+paddingStart;
			vertical = true;
			realLength = height - paddingEnd - paddingStart;
			targetPos += percentage * (realLength);
			pass;
	
	currentAmt = _amt;
	currentMax = _max;
	if !Engine.is_editor_hint():
		update_text(currentAmt, currentMax);

## Sets [member altColorOn] to [param on].
func set_alt_color(on := false):
	altColorOn = on;

## Used in the editor only to refresh the amounts every few frames.
var counter = 0;
func _process(delta):
	if targetPos is not float: return;
	var oldPos = lerpPosX;
	lerpPosX = lerp(lerpPosX, targetPos, delta*20);
	if oldPos > targetPos:
		lerpPosX = clamp(lerpPosX, targetPos, oldPos);
	else:
		lerpPosX = clamp(lerpPosX, oldPos, targetPos);
	if vertical:
		emptyBar.position.x = 0;
		emptyBar.position.y = clamp(lerpPosX, -height, height);
	else:
		emptyBar.position.x = clamp(lerpPosX, -width, width);
		emptyBar.position.y = 0;
	
	%FullHealth.size = fullTexture.get_size();
	%EmptyHealth.size = emptyTexture.get_size();
	
	if Engine.is_editor_hint():
		if EDITOR_fillAmt >= 0:
			currentAmt = EDITOR_fillAmt;
		else:
			currentAmt += 0.05;
			if currentAmt > currentMax:
				currentAmt -= currentMax;
		
		set_health(currentAmt, currentMax);
		#print(currentAmt, currentMax)
		#print(emptyBar.size)
		
		if altColorOn:
			TextFunc.set_text_color(label, colorAlt);
		else:
			TextFunc.set_text_color(label, colorBase);
	else:
		counter -= 1;
		if counter <= 0:
			counter = 2;
			update_text(currentAmt, currentMax);

## Updates the label (if [member hasLabel] is [code]true[/code]) to represent the given amount/max.
func update_text(_amt : float, _max: float):
	if not hasLabel:
		return;
	var stringHealth = TextFunc.format_stat(_amt, decimalPlaces, addSpaces, addZeroes) + "/" + TextFunc.format_stat(_max, decimalPlaces, addSpaces, addZeroes);
	label.text = stringHealth;
	tooltip_text = str(resourceName, "\n",stringHealth);
	if altColorOn:
		TextFunc.set_text_color(label, colorAlt);
	else:
		TextFunc.set_text_color(label, colorBase);
