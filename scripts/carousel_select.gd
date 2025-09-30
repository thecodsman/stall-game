extends Control

@onready var carousel      : Control       = $Carousel
@onready var stage_title   : RichTextLabel = $stage_title
@export_file("*.tscn") var stages : Array[String]
const ANIM_DURATION     : float   = 0.4
const SCALE_FRONT       : Vector2 = Vector2(2.0, 2.0)
const SCALE_SIDE        : Vector2 = Vector2(1.0, 1.0)
const POSITION_OFFSET_X : float   = 24
const POSITION_OFFSET_Y : float   = -6
var current_index : int  = 0 :
	set(index):
		current_index = index
		update_carousel()
var child_count   : int
var can_scroll    : bool = true
var can_select    : bool = false


func _ready() -> void:
	spawn_stage_icons()
	child_count = carousel.get_child_count()
	update_carousel()


func _unhandled_input(event: InputEvent) -> void:
	var controller : int
	if is_multiplayer_authority() == false: return
	if Globals.is_online:
		controller = 0
	else:
		controller = Globals.registered_controllers[0]
	if Input.get_joy_axis(controller, JOY_AXIS_LEFT_X) > 0.95 && can_scroll:
		scroll_right()
		can_scroll = false
	elif Input.get_joy_axis(controller, JOY_AXIS_LEFT_X) < -0.95 && can_scroll:
		scroll_left()
		can_scroll = false
	elif Input.get_joy_axis(controller, JOY_AXIS_LEFT_X) > -0.95 && Input.get_joy_axis(controller, JOY_AXIS_LEFT_X) < 0.95:
		can_scroll = true
	if Input.is_joy_button_pressed(controller, JOY_BUTTON_A) && can_select:
		go_to_stage()
	elif not Input.is_joy_button_pressed(controller, JOY_BUTTON_A) :
		can_select = true
	if event is InputEventKey && event.is_pressed():
		if   event.keycode == KEY_LEFT  and not event.is_echo():
			scroll_left()
		elif event.keycode == KEY_RIGHT and not event.is_echo():
			scroll_right()
		if   event.keycode == KEY_SPACE and not event.is_echo():
			go_to_stage()


func spawn_stage_icons() -> void:
	for i : int in range(stages.size()):
		var stage      : Stage     = load(stages[i]).instantiate()
		var icon       : Texture2D = stage.thumb_nail
		var stage_name : String    = stage.stage_name
		var sprite     : Sprite2D  = Sprite2D.new()
		sprite.texture = icon
		sprite.centered = true
		sprite.name = stage_name
		carousel.add_child(sprite)


func go_to_stage() -> void:
	if Globals.is_online:
		var stage : String = stages[current_index]
		if is_multiplayer_authority() == false: return
		Lobby.load_game.rpc(stage)
	else:
		var stage : String = stages[current_index]
		UI.transition_to_scene(stage)


func scroll_right() -> void:
	current_index = (current_index + 1) % child_count


func scroll_left() -> void:
	current_index = (current_index - 1 + child_count) % child_count


@rpc("call_local", "reliable")
func update_carousel() -> void:
	for i : int in range(child_count):
		var child  : Sprite2D = carousel.get_child(i)
		var offset : int      = i - current_index
		if   offset > child_count  / 2.0: offset -= child_count
		elif offset < -child_count / 2.0: offset += child_count
		var target_scale : Vector2 = SCALE_FRONT    if offset == 0 else SCALE_SIDE
		var target_color : Color   = Color(1,1,1,1) if offset == 0 else Color(0.5,0.5,0.5,1)
		var target_pos   : Vector2 = Vector2(
			get_viewport_rect().size.x  / 2 + offset * POSITION_OFFSET_X,
			(get_viewport_rect().size.y / 2 + 16)    + abs(offset) * POSITION_OFFSET_Y
			)
		var tween : Tween = create_tween()
		tween.set_parallel()
		tween.tween_property(child, "position", target_pos,   ANIM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(child, "scale",    target_scale, ANIM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(child, "modulate", target_color, ANIM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var selected_stage : Sprite2D = carousel.get_child(current_index)
	stage_title.text = selected_stage.name


func _on_back_pressed() -> void:
	UI.transition_to_scene("res://worlds/main_menu.tscn")
