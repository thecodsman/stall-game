extends Panel

@onready var stats : VBoxContainer = $stats

func update_stats(dict : Dictionary[String, float]) -> void:
	for i : int in range(stats.get_child_count()):
		var stat : Label = stats.get_child(i)
		stat.text = stat.tooltip_text % dict[stat.name]
