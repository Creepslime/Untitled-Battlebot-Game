extends Node
## Controls the amount of scrap the player currently has.

var scrap := 0;
const MAX_SCRAP := 999999;

enum priceTypes {
	PIECE,
	PART,
	REROLL,
	HEALING,
	GENERAL,
}
var discountTypeEnumDict = {
	priceTypes.PIECE : activeDiscounts_PIECE,
	priceTypes.PART : activeDiscounts_PART,
	priceTypes.REROLL : activeDiscounts_REROLL,
	priceTypes.HEALING : activeDiscounts_HEALING,
	priceTypes.GENERAL : activeDiscounts_GENERAL,
}
var discountTypeCalculatedDiscounts = {
	priceTypes.PIECE : 1.0,
	priceTypes.PART : 1.0,
	priceTypes.REROLL : 1.0,
	priceTypes.HEALING : 1.0,
	priceTypes.GENERAL : 1.0,
}
var activeDiscounts_PIECE : Dictionary[String, float] = {}
var activeDiscounts_PART : Dictionary[String, float] = {}
var activeDiscounts_REROLL : Dictionary[String, float] = {}
var activeDiscounts_HEALING : Dictionary[String, float] = {}
var activeDiscounts_GENERAL : Dictionary[String, float] = {}

func add_scrap(amt : int, source:String):
	scrap = max(0, scrap + amt, 999999);
	Hooks.OnGainScrap(source, amt);

## Removes 
func remove_scrap(amt : int, source:String):
	scrap = max(0, scrap - amt, 999999);
	Hooks.OnGainScrap(source, -amt);

## Sets the scrap amount to a specific number.
func set_scrap(amt := 0):
	scrap = amt;

func get_scrap():
	return scrap;

## Attempts to remove the given amount and returns the result. If the thing was affordable, returns true. If not, returns false.
func try_spend_scrap(amt : int, source:String) -> bool:
	if is_affordable(amt):
		remove_scrap(amt, source);
		return true;
	return false;

## Returns true if you're not too broke to afford whatever thing this is being used to check for.
func is_affordable(amt : int):
	return ceili(amt) <= scrap;

func clear_discounts():
	for discountDict in discountTypeEnumDict.values():
		discountDict.clear();

## Adds a discount using full percents. I.E, inputting 35 as [param percent_off] results in a discount multiplier of 0.65.
func add_discount_percent_off(priceType : priceTypes,source : String, percent_off : float, priority := 0):
	var mult = (100. - percent_off) / 100;
	add_discount_multiplier(priceType, source, mult, priority);

func add_discount_multiplier(priceType : priceTypes, source : String, multiplier : float, priority := 0):
	var priorityString = TextFunc.format_stat_num(priority, 0);
	var discountName = priorityString + source;
	discountTypeEnumDict[priceType][discountName] = multiplier;

func remove_discount(priceType : priceTypes, source : String, priority := 0):
	var priorityString = TextFunc.format_stat_num(priority, 0, "0");
	var discountName = priorityString + source;
	discountTypeEnumDict[priceType].erase(discountName);

func recalculate_discounts():
	for key in discountTypeEnumDict.keys():
		var dict = discountTypeEnumDict[key];
		var amtTotal = 1.0;
		var keys = dict.keys()
		keys.sort();
		for discountName in keys:
			var amt = dict[discountName];
			amtTotal -= (1. - amt) ## This should in theory result in additive discounts. Discounts are formatted as a multiplier, so...
		discountTypeCalculatedDiscounts[key] = amtTotal;

func get_discount_for_type(priceType : priceTypes):
	var discountGeneral = discountTypeCalculatedDiscounts[priceTypes.GENERAL];
	if priceType == priceTypes.GENERAL: return discountGeneral;
	var discountThis = discountTypeCalculatedDiscounts[priceType];
	return discountGeneral * discountThis;

func get_discounted_price(price : int, priceType : priceTypes):
	return ceili(price * get_discount_for_type(priceType))
