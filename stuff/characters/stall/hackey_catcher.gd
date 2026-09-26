extends Area2D

@onready var collider : CollisionShape2D = $CollisionShape2D

func _on_body_entered(body: Node2D) -> void:
	if not body is HackeySack: return
	var hackey : HackeySack = body
	hackey.destroy_timer.stop()
	hackey.destroy_timer.timeout.emit()
	collider.set_deferred("disabled", true)
