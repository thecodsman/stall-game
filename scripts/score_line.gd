class_name ScoreLine extends Node2D

@export var frame_delay : int
@export var active_text : String
@export var text_width : int
@onready var label : Label = $Label
@onready var checkerboard : Line2D = $checkerboard
@onready var active_line : Line2D = $active
@onready var inactive_line : Line2D = $inactive
var is_active : bool = false
var height : float


func _physics_process(_delta: float) -> void:
	if Engine.get_physics_frames() % frame_delay || not is_active: return
	label.global_position.x -= 1
	label.global_position.x = int(label.global_position.x) % text_width
	if Engine.get_physics_frames() % (frame_delay * 3): return
	active_line.global_position.x += 1
	active_line.global_position.x = int(active_line.global_position.x) % int(active_line.width*2)


func activate() -> void:
	active_line.modulate = Globals.current_player_colors[Globals.camera.ball.owner_index - 1]
	active_line.show()
	inactive_line.hide()
	label.show()
	is_active = true
	var tween : Tween = create_tween()
	tween.tween_property(label, "position:y", (height/2) - (label.size.y/2), 0.5)


func deactivate() -> void:
	modulate = Color.WHITE
	active_line.hide()
	inactive_line.show()
	is_active = false
	var tween : Tween = create_tween()
	tween.tween_property(label, "position:y", to_local(Vector2(0,96)).y, 0.5)
