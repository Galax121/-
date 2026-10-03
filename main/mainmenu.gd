extends Control

func _ready() -> void:
	for button in $Panel/VBoxContainer.get_children():
		if button is Button:
			button.pivot_offset = button.size / 2
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.mouse_exited.connect(_on_button_exit.bind(button))
			button.button_down.connect(_on_button_down.bind(button))
			button.button_up.connect(_on_button_up.bind(button))
			button.button_down.connect(_play_ui_sound)

func _on_button_3_pressed() -> void:
	get_tree().quit()

func _on_button_pressed() -> void:
	get_parent().visible = false

func _on_button_hover(button: Button):
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.2, 1.2), 0.15)

func _on_button_exit(button: Button):
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15)

func _on_button_down(button: Button):
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.15, 0.8), 0.08)

func _on_button_up(button: Button):
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.2, 1.2), 0.15)

func _play_ui_sound():
	$UISound.play()
