extends Control


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://worlds/stage_select.tscn")
	var stream_playback : AudioStreamPlaybackInteractive = MusicPlayer.get_stream_playback()
	stream_playback.switch_to_clip_by_name(&"Stall Battle")
