extends Control


@onready var text_boxes : VBoxContainer = $IP


func _ready():
	for i in range(text_boxes.get_child_count()):
		var text_box : LineEdit = text_boxes.get_child(i)
		text_box.focus_entered.connect(func():
			_on_text_box_focus(text_box))
		text_box.focus_exited.connect(func():
			_on_text_box_unfocus(text_box))


func _on_text_box_focus(text_box : LineEdit):
	UI.onscreen_keyboard.text_box = text_box
	UI.onscreen_keyboard.prev_focus = get_viewport().gui_get_focus_owner()


func _on_text_box_unfocus(text_box : LineEdit):
	if UI.onscreen_keyboard.visible: return
	UI.onscreen_keyboard.text_box = null
