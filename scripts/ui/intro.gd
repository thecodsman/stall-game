extends Control


func goto_main_menu() -> void:
	const main_menu_uid : NodePath = ^"uid://dqrhx4hoehkkl"
	UI.transition_to_scene(main_menu_uid)
