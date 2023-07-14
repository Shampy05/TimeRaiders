extends CanvasLayer

# warning-ignore-all:return_value_discarded

func _on_PlayButton_pressed():
	get_tree().change_scene("res://Main.tscn")

func _on_QuitButton_pressed():
	get_tree().quit()
