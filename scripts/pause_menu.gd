extends Control


func _on_resume_pressed() -> void:
	hide()


func _on_mainmenu_pressed() -> void:
	UI.transition_to_scene("res://worlds/main_menu.tscn")
	UI.on_transition.connect(func():
		hide()
		)


func _on_quit_pressed() -> void:
	get_tree().quit()
