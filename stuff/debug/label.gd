extends Label

@export var state_machine : StateMachineComponent


func _process(delta: float) -> void:
	if state_machine.state: text = state_machine.state.name
