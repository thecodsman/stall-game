class_name TrailFX extends Line2D

@export var trail_lifetime : float
@export var target : Node2D
var tweens : Array[Tween] = []
var lifetime_reached : bool = true
var stopping : bool = true

@rpc("authority", "call_remote", "unreliable_ordered", 2)
func add_new_color(color : Color) -> void:
	gradient.add_point(1.0, color)
	var index : int = gradient.offsets.size() - 1
	var set_offset : Callable = func(offset : float) -> void: gradient.set_offset(index, offset)
	var color_tween : Tween = create_tween()
	color_tween.tween_method(set_offset, 1.0, 0.0, trail_lifetime)
	tweens.append(color_tween)
	color_tween.finished.connect(_on_tween_finished.bind(color_tween))
	if is_multiplayer_authority() == false: return
	add_new_color.rpc(color)


@rpc("authority", "call_local", "unreliable_ordered", 2)
func stop() -> void:
	stopping = true


@rpc("authority", "call_local", "unreliable_ordered", 2)
func start() -> void:
	for i : int in range(points.size()):
		remove_point(0)
	stopping = false
	lifetime_reached = false
	await get_tree().create_timer(trail_lifetime).timeout
	lifetime_reached = true


func _physics_process(_delta: float) -> void:
	if target: add_point(target.global_position)
	if not lifetime_reached: return
	remove_point(0)
	if not stopping: return
	if points.size() < 1: return
	remove_point(0)


func _on_tween_finished(tween : Tween) -> void:
	tweens.erase(tween)
	if tweens.size() > 0: return
	for i : int in range(gradient.offsets.size()-1):
		gradient.remove_point(0)
