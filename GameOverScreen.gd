extends CanvasLayer

# warning-ignore-all:return_value_discarded

var stats = PlayerStats

func _ready():
	get_tree().paused = true

func _on_RestartButton_pressed() -> void:
	get_tree().paused = false
	PlayerStats._ready()
	get_tree().change_scene("res://Main.tscn")

func _on_QuitButton_pressed():
	get_tree().quit()

func _on_MainMenuButton_pressed():
	get_tree().paused = false
	get_tree().change_scene("res://MainMenuScreen.tscn")
