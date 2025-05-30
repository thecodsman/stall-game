extends Control


func _on_start_pressed() -> void:
	Globals.is_online = false
	get_tree().change_scene_to_file("res://worlds/stage_select.tscn")
	# var stream_playback : AudioStreamPlaybackInteractive = MusicPlayer.get_stream_playback()
	# stream_playback.switch_to_clip_by_name(&"Stall Battle")


func _on_online_pressed() -> void:
	Globals.is_online = true
	get_tree().change_scene_to_file("res://worlds/connect_menu.tscn")


func _ready():
	$VBoxContainer/local.grab_focus()


func _input(event):
	var current = get_viewport().gui_get_focus_owner()
	if not current: return
	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_LEFT_Y: #vertical left stick
			if event.axis_value == -1.0: #full motion up
				var prev = get_node(NodePath("VBoxContainer/local/" + str(current.focus_previous)))
				if not prev: return
				prev.grab_focus()
			elif event.axis_value == 1.0: # full motion down
				var next = get_node(NodePath("VBoxContainer/local/" + str(current.focus_next)))
				if not next: return
				next.grab_focus()
	elif event is InputEventJoypadButton:
		if event.button_index == JOY_BUTTON_A and event.pressed:
			if current is Button:
				current.pressed.emit()
