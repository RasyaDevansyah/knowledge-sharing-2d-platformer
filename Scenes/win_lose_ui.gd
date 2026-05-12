extends Control


@onready var win_ui: Control = $WinUI
@onready var lose_ui: Control = $LoseUI


func _ready() -> void:
	GlobalPoints.state_changed.connect(on_state_changed)
	
func on_state_changed():
	match GlobalPoints.currentState:
		
		GlobalPoints.levelState.Lose:
			lose_ui.show()
			pass
		GlobalPoints.levelState.Win:
			win_ui.show()
			pass
		_:
			win_ui.hide()
			lose_ui.hide()
	

func _on_retry_button_pressed() -> void:
	get_tree().reload_current_scene()
	GlobalPoints.reset()

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	GlobalPoints.reset()
