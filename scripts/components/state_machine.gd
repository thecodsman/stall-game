class_name StateMachineComponent extends Node


@export var initial_state : StateComponent
@onready var state : StateComponent = (func get_initial_state() -> PlayerState:
	return initial_state if initial_state != null else get_child(0)
).call()


func _ready() -> void:
	for state_node : StateComponent in find_children("*", "StateComponent"):
		state_node.finished.connect(_go_to_next_state)
		state_node.parent = owner
		state_node.state_machine = self
	await owner.ready
	state.enter("")


func _process(delta : float) -> void:
	state.update(delta)


func _physics_process(delta : float) -> void:
	state.physics_update(delta)


func _go_to_next_state(target_state : String, data : Dictionary = {}) -> void:
	if not has_node(target_state):
		printerr("%s failed to go to %s state because it does not exist" % [state.name, target_state])
		return
	var previous_state : String = state.name	
	state.exit()
	state = get_node(target_state)
	state.enter(previous_state, data)

