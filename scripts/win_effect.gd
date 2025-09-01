extends Node2D

const max_radius : float = 1000
const duration : float = 10
const filled : bool = false
const min_width : float = 2
const max_width : float = 6
const antialiased : bool = false
const radius_mult : float = 0.66
var radius : float = 0

func _ready() -> void:
	var tween : Tween = create_tween().set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, ^"radius", max_radius, duration)
	tween.tween_callback(queue_free)


func _physics_process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(1,1), radius, Color.BLACK, filled, min_width, antialiased)
	draw_circle(Vector2(1,1), radius*radius_mult, Color.BLACK, filled, max_width, antialiased)
	draw_circle(Vector2.ZERO, radius, Color.WHITE, filled, min_width, antialiased)
	draw_circle(Vector2.ZERO, radius*radius_mult, Color.WHITE, filled, max_width, antialiased)
