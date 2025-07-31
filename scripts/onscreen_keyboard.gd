extends Control

@onready var letters = $tabs/qwerty
@onready var numbers = $"tabs/123"
@onready var anim = $anim
var text_box : LineEdit
var prev_focus : Control


func _ready() -> void:
	var l_vbox : VBoxContainer = letters.get_child(0)
	for i in range(l_vbox.get_child_count()):
		if i == 0: continue
		var hbox : HBoxContainer = l_vbox.get_child(i)
		for j in range(hbox.get_child_count()):
			var key : Button = hbox.get_child(j)
			key.pressed.connect(func(): ## dont connect it directly to the signal so i can pass in the key
				_on_virtual_key_pressed(key))
	var n_vbox : VBoxContainer = numbers.get_child(0)
	for i in range(n_vbox.get_child_count()):
		if i == 0: continue
		var hbox : HBoxContainer = n_vbox.get_child(i)
		for j in range(hbox.get_child_count()):
			var key : Button = hbox.get_child(j)
			key.pressed.connect(func(): ## dont connect it directly to the signal so i can pass in the key
				_on_virtual_key_pressed(key))


func _on_virtual_key_pressed(key : Button) -> void:
	if not text_box: return
	text_box.text = str(text_box.text + key.text)


func _input(event: InputEvent) -> void:
	if not event is InputEventJoypadButton: return
	match event.button_index:
		JOY_BUTTON_B:
			if not visible: return
			anim.play("close")
			prev_focus.grab_focus()
		
		JOY_BUTTON_A:
			if visible || not text_box: return
			anim.play("open")
			show()
			numbers.call_deferred("grab_focus")


func _on_back_pressed() -> void:
	if not text_box: return
	text_box.text = text_box.text.erase(text_box.text.length() - 1)


func _on_dot_pressed() -> void:
	if not text_box: return
	text_box.text = str(text_box.text + ".")


