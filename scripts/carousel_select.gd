
extends Control

@onready var carousel = $Carousel
@onready var child_count = carousel.get_child_count()
@onready var stage_title = $stage_title
@onready var current_index = 0



const ANIM_DURATION = 0.4
const SCALE_FRONT = Vector2(1.0, 1.0)
const SCALE_SIDE = Vector2(0.8, 0.8)
const POSITION_OFFSET_X = 14
const POSITION_OFFSET_Y = -3

const basic_stage = "res://worlds/basic_stage.tscn"
const platform_stage = "res://worlds/platform_stage.tscn"


func _ready():
	update_carousel()



func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("right") and not event.is_echo():
			scroll_left()
		elif event.is_action_pressed("left") and not event.is_echo():
			scroll_right()
		if event.is_action_pressed("jump") and not event.is_echo():
			go_to_stage()



func go_to_stage():
	match current_index:
		0:
			get_tree().change_scene_to_file(basic_stage)	
		1:
			get_tree().change_scene_to_file(platform_stage)



func scroll_right():
	current_index = (current_index + 1) % child_count
	update_carousel()

func scroll_left():
	current_index = (current_index - 1 + child_count) % child_count
	update_carousel()

func update_carousel():
	for i in range(child_count):
		var child = carousel.get_child(i)
		var offset = i - current_index

		if offset > child_count / 2:
			offset -= child_count
		elif offset < -child_count / 2:
			offset += child_count

		var target_pos = Vector2(
			get_viewport_rect().size.x / 2 + offset * POSITION_OFFSET_X,
			get_viewport_rect().size.y / 2 + abs(offset) * POSITION_OFFSET_Y
		)

		var target_scale = SCALE_FRONT if offset == 0 else SCALE_SIDE
		var target_color = Color(1,1,1,1) if offset == 0 else Color(0.5,0.5,0.5,1)

		var tween = create_tween()
		tween.set_parallel()
		tween.tween_property(child, "position", target_pos, ANIM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(child, "scale", target_scale, ANIM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(child, "modulate", target_color, ANIM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


	
	var selected_stage = carousel.get_child(current_index)
	stage_title.text = selected_stage.name
