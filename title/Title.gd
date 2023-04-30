extends Control

# called when the start button is clicked
func _on_StartButton_button_up():
	get_parent().get_tree().change_scene_to_file("res://game/Game.tscn")
