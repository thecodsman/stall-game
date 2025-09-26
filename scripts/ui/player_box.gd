class_name PlayerBox extends Panel

@onready var sprite : Sprite2D = $sprite
@onready var label : Label = $Label

var color : Color = Globals.GRAY : 
	set(new_color):
		color = new_color
		sprite.modulate = new_color
		if not character_selected: return
		var style_box : StyleBoxFlat = get_theme_stylebox("panel")
		style_box.border_color = new_color
		add_theme_stylebox_override("panel", style_box)
var player_joined : bool = false :
	set(vis):
		sprite.visible = vis
		player_joined = vis
		label.visible = !vis
var character_selected : bool = false :
	set(_bool):
		character_selected = _bool
		if character_selected: color = color # sets the border color
		else:
			var style_box : StyleBoxFlat = get_theme_stylebox("panel")
			style_box.border_color = Globals.GRAY
			add_theme_stylebox_override("panel", style_box)
var portrait : Texture2D :
	set(tex):
		if tex == portrait: return
		sprite.texture = tex
		portrait = tex
	get():
		if not sprite: return null
		return sprite.texture


func _physics_process(_delta: float) -> void:
	if Engine.get_physics_frames() % 50: return
	label.text = label.text + label.text[0]
	label.text = label.text.erase(0)
