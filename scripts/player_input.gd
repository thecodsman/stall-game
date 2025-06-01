class_name PlayerInput extends MultiplayerSynchronizer

var device_index : int = 0
var button_state : Dictionary[String,int] = {
	"held":0,
	"frame_pressed":-1,
	"frame_released":-1,
	}
var buttons : Dictionary[JoyButton,Dictionary] ## button states
var direction : Vector2
var dead_zone : float = 0.09


func _ready():
	set_physics_process(get_multiplayer_authority() == multiplayer.get_unique_id())


func _physics_process(_delta: float) -> void:
	direction = Vector2(
		Input.get_joy_axis(device_index, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(device_index, JOY_AXIS_LEFT_Y)
		)


@rpc("authority", "call_local", "unreliable_ordered")
func set_action_state(button : int):
	if not buttons.get(button):
		buttons[button] = button_state.duplicate()
	var prev_button_state = buttons[button]
	var currently_held = Input.is_joy_button_pressed(device_index, button)
	if currently_held && not prev_button_state.held:
		buttons[button].held = 1
		buttons[button].frame_pressed = Engine.get_process_frames()
	elif not currently_held && prev_button_state.held:
		buttons[button].held = 0
		buttons[button].frame_released = Engine.get_process_frames()


func is_button_just_pressed(button : JoyButton) -> bool:
	set_action_state(button)
	return (buttons[button].held && buttons[button].frame_pressed == Engine.get_process_frames())


func get_joy_axis(axis : JoyAxis) -> float:
	return Input.get_joy_axis(device_index, axis)


func is_joy_button_pressed(button : JoyButton) -> bool:
	set_action_state(button)
	return buttons[button].held == 1
