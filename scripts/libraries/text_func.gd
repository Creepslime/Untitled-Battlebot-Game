@tool
extends Node

# Colors for text.
enum textColorsEnum {
	white,
	grey,
	utility,
	lightgreen,
	ranged,
	lightblue,
	melee,
	lightred,
	scrap,
	red,
	unaffordable,
	inaffordable,
	outline,
	magenta,
}
const textColors = {
	"white" : Color("ffffff"),
	"grey" : Color("e0dede"),
	"utility" : Color("aae05b"),
	"lightgreen" : Color("aae05b"),
	"ranged" : Color("789be9"),
	"lightblue" : Color("789be9"),
	"melee" : Color("ff6e49"),
	"lightred" : Color("ff6e49"),
	"scrap" : Color("f2ec6b"),
	"red" : Color("cf2121"),
	"unaffordable" : Color("ff0000"),
	"inaffordable" : Color("ff0000"),
	"outline" : Color("240e0e"),
	"magenta" : Color("bd2064"),
}

## Recolors a Label or RichTextLabel or TextEdit or anythign else of the sort with [method Label.theme_override_colors/font_color].
func set_text_color(node, _color):
	if is_instance_valid(node) and "theme_override_colors/font_color" in node:
		#print("Thing in thing")
		var color = get_color(_color);
		if node.get("theme_override_colors/font_color") != color:
			#print("color for ",node, " being set from: ", node.get("theme_override_colors/font_color"), "to: ",color);
			node.set_deferred("theme_override_colors/font_color", color);

## Returns a predefined color from [member textColors] if given a String key, or returns a given Color input as-is. Returns Color.WHITE if the input is not a String or Color.
func get_color(_color) -> Color:
	if _color is textColorsEnum: ##Get the string from the enum name.
		_color = textColorsEnum.keys()[_color];
	elif _color is Color:
		return _color;
	elif _color is String:
		var newCol := Color(textColors["white"]);
		if _color in textColors:
			newCol = Color(textColors[_color]);
		else:
			newCol = Color(_color);
		return newCol;
	return Color.WHITE;

## Returns a string to be used for stats. Shortens decimal places down to the desired amount. If there is a decimal, adds spaces or zeroes to the end while the resulting string is lower than the desired length. If no decimals, the number is truncated to an int before being converted to a string via [method round_to_dec].
func format_stat(num:float, decimal_places:int=2, addSpaces := true, addZeroes := false) -> String:
	var s = str(int(num))
	var sLength = s.length();
	if decimal_places <= 0:
		return str(int(round_to_dec(num, 0)));
	else:
		var targetLength = sLength + decimal_places + 1; ## The amount of numbers without the decimals, then the amount of decimal_places, then the literal decimal "." .
		s = str(round_to_dec(num, decimal_places))
		if addZeroes:
			while s.length() < targetLength:
				s += "0";
		elif addSpaces:
			while s.length() < targetLength:
				s += " ";
		return s;

## Returns a string to be used for StatIcons. Adds a space character to the start if the number is below 10.
func format_stat_num(num, decimal_places : int = 2, character := " ") -> String:
	var factor = 10^decimal_places;
	var inNum = (floor(num*factor))/factor
	
	var outString = ""
	if inNum >= 10:
		outString = str(inNum);
	else:
		outString = character + str(inNum);
	
	if outString.length() < 5:
		outString += "0";
	return outString;

## Returns a number rounded to the desired amount of [param decimal_places].
func round_to_dec(num, decimal_places):
	return round(num * pow(10.0, decimal_places)) / pow(10.0, decimal_places)

## Returns the decimal cut off from the given [float] [param num], run through [method round_to_dec] to get the desired amount of decimal places.[br][br]
## EX: [codeblock]
## get_decimal(1.002467, 3) ## Returns 0.002
## get_decimal(55.4767, 2) ## Returns 0.48
## [/codeblock]
func get_decimal(num, decimal_places) -> float:
	var numToCut = round_to_dec(num, decimal_places);
	var knifeNum = floor(num);
	return numToCut - knifeNum;

