extends Node2D

#When the game is finished, it shows the buttons and the text
func _ended_game(text):
	$".".visible = true
	$Text.text = text

#If you press, the game restarts
func _on_Button_pressed():
	get_tree().reload_current_scene()
