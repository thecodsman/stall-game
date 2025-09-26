class_name CharacterSelectIcon extends Panel

@export var sprite : Sprite2D
@export var icon : Texture2D :
	set(new_icon):
		icon = new_icon
		sprite.texture = new_icon
		sprite.position = size/2
@export var icon_offset : Vector2 :
	set(_offset):
		icon_offset = _offset
		sprite.offset = icon_offset
@export var locked : bool :
	set(is_locked):
		locked = is_locked
		if locked: sprite.modulate = Color.BLACK
		else: sprite.modulate = Color.WHITE
@export var portrait : Texture2D
var focusing : PackedInt32Array
var selected : PackedInt32Array
var border_color : Color = Globals.GRAY :
	set(color):
		if border_color == color: return
		var style_box : StyleBoxFlat = get_theme_stylebox("panel")
		border_color = color
		style_box.border_color = color
		add_theme_stylebox_override("panel", style_box)


func _draw() -> void:
	for i : int in range(focusing.size()):
		var text : String = str("P%s" % (focusing[i] + 1))
		var player : int = focusing[i]
		var offset : Vector2
		match player:
			0: offset = Vector2(-2,0)
			1: offset = Vector2(8,0)
			2: offset = Vector2(-2,18)
			3: offset = Vector2(8,18)
		for j : int in range(text.length()):
			var l : String = text[j]
			draw_char(preload("uid://dq3ivvjy1lslp"), Vector2(j*5,0) + offset, l, 8, Globals.current_player_colors[player])
	for i : int in range(selected.size()):
		var text : String = str("P%s" % (selected[i] + 1))
		var player : int = selected[i]
		var offset : Vector2
		match player:
			0: offset = Vector2(-2,0)
			1: offset = Vector2(8,0)
			2: offset = Vector2(-2,18)
			3: offset = Vector2(8,18)
		for j : int in range(text.length()):
			var l : String = text[j]
			draw_char(preload("uid://dq3ivvjy1lslp"), Vector2(j*5,0) + offset, l, 8, Color.WHITE)


func _process(_delta: float) -> void:
	if focusing.size() == 0: border_color = Globals.GRAY
	else: border_color = Globals.current_player_colors[focusing[-1]]
	queue_redraw()
