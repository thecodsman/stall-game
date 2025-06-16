extends Control

@export var point_displays : Array[HBoxContainer]


func _ready():
	Globals.scores_changed.connect(_on_scores_changed)


func _on_scores_changed(scores : Array[int]):
	for i in range(scores.size()):
		var score : int = scores[i]
		for j in range(point_displays[i].get_child_count()):
			var point : TextureRect = point_displays[i].get_child(j)
			if j < score: point.self_modulate = Globals.player_colors[i]
			else: point.self_modulate = Color.WHITE
