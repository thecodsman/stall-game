class_name PlayerInput extends Node

@export var ABuffer : int
@export var XBuffer : int
@export var RShoulderBuffer : int
@export var MaxTimeToSmash : float
@export var DeadZone : float = 0.09 ## whats considered zeroed
@export var NeutralZone : float = 0.15 ## whats considered "Neutral"
@export var KeyboardToController : Dictionary[Key,JoyButton]
var is_keyboard : bool = false
var neutral : bool = false
var smashing : bool = false
var device_index : int = 0
var direction : Vector2
var prev_direction : Vector2
var smash_timer : Timer = Timer.new()
var button_state : Dictionary[String,int] = {
	"held":0,
	"frame_pressed":-1,
	"frame_released":-1,
	"buffer":0,
	}
@onready var buttons : Dictionary[JoyButton,Dictionary] = {
	JOY_BUTTON_A:{
		"held":0,
		"frame_pressed":-1,
		"frame_released":-1,
		"buffer":ABuffer
			},
	JOY_BUTTON_X:{
		"held":0,
		"frame_pressed":-1,
		"frame_released":-1,
		"buffer":XBuffer
			},
	JOY_BUTTON_RIGHT_SHOULDER:{
		"held":0,
		"frame_pressed":-1,
		"frame_released":-1,
		"buffer":RShoulderBuffer
		}
		} ## button states


func _ready():
	set_physics_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	smash_timer.wait_time = MaxTimeToSmash
	smash_timer.one_shot = true
	add_child(smash_timer)
	smash_timer.timeout.connect(_on_smash_timer_timeout)


func _physics_process(_delta: float) -> void:
	direction = Vector2(
		Input.get_joy_axis(device_index, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(device_index, JOY_AXIS_LEFT_Y)
		)
	if is_keyboard:
		direction = Input.get_vector("left", "right", "up", "down")
	if direction.length() < DeadZone:
		direction = Vector2.ZERO
		neutral = true
	elif direction.length() >= NeutralZone && prev_direction.length() < NeutralZone:
		smashing = true
		neutral = false
		smash_timer.start()
	else:
		neutral = true
	prev_direction = direction


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton && buttons.has(event.button_index):
		is_keyboard = false
		set_action_state(event.button_index)
	elif event is InputEventKey && device_index == 0:
		is_keyboard = true
		if not KeyboardToController.has(event.keycode): return
		set_action_state(KeyboardToController.get(event.keycode))


@rpc("authority", "call_local", "unreliable_ordered")
func set_action_state(button : int):
	if not buttons.get(button):
		buttons[button] = button_state.duplicate()
	var prev_button_state = buttons[button]
	var currently_held = false
	if not is_keyboard:
		currently_held = Input.is_joy_button_pressed(device_index, button)
	else:
		currently_held = Input.is_physical_key_pressed(KeyboardToController.find_key(button))
	if currently_held && not prev_button_state.held:
		buttons[button].held = 1
		buttons[button].frame_pressed = Engine.get_physics_frames()
	elif not currently_held && prev_button_state.held:
		buttons[button].held = 0
		buttons[button].frame_released = Engine.get_physics_frames()


func is_button_just_pressed(button : JoyButton, buffer_override : int = -1, test_only : bool = false) -> bool: ## set `buffer_override` to -1 to use default buffer for `button`, set test_only to true to not deactivate buffer if successful
	var buffer : int
	set_action_state(button)
	if buffer_override > -1: buffer = buffer_override
	else: buffer = buttons[button].buffer
	if buffer > 0:
		var button_pressed = (buttons[button].frame_pressed + buffer >= Engine.get_physics_frames())
		if button_pressed && not test_only: buttons[button].frame_pressed -= buffer ## stop the same input being buffered for multiple actions
		return button_pressed
	return (buttons[button].held && buttons[button].frame_pressed == Engine.get_physics_frames())


func just_smashed() -> bool:
	if smashing && direction.length() >= 1.0:
		smashing = false
		smash_timer.stop()
		return true
	return false


func get_joy_axis(axis : JoyAxis) -> float:
	return Input.get_joy_axis(device_index, axis)


func is_joy_button_pressed(button : JoyButton) -> bool:
	set_action_state(button)
	return buttons[button].held == 1


func _on_smash_timer_timeout():
	smashing = false
