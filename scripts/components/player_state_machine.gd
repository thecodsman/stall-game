class_name PlayerStateMachine extends StateMachineComponent

var player : Player
var time_scale : float = 1.0 :
	set(new_time_scale):
		player.time_scale = new_time_scale
	get():
		return player.time_scale


func _ready() -> void:
	player = owner
	for state_node : PlayerState in find_children("*", "PlayerState"):
		state_node.finished.connect(_go_to_next_state)
		state_node.player = owner
		state_node.state_machine = self
	await owner.ready
	state.enter("")


func _process(delta : float) -> void:
	delta *= time_scale
	state.update(delta)


func _physics_process(delta : float) -> void:
	delta *= time_scale
	state.physics_update(delta)
