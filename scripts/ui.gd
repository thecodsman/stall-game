extends Control

signal on_transition

@export var point_displays : Array[HBoxContainer]
@onready var scores = $scores
@onready var anim = $AnimationPlayer


func _ready():
	Globals.scores_changed.connect(_on_scores_changed)
	_on_scores_changed(Globals.scores)


func _on_scores_changed(scores : Array[int]):
	for i in range(scores.size()):
		var score : int = scores[i]
		for j in range(point_displays[i].get_child_count()):
			var point : TextureRect = point_displays[i].get_child(j)
			if j < score: point.self_modulate = Globals.player_colors[i]
			else: point.self_modulate = Color.BLACK


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
