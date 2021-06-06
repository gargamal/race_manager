extends Node2D


func _on_exit_pitlane_body_exited(body):
	if body.is_in_group("car"):
		body.exit_pitlane()


func _on_in_pitlane_body_entered(body):
	if body.is_in_group("car") and body.has_pit_stop:
		body.limit_pitlane()
