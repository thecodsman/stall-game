extends Control

@onready var carousel = $Carousel
@onready var stage_title = $stage_title
@onready var current_index = 0

@export_file("*.tscn") var stages : Array[String]

const ANIM_DURATION = 0.4
const SCALE_FRONT = Vector2(2.0, 2.0)
const SCALE_SIDE = Vector2(1.0, 1.0)
const POSITION_OFFSET_X = 24
const POSITION_OFFSET_Y = -6

const basic_stage = "res://worlds/basic_stage.tscn"
const platform_stage = "res://worlds/platform_stage.tscn"

var child_count : int
var can_scroll : bool = true
var can_select : bool = false


func _ready():
	spawn_stage_icons()
	child_count = carousel.get_child_count()
	update_carousel()


func _unhandled_input(event: InputEvent) -> void:
	if Input.get_joy_axis(0, JOY_AXIS_LEFT_X) > 0.95 && can_scroll:
		scroll_right()
		can_scroll = false
	elif Input.get_joy_axis(0, JOY_AXIS_LEFT_X) < -0.95 && can_scroll:
		scroll_right()
		can_scroll = false
	elif Input.get_joy_axis(0, JOY_AXIS_LEFT_X) > -0.95 && Input.get_joy_axis(0, JOY_AXIS_LEFT_X) < 0.95:
		can_scroll = true
	if Input.is_joy_button_pressed(0, JOY_BUTTON_A) && can_select:
		go_to_stage()
	elif not Input.is_joy_button_pressed(0, JOY_BUTTON_A) :
		can_select = true

	if event is InputEventKey:
			if event.is_action_pressed("right") and not event.is_echo():
				scroll_left()
			elif event.is_action_pressed("left") and not event.is_echo():
				scroll_right()
			if event.is_action_pressed("jump") and not event.is_echo():
				go_to_stage()


func spawn_stage_icons():
	for i in range(stages.size()):
		var stage : Stage = load(stages[i]).instantiate()
		var icon : Texture2D = stage.thumb_nail
		var stage_name : String = stage.stage_name
		var sprite : Sprite2D = Sprite2D.new()
		sprite.texture = icon
		sprite.centered = true
		sprite.name = stage_name
		carousel.add_child(sprite)


func go_to_stage():
	if Globals.is_online:
		var stage = stages[current_index]
		Lobby.load_game.rpc(stage)
	else:
		var stage = stages[current_index]
		UI.transition_to_scene(stage)


func scroll_right():
	current_index = (current_index + 1) % child_count
	update_carousel.rpc()


func scroll_left():
	current_index = (current_index - 1 + child_count) % child_count
	update_carousel.rpc()


@rpc("call_local", "reliable")
func update_carousel():
	for i in range(child_count):
		var child : Sprite2D = carousel.get_child(i)
		var offset = i - current_index
		if offset > child_count / 2.0: offset -= child_count
		elif offset < -child_count / 2.0: offset += child_count
		var target_scale = SCALE_FRONT if offset == 0 else SCALE_SIDE
		var target_color = Color(1,1,1,1) if offset == 0 else Color(0.5,0.5,0.5,1)
		var target_pos = Vector2(
			get_viewport_rect().size.x / 2 + offset * POSITION_OFFSET_X,
			(get_viewport_rect().size.y / 2 + 16) + abs(offset) * POSITION_OFFSET_Y
			)
		var tween = create_tween()
		tween.set_parallel()
		tween.tween_property(child, "position", target_pos, ANIM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(child, "scale", target_scale, ANIM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(child, "modulate", target_color, ANIM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var selected_stage = carousel.get_child(current_index)
	stage_title.text = selected_stage.name
