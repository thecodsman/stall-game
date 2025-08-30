extends Control

signal on_transition

@export var point_displays : Array[HBoxContainer]
@export var scores : Control
@export var bal_meter : Control
@export var bal_percent : Label
@export var game_text : Label
@export var pause_menu : Control
@export var onscreen_keyboard : Control
@onready var in_game : Control = $"CanvasLayer/in-game"
@onready var anim : AnimationPlayer = $CanvasLayer/AnimationPlayer


func _ready() -> void:
	update_scores(Globals.scores)


func update_scores(_scores : Array[int]) -> void:
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

