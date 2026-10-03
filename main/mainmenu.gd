extends Control
## 主菜单脚本（副 C 维护）。
## 开始：藏菜单层（Main.gd 负责出现游戏并开跑）；菜单：开关键位说明浮层；
## 退出：关闭游戏。新增按钮先找主程，信号名不许乱改。

# 键位说明浮层，平时藏着，按“菜单”键出现
var _help_layer: CanvasLayer

func _ready() -> void:
	_build_help()
	# 延迟一帧再绑按钮动画：等布局算完尺寸，缩放才围绕按钮中心
	call_deferred("_init_button_fx")

func _init_button_fx() -> void:
	var box: Node = get_node_or_null("VBoxContainer")
	if box == null:
		push_warning("[mainmenu] 找不到 VBoxContainer，按钮动画跳过")
		return
	for button in box.get_children():
		if button is Button:
			button.pivot_offset = button.size / 2
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.mouse_exited.connect(_on_button_exit.bind(button))
			button.button_down.connect(_on_button_down.bind(button))
			button.button_up.connect(_on_button_up.bind(button))
			button.button_down.connect(_play_ui_sound)

# 键位说明浮层：全屏半透明盖在菜单上，点击任意处返回菜单
func _build_help() -> void:
	_help_layer = CanvasLayer.new()
	_help_layer.name = "HelpLayer"
	_help_layer.layer = 10
	_help_layer.visible = false
	add_child(_help_layer)
	var bg := ColorRect.new()
	bg.name = "HelpBg"
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_help_layer.add_child(bg)
	# 全屏隐形按钮接住所有点击（文字层全部穿透，保证点任意处都返回）
	var catcher := Button.new()
	catcher.flat = true
	catcher.text = ""
	catcher.focus_mode = Control.FOCUS_NONE
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	_help_layer.add_child(catcher)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_help_layer.add_child(center)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = "操作说明\n\nWASD / 方向键：移动青色主控细胞\n空格：加速（消耗体力）\n松开空格：缓慢恢复体力\n\n点击任意处返回菜单"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var sys_font := SystemFont.new()
	sys_font.font_names = PackedStringArray(["Microsoft YaHei", "SimHei", "PingFang SC", "Noto Sans SC", "sans-serif"])
	label.add_theme_font_override("font", sys_font)
	label.add_theme_font_size_override("font_size", 32)
	center.add_child(label)
	catcher.pressed.connect(_on_help_return)

# “菜单”键：开 / 关键位说明
func _on_button_2_pressed() -> void:
	_help_layer.visible = not _help_layer.visible

# 点浮层任意处：回到菜单
func _on_help_return() -> void:
	_help_layer.visible = false

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
	if has_node("UISound"):
		$UISound.play()
