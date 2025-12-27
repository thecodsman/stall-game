class_name StateComponent extends Node

signal finished(next_state : String, data : Dictionary)
var state_machine : StateMachineComponent


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	pass


func update(_delta : float) -> void:
	pass


func physics_update(_delta : float) -> void:
	pass


func exit() -> void:
	pass
