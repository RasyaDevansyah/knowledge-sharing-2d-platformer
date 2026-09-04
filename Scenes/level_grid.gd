extends GridContainer


func select_level(levelPath : String):
	get_tree().change_scene_to_file(levelPath)