## Returns the string for the decimal of a number, with or without the starting 0.[br]Returns an empty string if [param decimal_places] is set to 0[br][br]
## EX. [codeblock]
## get_decimal_string(1.002467, 3, true) ## Returns "0.002"
## get_decimal_string(55.4767, 2, false) ## Returns ".48"
## get_decimal_string(55.1, 0, false) ## Returns ""
## [/codeblock]
func get_decimal_string(num, decimal_places, includeZero := true) -> String:
	if decimal_places == 0:
		return "";
	var ret = str(get_decimal(num, decimal_places));
	if includeZero:
		return ret;
	else:
		return ret.trim_prefix("0");

## Formats time in a minutes:seconds format and returns the string, or seconds only if [param max_minutes] is 0. Minutes can't exceed [param max_minutes] if > 0.[br]
## Hours can be displayed only if [param max_minutes] and [param max_hours] are both > 0. If [param max_hours] > 0, [param max_minutes] is [u]ignored[/u] and will instead do the same while loop seconds does to convert to minutes.[br]If [param max_hours] < 0, hours have no limit.[br][br]
## if [param max_minutes] <= 0, only then will [param max_seconds] will be applied, and provide a ceiling for the seconds count (99 by default).[br]If [param max_seconds] is 0, but there are minutes allowed, then only minutes get returned.[br][br]
## EX:[codeblock]
## format_time(0.1); ## Returns "00:00"
## format_time(25); ## Returns "00:25"
## format_time(81, 2); ## Returns "01:21.00"
## format_time(100.248456, 2, 99); ## Returns "00:01:40.25"
## format_time(360000.248456, 0, -1); ## Returns "100:00:00"
## [/codeblock]
func format_time(_timeInSeconds:float, decimal_places := 0, max_hours := 0, max_minutes := 99, max_seconds := 99):
	var hours = 0;
	var minutes = 0;
	var seconds = floori(_timeInSeconds);
	var decimalString = get_decimal_string(_timeInSeconds, decimal_places, false); ## Get the decimal string here. Doesn't matter for the rest of calculation since seconds is an integer.
	
	
	var hourString = ""
	var minuteString = ""
	var secondString = ""
	
	var hasHours = max_hours != 0;
	var hasMinutes = max_minutes != 0;
	var hasSeconds = max_seconds != 0;
	
	
	if hasHours:
		max_minutes = 60; ## If there are hours, minutes must be clamped to 60.
	
	if hasMinutes:
		max_seconds = 60; ## If there are minutes, seconds must be clamped to 60.
	else:
		hasHours = false; ## If there are no minutes, there cannot be any hours.

	
	## Count up potential minutes and hours from the given seconds.
	if hasMinutes or hasHours: ## Clamp seconds to a range of 60 if hours or minutes are present.
		while seconds >= 60:
			seconds -= 60;
			minutes += 1;
	if hasHours: ## Clamp minutes to a range of 60 if hours are present.
		while minutes >= 60:
			minutes -= 60;
			hours += 1;
	
	## Clamp all seconds, minutes, and hours to their maximums.
	## Construct the strings.
	if hasHours:
		hourString = add_char_before_int_string_up_to_max_number_length(hours, max_hours);
	if hasMinutes:
		minuteString = add_char_before_int_string_up_to_max_number_length(minutes, max_minutes);
	if hasSeconds:
		secondString = add_char_before_int_string_up_to_max_number_length(seconds, max_seconds);
	
	var ret = add_char_between_strings([hourString, minuteString, secondString]) + decimalString;
	return ret;

## Clamps the [int] input, then returns a string with (default) 0s placed before the given value if its string length is less than the maximum number input.[br]
## If [param maximum] is a negative number, this will return [code]str(num)[/code] instead.
func add_char_before_int_string_up_to_max_number_length(num : int, maximum : int, prefixChar := "0", minimum := 0) -> String:
	if maximum < 0:
		return str(num);
	num = clamp(num, minimum, maximum);
	if num == maximum:
		return str(num);
	var numString = str(num);
	var max_numString = str(maximum);
	var lenDif = max_numString.length() - numString.length();
	while lenDif > 0:
		numString = prefixChar + numString;
		lenDif -= 1;
	return numString;

