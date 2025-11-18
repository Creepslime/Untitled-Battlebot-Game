extends PFXBulletTracer

var diedAlready := false;

func stop_trailing():
	if not diedAlready:
		#$Rubble.one_shot = true;
		#$Rubble.emitting = true;
		diedAlready = true;
	super();
