extends Node

func get_action_string(actionName:String, separatorCharacter := "\n") -> String:
	var s = ""
	var allEventsWithName = InputMap.action_get_events(actionName)
	while allEventsWithName.size() > 0:
		var inputEvent = allEventsWithName.pop_front();
		s += inputEvent.as_text();
		if allEventsWithName.size() >= 1:
			s += separatorCharacter;
	return s;