## Adds the [param mid_char] (default ":") between each string provided in the [Array] [param strings].[br]
## IF a char is empty ("") then it does not add the character.
func add_char_between_strings(strings : Array[String], mid_char := ":") -> String:
	var s = ""
	var count = 0
	for char in strings:
		s += char;
		count += 1
		if count < strings.size() and !char.is_empty():
			s += mid_char;
	return s;

## Spawns a text [Flyaway] at the given location with the given text and color.
func flyaway(textToDisplay, globalPosition : Vector3, color, color_outline := textColors["outline"]):
	var brd = GameState.get_game_board();
	if is_instance_valid(brd):
		color = get_color(color);
		color_outline = get_color(color_outline);
		var newFly = Flyaway.new();
		newFly.text = str(textToDisplay);
		newFly.modulate = color;
		newFly.outline_modulate = color_outline;
		brd.add_child(newFly);
		newFly.global_position = globalPosition;
		newFly.initPosY = globalPosition.y;
		newFly.show();


const alphanumericCharacters = [
	"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", "Z", "X", "C", "V", "B", "N", "M", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"
]
func last_char_is_alphanumeric(base : String):
	if base.length() == 0: return false;
	var last_char = base[base.length() - 1];
	return last_char in alphanumericCharacters or last_char.capitalize() in alphanumericCharacters;
func first_char_is_alphanumeric(base : String):
	if base.length() == 0: return false;
	var first_char = base[0];
	return first_char in alphanumericCharacters or first_char.capitalize() in alphanumericCharacters;

#### STRING CONSTRUCTOR

func parse_text_constructor_array(input : Array[RichTextConstructor]):
	var count = 0;
	var string;
	for constructor in input:
		count += 1;
		string = parse_text_constructor(constructor, count == 1, count == input.size());
	if string is String:
		#print_rich("FINAL STRING: "+string)
		return string;
	else:
		#print_rich("FINAL STRING DID NOT GO THROUGH")
		return "[color=red]ERROR!"

func parse_text_constructor(constructor : RichTextConstructor, start : bool, end : bool):
	#print("STRING IS STARTING: "+str(start))
	var base = get_stored_rich_string();
	## Newline. Adds a newline character before the appending string, if it is not the first line.
	if base.length() > 0:
		if constructor.newline: add_to_rich_string(false,"\n", null);
	##Starting space. Only runs if the last character of the constructed string, and the first character of the upcoming string, are both alphanumerical.
	if first_char_is_alphanumeric(constructor.string) and last_char_is_alphanumeric(base) and constructor.startingSpace:
		add_to_rich_string(false," ", null);
	add_to_rich_string(start, constructor.string, constructor.color);
	var new = get_stored_rich_string();
	##End space. Only if the last character is not already a space.
	if base.length() > 0:
		var last_char = base[base.length() - 1];
		if last_char != " ":
			if constructor.endingSpace: add_to_rich_string(false," ", null);
	## Return the result at the end of the array.
	if end: return get_stored_rich_string();

var storedString := "";

func get_stored_rich_string() -> String:
	return storedString;

func add_to_rich_string(start := false, append : String = "", _colorGet = get_color("white")):
	if start: 
		clear_rich_string_construction();
	var baseString = get_stored_rich_string();
	var color = get_color(_colorGet);
	var newString = "";
	if _colorGet != null:
		newString = "[color=" + color.to_html() + "]"
	newString += append;
	var endString = baseString + newString
	#print_rich("CONTRUCTED STRING THUS FAR: "+endString)
	storedString = endString;
	return endString;

func clear_rich_string_construction():
	storedString = "";

func get_final_rich_string():
	var ret = get_stored_rich_string();
	clear_rich_string_construction();
	#print_rich("FINAL STRING:" + ret)
	return ret;
