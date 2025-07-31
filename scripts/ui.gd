extends Control

signal on_transition

@export var point_displays : Array[HBoxContainer]
@export var bal_percent : Label
@export var game_text : Label
@export var pause_menu : Control
@export var onscreen_keyboard : Control
@onready var scores = $"CanvasLayer/in-game"
@onready var anim = $CanvasLayer/AnimationPlayer


func _ready():
	Globals.scores_changed.connect(_on_scores_changed)
	_on_scores_changed(Globals.scores)


func _on_scores_changed(_scores : Array[int]):
	for i in range(_scores.size()):
		var score : int = _scores[i]
		for j in range(point_displays[i].get_child_count()):
			var point : TextureRect = point_displays[i].get_child(j)
			if j < score: point.self_modulate = Globals.player_colors[i]
			else: point.self_modulate = Color.BLACK


func _on_bal_percent_change(percent : float):
	bal_percent.text = str("%1.1f%%" % (percent * 100 - 100))


func transition_to_scene(scene : String):
	anim.play("transition_close")
	await anim.animation_finished
	get_tree().change_scene_to_file(scene)
	anim.play("transition_open")


func start_transition():
	anim.play("transition_close")
	await anim.animation_finished
	on_transition.emit()


func continue_transition():
	anim.play("transition_open")
