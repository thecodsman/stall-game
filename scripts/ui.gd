extends Control

signal on_transition

@export var point_displays : Array[HBoxContainer]
@export var scores : Control
@export var bal_meter : Control
@export var bal_percent : Label
@export var game_text : Label
@export var pause_menu : Control
@export var onscreen_keyboard : Control
@export var post_match_report : Panel
@export var combo_counter : Label
@onready var in_game : Control = $"CanvasLayer/in-game"
@onready var anim : AnimationPlayer = $CanvasLayer/AnimationPlayer


func _ready() -> void:
	update_scores(Globals.scores)


func update_scores(_scores : Array[int]) -> void:
	if _scores == []: return
	var tween : Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for i : int in range(_scores.size()):
		var score : int = _scores[i]
		for j : int in range(point_displays[i].tallys.get_child_count()):
			var point : TextureRect = point_displays[i].tallys.get_child(j)
			var new_color : Color
			const anim_duration : float = 0.1
			if j < score: new_color = Globals.current_player_colors[i]
			else: new_color = Globals.GRAY
			if point.self_modulate == new_color: continue
			if new_color == Globals.GRAY:
				point.self_modulate = new_color
				continue
			tween.tween_property(point, "position:y", -4, anim_duration)
			tween.tween_callback(func() -> void: point.self_modulate = new_color).set_delay(0.1)
			tween.tween_callback(Globals.camera.screen_shake.bind(5,2,2))
			tween.tween_property(point, "position:y", 0, anim_duration).set_delay(0.1)


@rpc("authority", "call_remote", "reliable", 1)
func update_combo_counter(player : int, combo : int, color : Color) -> void:
	if player % 2 == 0: 
		combo_counter.position = (
				Vector2(
					96 - combo_counter.size.x,
					48 - (combo_counter.size.y / 2)
					)
				+ Vector2(
					randf_range(0,-4),
					randf_range(-4,4)
					)
			)
	else: 
		combo_counter.position = (
				Vector2(
					0,
					48 - (combo_counter.size.y/2)
					)
				+ Vector2(
					randf_range(0,8),
					randf_range(-4,4)
					)
			)
	combo_counter.pivot_offset = combo_counter.size/2
	combo_counter.show()
	combo_counter.text = "%sx\n\nCOMBO" % combo
	combo_counter.material.set_shader_parameter("outline_color", color)
	var tween : Tween = create_tween().set_parallel(true)
	tween.tween_property(combo_counter, "scale", Vector2(1,1), 0.2).from(Vector2(0.5,0.5))
	tween.tween_property(combo_counter, "rotation", randf_range(-PI/10,PI/10), 0.2).from(0)
	if multiplayer.get_remote_sender_id() != 0: return
	update_combo_counter.rpc(combo, color)


func _on_bal_percent_change(percent : float) -> void:
	bal_percent.text = str("%1.1f%%" % (percent * 100 - 100))


func transition_to_scene(scene : String) -> void:
	anim.play("transition_close")
	await anim.animation_finished
	get_tree().change_scene_to_file(scene)
	on_transition.emit()
	anim.play("transition_open")


func start_transition() -> void:
	anim.play("transition_close")
	await anim.animation_finished
	on_transition.emit()


func continue_transition() -> void:
	anim.play("transition_open")


func show_element(element : Control, final_y : float = 0, duration : float = 0.5) -> void:
	var tween : Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
	element.show()
	tween.tween_property(element, "position:y", final_y, duration).from(-element.size.y)


func hide_element(element : Control, duration : float = 0.5) -> void:
	var tween : Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
	tween.tween_property(element, "position:y", -element.size.y, duration)
	tween.tween_callback(element.hide)
