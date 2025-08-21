class_name ScoreLine extends Node2D

@export var frame_delay : int
@onready var label : Label = $Label
@onready var active_line : Line2D = $active
@onready var inactive_line : Line2D = $inactive
var is_active : bool = false


func _physics_process(_delta: float) -> void:
	if Engine.get_physics_frames() % frame_delay || not is_active: return
	label.global_position.x -= 1
	label.global_position.x = int(label.global_position.x) % 38


func activate() -> void:
	modulate = Globals.player_colors[1]
	active_line.show()
	inactive_line.hide()
	label.show()
	is_active = true
	var tween : Tween = create_tween()
	tween.tween_property(label, "position:y", 3, 0.5)


func deactivate() -> void:
	modulate = Color.WHITE
	active_line.hide()
	inactive_line.show()
	is_active = false
	var tween : Tween = create_tween()
	tween.tween_property(label, "position:y", to_local(Vector2(0,96)).y, 0.5)
