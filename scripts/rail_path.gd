extends Path2D

@onready var line_2d: Line2D = $rail_line


func _ready() -> void:
	var points = curve.get_baked_points()
	line_2d.points = points
