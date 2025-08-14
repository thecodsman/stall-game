extends Area2D

signal water_entered
signal water_exited

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _on_area_entered(_area : Area2D) -> void:
	water_entered.emit()


func _on_area_exited(_area : Area2D) -> void:
	water_exited.emit()
