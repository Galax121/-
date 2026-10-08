extends Node2D
## 主场景脚本，挂在 Main.tscn 根节点 Node2D 上。
## 作用：纯展示，用代码建 UI + 细胞贴图，订阅 EventBus 更新 Label 和画面。
## 细胞运动：出生后缓慢自由滑动，出生不重叠，相撞后按原速率弹开。
## 细胞外观：白色圆形，大小统一，出生时由小到大渐变。
## 培养皿：大灰色圆形边界，细胞碰到后原速反弹。
## 流程：先显示副 C 的主菜单（MainMenuLayer），点“开始”后才出现培养皿和数值。
## 主控：第一个出生的细胞是主控（青色），WASD 控制方向，空格加速耗体力，
##   不加速缓慢回体力，体力条在左上角数值区。用默认输入映射，无需配键。
## 暂停：右上角暂停键 → 整局定住并弹菜单（继续 / 状态 / 退出游戏）。
## 等级：左上角数值只代表主控；其它细胞主控2级后随机出现，随存活变长升级
##   （升级速度与主控相近，移动速度与主控相同），上限为主控当前等级减一；
##   每个细胞头顶显示 lv.数字。

var label_state: Label
var label_cells: Label
var label_enemy: Label
var label_level: Label
var label_env: Label
var label_ending: Label
var label_hint: Label
var stamina_bar: ProgressBar
# 副A战斗属性：主控份数据对象（权威在技能系统/体力，这里只镜像）+ 底部三条
var combat: CellCombatStats
var bottom_box: VBoxContainer
var hp_bar: ProgressBar
var mp_bar: ProgressBar
var exp_bar: ProgressBar
# 敌人阶段横幅：平时藏着，敌军出现/围堵时才弹顶屏提示
var label_enemy_alert: Label

# 左上角数值区容器，菜单阶段先藏起来，点开始后再出现
var stats_box: VBoxContainer
# 副 C 的菜单层（Main.tscn 里的 MainMenuLayer），点开始后藏起来
var menu_layer: CanvasLayer

# 暂停相关：暂停层（含暂停键和暂停菜单，暂停时也要能点所以常开进程模式）
var pause_layer: CanvasLayer
var pause_btn: Button
var pause_menu: CenterContainer
# 倍速相关：右上角倍速键 + 速度单浮层（常开进程，定住也能点）
var speed_layer: CanvasLayer
var speed_btn: Button
var speed_menu: CenterContainer
# 可选倍速：点中后整局按该倍速跑
const SPEEDS: Array[float] = [0.5, 1.0, 1.5, 2.0, 3.0]
# 状态浮层：显示主控所有数值，点任意处回到暂停菜单
var state_overlay: CanvasLayer
var state_label: Label

# 细胞画面相关：容器 + 共享贴图 + 随机数 + 已生成的精灵列表 + 每个细胞的速度和年龄
var cell_layer: Node2D
var cell_texture: Texture2D
var rng := RandomNumberGenerator.new()
var cell_sprites: Array[Sprite2D] = []
var cell_vels: Array[Vector2] = []
var cell_ages: Array[float] = []
# 每个细胞的等级和头顶的 lv 标签（下标与 cell_sprites 对齐）
var cell_levels: Array[int] = []
var cell_level_labels: Array[Label] = []
# 出生调度：逻辑层涨的数先攒着，主控2级后随机滴出来
var _pending: int = 0
var _spawned_total: int = 0
var _spawn_timer: float = 0.0
var _next_spawn_in: float = 0.0
# 画面上最多画多少个，避免数量太大卡顿（逻辑数量不受限，Label 照常显示）
const MAX_VISUAL: int = 80
# 普通细胞：速度慢、细胞半径（碰撞距离 = 两倍半径）
const SPEED_MIN: float = 20.0
const SPEED_MAX: float = 35.0
const CELL_RADIUS: float = 20.0
# 主控细胞：比普通稍快，加速倍率，体力消耗/恢复速率
const MAIN_BASE_SPEED: float = 45.0
const MAIN_SPRINT_MULT: float = 1.8
const MAIN_DRIFT_SPEED: float = 22.0
const STAMINA_MAX: float = 100.0
const STAMINA_DRAIN: float = 30.0
const STAMINA_REGEN: float = 12.0
# 其它细胞：移动速度与主控相同，出生后每隔这么久升1级（与主控同为40秒一级）
const OTHER_LEVEL_UP_TIME: float = 40.0
# 外观参数：其它细胞最大形态统一，主控比它们大一档，出生后用这么久长满
const CELL_MAX_SCALE: float = 0.8
const MAIN_MAX_SCALE: float = 1.0
const GROW_TIME: float = 0.6
# 培养皿半径（相对 cell_layer 原点），细胞圆心活动范围 = 半径 - 细胞半径
const DISH_RADIUS: float = 280.0
# 敌方出生位点：主控3级时只在这三个点附近冒出来；4级后全图自由生成
const ENEMY_SPAWN_POINTS: Array[Vector2] = [Vector2(-150, -100), Vector2(150, -100), Vector2(0, 150)]
# 3级拴绳半径：没围堵时敌军只能在家附近打转，出绳就弹回
const ENEMY_TETHER_RADIUS: float = 70.0

# 体力：加速按住空格才扣，平时缓慢恢复
var stamina: float = STAMINA_MAX
var is_sprinting: bool = false
# 输入自检：第一次收到移动键时在输出栏打印一行，方便定位问题
var _input_ok_printed: bool = false
# 敌方画面：红色精灵、速度、年龄与出生调度（逻辑数在 EnemySystem 里）
var enemy_sprites: Array[Sprite2D] = []
var enemy_vels: Array[Vector2] = []
var enemy_ages: Array[float] = []
var _enemy_pending: int = 0
var _enemy_spawned_total: int = 0
var _enemy_spawn_timer: float = 0.0
var _enemy_next_in: float = 0.0
var _enemy_time: float = 0.0
# 每个敌军的家（3级出生位点），4级围堵后不再拴绳
var enemy_homes: Array[Vector2] = []

func _ready() -> void:
	rng.randomize()
	# 副A数据对象：不在场景树里，只存数（它的 _process 已停用，不会跟现有系统打架）
	combat = get_node_or_null("CellCombatStats")
	if combat == null:
		combat = CellCombatStats.new()
	combat.init_main()
	_build_cell_layer()
	_build_ui()
	_build_bottom_bars()
	_build_pause_ui()
	_build_speed_ui()
	_connect_signals()
	# 菜单阶段：藏起培养皿、数值和暂停键，只留菜单；游戏等点开始才跑
	menu_layer = $MainMenuLayer
	cell_layer.visible = false
	stats_box.visible = false
	bottom_box.visible = false
	pause_layer.visible = false
	speed_layer.visible = false
	_connect_menu()
	_refresh_all()
	print("[Main] UI 初始化完成，已订阅 EventBus")

# 接副 C 菜单的“开始”按钮：她自己的脚本负责藏菜单，这里负责出现游戏并开跑
func _connect_menu() -> void:
	var btn: Button = get_node_or_null("MainMenuLayer/Mainmenu/VBoxContainer/Button")
	if btn != null:
		btn.pressed.connect(_on_start_pressed)
	else:
		push_warning("[Main] 没找到开始按钮，检查 mainmenu.tscn 里是不是 VBoxContainer/Button")

# 点“开始”：藏菜单 → 清空旧细胞 → 体力回满 → 出现培养皿、数值和暂停键 → 通知开跑
# 必须释放按钮焦点，否则按空格会重新触发开始按钮导致重开
func _on_start_pressed() -> void:
	get_viewport().gui_release_focus()
	get_tree().paused = false
	Engine.time_scale = 1.0
	speed_menu.visible = false
	_update_speed_btn()
	if menu_layer != null:
		menu_layer.visible = false
	pause_menu.visible = false
	state_overlay.visible = false
	_clear_cells()
	_clear_enemies()
	stamina = STAMINA_MAX
	is_sprinting = false
	if combat != null:
		combat.init_main()
	cell_layer.visible = true
	stats_box.visible = true
	bottom_box.visible = true
	pause_layer.visible = true
	speed_layer.visible = true
	GameManager.start_game()
	_refresh_all()

# 清空画面上的旧细胞（重开一局时用，逻辑数量由 GameManager 重置）
func _clear_cells() -> void:
	for sp in cell_sprites:
		sp.queue_free()
	for lv in cell_level_labels:
		lv.queue_free()
	cell_sprites.clear()
	cell_vels.clear()
	cell_ages.clear()
	cell_levels.clear()
	cell_level_labels.clear()
	_pending = 0
	_spawned_total = 0
	_spawn_timer = 0.0
	_next_spawn_in = 0.0

# 每帧：主控输入 + 体力 + 出生调度 + 长大 + 运动 + 碰撞 + 等级，delta 为帧耗时
# 菜单阶段整个层藏着，直接跳过；暂停时引擎不会调这里（被定住）
func _process(delta: float) -> void:
	if cell_layer == null or not cell_layer.visible:
		return
	_update_main_input()
	_update_stamina(delta)
	_update_spawning(delta)
	_update_enemy_spawning(delta)
	_grow_cells(delta)
	_grow_enemies(delta)
	_move_cells(delta)
	_move_enemies(delta)
	_collide_cells()
	_separate_enemies()
	_update_other_levels(delta)
	_update_level_labels()
	_update_realtime_labels()
	_sync_combat_bars()

# ---- 暂停菜单 ----
# 右上角暂停键 + 居中弹窗（继续 / 状态 / 退出游戏），暂停层常开进程所以定住也能点
func _build_pause_ui() -> void:
	pause_layer = CanvasLayer.new()
	pause_layer.name = "PauseLayer"
	pause_layer.layer = 5
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_layer)
	pause_btn = _make_button("暂停", 24)
	pause_btn.anchor_left = 1.0
	pause_btn.anchor_right = 1.0
	pause_btn.offset_left = -150.0
	pause_btn.offset_right = -20.0
	pause_btn.offset_top = 20.0
	pause_btn.offset_bottom = 68.0
	pause_layer.add_child(pause_btn)
	pause_btn.pressed.connect(_on_pause_pressed)
	# 暂停菜单：半透明底 + 三个键
	pause_menu = CenterContainer.new()
	pause_menu.name = "PauseMenu"
	pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.visible = false
	pause_layer.add_child(pause_menu)
	var panel := PanelContainer.new()
	pause_menu.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var btn_resume := _make_button("继续", 28)
	var btn_state := _make_button("状态", 28)
	var btn_quit := _make_button("退出游戏", 28)
	box.add_child(btn_resume)
	box.add_child(btn_state)
	box.add_child(btn_quit)
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_state.pressed.connect(_on_state_pressed)
	btn_quit.pressed.connect(_on_quit_to_menu)
	# 状态浮层：比暂停菜单再高一层，点任意处回到暂停菜单
	state_overlay = CanvasLayer.new()
	state_overlay.name = "StateOverlay"
	state_overlay.layer = 6
	state_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	state_overlay.visible = false
	add_child(state_overlay)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state_overlay.add_child(bg)
	# 全屏隐形按钮接住所有点击（文字层全部穿透，保证点任意处都返回）
	var catcher := Button.new()
	catcher.flat = true
	catcher.text = ""
	catcher.focus_mode = Control.FOCUS_NONE
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	state_overlay.add_child(catcher)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state_overlay.add_child(center)
	state_label = Label.new()
	state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(state_label, 26)
	center.add_child(state_label)
	catcher.pressed.connect(_on_state_return)

# ---- 倍速 ----
# 右上角倍速键 + 速度单：点开定住选速度，选中按对应倍速跑，点空白处直接回去
func _build_speed_ui() -> void:
	speed_layer = CanvasLayer.new()
	speed_layer.name = "SpeedLayer"
	speed_layer.layer = 7
	speed_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(speed_layer)
	speed_btn = _make_button("1.0x", 24)
	speed_btn.anchor_left = 1.0
	speed_btn.anchor_right = 1.0
	speed_btn.offset_left = -300.0
	speed_btn.offset_right = -170.0
	speed_btn.offset_top = 20.0
	speed_btn.offset_bottom = 68.0
	speed_layer.add_child(speed_btn)
	speed_btn.pressed.connect(_on_speed_pressed)
	speed_menu = CenterContainer.new()
	speed_menu.name = "SpeedMenu"
	speed_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	speed_menu.visible = false
	speed_layer.add_child(speed_menu)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speed_menu.add_child(dim)
	# 全屏隐形按钮接住空白点击，直接回游戏（速度保持刚才选的）
	var catcher := Button.new()
	catcher.flat = true
	catcher.text = ""
	catcher.focus_mode = Control.FOCUS_NONE
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	speed_menu.add_child(catcher)
	var panel := PanelContainer.new()
	speed_menu.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	for s in SPEEDS:
		var b := _make_button("%.1fx" % s, 28)
		box.add_child(b)
		b.pressed.connect(_on_speed_chosen.bind(s))
	catcher.pressed.connect(_on_speed_return)

# 点倍速键：定住并弹速度单（同时收起暂停菜单防叠在一起）
func _on_speed_pressed() -> void:
	pause_menu.visible = false
	get_tree().paused = true
	speed_menu.visible = true

# 选中某档：整局按该倍速跑，收单继续
func _on_speed_chosen(value: float) -> void:
	Engine.time_scale = value
	_update_speed_btn()
	speed_menu.visible = false
	pause_menu.visible = false
	get_tree().paused = false

# 点空白处：不换挡，直接回游戏
func _on_speed_return() -> void:
	speed_menu.visible = false
	pause_menu.visible = false
	get_tree().paused = false

func _update_speed_btn() -> void:
	speed_btn.text = "%.1fx" % Engine.time_scale

# 做一个中文字体可用的按钮：去焦点（防空格误触）+ 系统中文字体
func _make_button(text: String, font_size: int) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_override("font", game_font())
	btn.add_theme_font_size_override("font_size", font_size)
	return btn

func _apply_font(label: Label, font_size: int) -> void:
	label.add_theme_font_override("font", game_font())
	label.add_theme_font_size_override("font_size", font_size)

# 全局统一字体：副C的UI字体，加载一次复用，文件缺失时回退系统字体
const UI_FONT_PATH: String = "res://main/字体/NanoTikBazHei-Bold.ttf"
var _shared_font: Font = null

func game_font() -> Font:
	if _shared_font == null:
		if ResourceLoader.exists(UI_FONT_PATH):
			_shared_font = load(UI_FONT_PATH)
		else:
			var sys := SystemFont.new()
			sys.font_names = PackedStringArray(["Microsoft YaHei", "SimHei", "PingFang SC", "Noto Sans SC", "sans-serif"])
			_shared_font = sys
	return _shared_font

# 点暂停键：定住整局（含细胞和计时），弹出菜单
func _on_pause_pressed() -> void:
	speed_menu.visible = false
	get_tree().paused = true
	pause_menu.visible = true

# 继续：收起菜单，原速接着跑
func _on_resume_pressed() -> void:
	pause_menu.visible = false
	get_tree().paused = false

# 状态：藏暂停菜单，弹出主控数值浮层
func _on_state_pressed() -> void:
	pause_menu.visible = false
	state_label.text = _main_stats_text()
	state_overlay.visible = true

# 点浮层任意处：回暂停菜单（游戏继续定着）
func _on_state_return() -> void:
	state_overlay.visible = false
	pause_menu.visible = true

# 退出游戏：解暂停 → 藏游戏 → 清细胞 → 停模拟 → 回主菜单
func _on_quit_to_menu() -> void:
	get_tree().paused = false
	pause_menu.visible = false
	state_overlay.visible = false
	Engine.time_scale = 1.0
	speed_menu.visible = false
	_update_speed_btn()
	pause_layer.visible = false
	speed_layer.visible = false
	label_enemy_alert.visible = false
	cell_layer.visible = false
	stats_box.visible = false
	bottom_box.visible = false
	_clear_cells()
	_clear_enemies()
	GameManager.stop_to_menu()
	if menu_layer != null:
		menu_layer.visible = true

# 主控所有数值：位置、速度、速率、体力、等级、大小、存活时间，外加场上总数
func _main_stats_text() -> String:
	var lines := PackedStringArray()
	lines.append("主控细胞状态\n")
	if cell_sprites.is_empty():
		lines.append("场上暂无细胞")
	else:
		var pos: Vector2 = cell_sprites[0].position
		var vel: Vector2 = cell_vels[0]
		var diameter: float = 64.0 * cell_sprites[0].scale.x
		lines.append("位置：(%.0f, %.0f)" % [pos.x, pos.y])
		lines.append("速度：(%.1f, %.1f)" % [vel.x, vel.y])
		lines.append("速率：%.1f 像素/秒" % vel.length())
		lines.append("体力：%.0f / %.0f" % [stamina, STAMINA_MAX])
		lines.append("敌军：%d" % enemy_sprites.size())
		lines.append("等级：lv.%d（最高 30）" % cell_levels[0])
		lines.append("大小：缩放 %.2f，直径约 %.0f 像素" % [cell_sprites[0].scale.x, diameter])
		lines.append("存活：%.1f 秒" % cell_ages[0])
	lines.append("场上细胞总数：%d" % cell_sprites.size())
	lines.append("\n点击任意处返回")
	return "\n".join(lines)

# 主控输入：cell_sprites[0] 是主控（青色），WASD/方向键定方向，空格加速
# 直接读物理键，不依赖 InputMap，动作映射被改也不影响
# 有输入就按输入走，没输入就缓慢漂移；加速只有体力大于 0 才生效
func _update_main_input() -> void:
	is_sprinting = false
	if cell_sprites.is_empty():
		return
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if dir == Vector2.ZERO:
		dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir.length() < 0.01:
		if cell_vels[0].length() > MAIN_DRIFT_SPEED:
			cell_vels[0] = cell_vels[0].normalized() * MAIN_DRIFT_SPEED
		return
	if not _input_ok_printed:
		_input_ok_printed = true
		print("[Main] 移动输入已接通，主控开始响应")
	var want_sprint: bool = (Input.is_physical_key_pressed(KEY_SPACE) or Input.is_action_pressed("ui_accept")) and stamina > 0.0
	var spd: float = MAIN_BASE_SPEED * (MAIN_SPRINT_MULT if want_sprint else 1.0)
	cell_vels[0] = dir.normalized() * spd
	is_sprinting = want_sprint

# 体力：加速扣，平时回，同步到体力条
func _update_stamina(delta: float) -> void:
	if is_sprinting:
		stamina = maxf(stamina - STAMINA_DRAIN * delta, 0.0)
	else:
		stamina = minf(stamina + STAMINA_REGEN * delta, STAMINA_MAX)
	if stamina_bar != null:
		stamina_bar.value = stamina

# 细胞层：放在 (640, 420) 附近，培养皿圆心就在这里，所有细胞都是它的子节点
func _build_cell_layer() -> void:
	cell_layer = Node2D.new()
	cell_layer.name = "CellLayer"
	cell_layer.position = Vector2(640, 420)
	add_child(cell_layer)
	_build_dish()
	cell_texture = _make_cell_texture()

# 培养皿：灰色半透明圆底 + 灰色圆环边，z_index 为负保证画在细胞下面
func _build_dish() -> void:
	var pts := PackedVector2Array()
	var n: int = 64
	for i in range(n):
		var a: float = TAU * float(i) / float(n)
		pts.append(Vector2(cos(a), sin(a)) * DISH_RADIUS)
	var fill := Polygon2D.new()
	fill.name = "DishFill"
	fill.polygon = pts
	fill.color = Color(0.5, 0.5, 0.5, 0.25)
	fill.z_index = -2
	cell_layer.add_child(fill)
	var ring_pts := PackedVector2Array(pts)
	ring_pts.append(pts[0])
	var ring := Line2D.new()
	ring.name = "DishRing"
	ring.points = ring_pts
	ring.width = 6.0
	ring.default_color = Color(0.7, 0.7, 0.7, 0.9)
	ring.joint_mode = Line2D.LINE_JOINT_ROUND
	ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	ring.z_index = -1
	cell_layer.add_child(ring)

# 用纯代码生成一张白色圆形细胞贴图，不需要外部 PNG
# 原理：径向渐变中间纯白、边缘透明，天然就是一个白圆
func _make_cell_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = 64
	tex.height = 64
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "UI"
	add_child(layer)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.position = Vector2(20, 20)
	box.add_theme_constant_override("separation", 8)
	layer.add_child(box)
	stats_box = box
	label_state = _make_label(box, "状态: -")
	label_cells = _make_label(box, "细胞数量: -")
	label_enemy = _make_label(box, "敌军数量: -")
	label_level = _make_label(box, "等级: -")
	label_env = _make_label(box, "环境温度: -")
	label_ending = _make_label(box, "结局: -")
	_make_label(box, "体力（空格加速）:")
	stamina_bar = ProgressBar.new()
	stamina_bar.min_value = 0.0
	stamina_bar.max_value = STAMINA_MAX
	stamina_bar.value = STAMINA_MAX
	stamina_bar.show_percentage = false
	stamina_bar.custom_minimum_size = Vector2(220, 18)
	box.add_child(stamina_bar)
	label_hint = _make_label(box, "目标50胜！升级40秒一级，3级出敌军")
	# 顶屏横幅：平时藏着，只在敌军出现/围堵时显示
	label_enemy_alert = Label.new()
	label_enemy_alert.text = "敌军出现！"
	_apply_font(label_enemy_alert, 40)
	label_enemy_alert.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	label_enemy_alert.anchor_left = 0.5
	label_enemy_alert.anchor_right = 0.5
	label_enemy_alert.offset_left = -300.0
	label_enemy_alert.offset_right = 300.0
	label_enemy_alert.offset_top = 24.0
	label_enemy_alert.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_enemy_alert.visible = false
	layer.add_child(label_enemy_alert)

# 屏幕下方三条：血量（红）、法力（蓝＝体力）、经验（绿），读副A数据对象
func _build_bottom_bars() -> void:
	var blayer := CanvasLayer.new()
	blayer.name = "BottomLayer"
	add_child(blayer)
	bottom_box = VBoxContainer.new()
	bottom_box.name = "BottomBox"
	bottom_box.anchor_left = 0.0
	bottom_box.anchor_top = 1.0
	bottom_box.anchor_right = 0.0
	bottom_box.anchor_bottom = 1.0
	bottom_box.offset_left = 20.0
	bottom_box.offset_top = -150.0
	bottom_box.offset_right = 440.0
	bottom_box.offset_bottom = -20.0
	bottom_box.add_theme_constant_override("separation", 6)
	blayer.add_child(bottom_box)
	hp_bar = _make_bar(Color(1.0, 0.32, 0.32))
	mp_bar = _make_bar(Color(0.32, 0.6, 1.0))
	exp_bar = _make_bar(Color(0.35, 0.9, 0.4))
	_add_bar_row(bottom_box, "血量", hp_bar)
	_add_bar_row(bottom_box, "法力", mp_bar)
	_add_bar_row(bottom_box, "经验", exp_bar)

func _add_bar_row(parent: Control, text: String, bar: ProgressBar) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var lab := Label.new()
	lab.text = text
	lab.custom_minimum_size = Vector2(72, 0)
	_apply_font(lab, 22)
	row.add_child(lab)
	row.add_child(bar)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _make_bar(fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(300, 20)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(6)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	return bar

# 战斗属性同步：等级/经验只读镜像进副A对象；法力独立属性，目前无消耗，只展示
func _sync_combat_bars() -> void:
	if combat == null:
		return
	combat.level = mini(GameManager.get_level(), 30)
	var sys = GameManager.skill_system
	if sys != null and sys.has_method("get_upgrade_progress"):
		var pg: Vector2 = sys.get_upgrade_progress()
		combat.exp = pg.x
		combat.exp_to_next = pg.y
	hp_bar.max_value = combat.max_hp
	hp_bar.value = combat.hp
	mp_bar.max_value = combat.max_mp
	mp_bar.value = combat.mp
	exp_bar.max_value = combat.exp_to_next
	exp_bar.value = combat.exp

func _make_label(parent: Control, text: String) -> Label:
	var label := Label.new()
	label.text = text
	_apply_font(label, 24)
	parent.add_child(label)
	return label

func _connect_signals() -> void:
	EventBus.cell_count_changed.connect(_on_cell_count_changed)
	EventBus.enemy_count_changed.connect(_on_enemy_count_changed)
	EventBus.env_changed.connect(_on_env_changed)
	EventBus.level_changed.connect(_on_level_changed)
	EventBus.ending_triggered.connect(_on_ending_triggered)
	EventBus.game_state_changed.connect(_on_game_state_changed)

func _refresh_all() -> void:
	_on_game_state_changed(GameManager.state_to_string(GameManager.current_state))
	_on_cell_count_changed(GameManager.get_cell_count())
	_on_level_changed(GameManager.get_level())
	_on_env_changed("temperature", GameManager.get_temperature())
	if GameManager.ending_id != "":
		_on_ending_triggered(GameManager.ending_id)

# 逻辑层涨数只攒进待出生池，不直接刷画面；逻辑掉数则同步裁掉（主控保留）
func _on_cell_count_changed(count: int) -> void:
	_pending = maxi(count - _spawned_total, 0)
	while _spawned_total > count and cell_sprites.size() > 1:
		_free_last_cell()
		_spawned_total -= 1
	_update_count_label()

# 左上角细胞数量显示场上实际总数 / 胜利线（胜利线读结局系统，不在两处硬写）
func _update_count_label() -> void:
	var target := 50
	if GameManager.ending_system != null:
		var w = GameManager.ending_system.get("win_cell_count")
		if w != null:
			target = int(w)
	label_cells.text = "细胞数量：%d/%d" % [cell_sprites.size(), target]

# 出生调度：第一个永远是主控；其它细胞主控2级后才随机滴出来（0.15~0.4 秒一个）
func _update_spawning(delta: float) -> void:
	if _pending <= 0:
		return
	if cell_sprites.size() >= MAX_VISUAL:
		_pending = 0
		return
	var is_first: bool = cell_sprites.is_empty()
	if not is_first and GameManager.get_level() < 2:
		return
	_spawn_timer += delta
	if _spawn_timer < _next_spawn_in:
		return
	_spawn_timer = 0.0
	_next_spawn_in = rng.randf_range(0.15, 0.4)
	_spawn_one_cell()
	_pending -= 1
	_spawned_total += 1
	_update_count_label()

# 出生一个细胞：找不重叠的位置，主控青色慢速，其它白色、速度与主控相同、1 级开局
func _spawn_one_cell() -> void:
	var is_main: bool = cell_sprites.is_empty()
	var sp := Sprite2D.new()
	sp.texture = cell_texture
	sp.position = _find_free_spot()
	# 出生时很小，主控长到更大，随后在 _grow_cells 里各自长满
	sp.scale = Vector2.ONE * (MAIN_MAX_SCALE if is_main else CELL_MAX_SCALE) * 0.1
	if is_main:
		sp.modulate = Color(0.65, 1.0, 1.0)
	else:
		sp.modulate = Color(1, 1, 1, 1)
	cell_layer.add_child(sp)
	cell_sprites.append(sp)
	cell_ages.append(0.0)
	if is_main:
		cell_levels.append(mini(GameManager.get_level(), 30))
		cell_vels.append(Vector2.RIGHT * MAIN_DRIFT_SPEED)
	else:
		cell_levels.append(1)
		var ang: float = rng.randf_range(0.0, TAU)
		cell_vels.append(Vector2(cos(ang), sin(ang)) * MAIN_BASE_SPEED)
	var lv := _make_level_label(is_main)
	lv.text = "lv.%d" % cell_levels[cell_levels.size() - 1]
	lv.position = sp.position + Vector2(-14, -36)
	cell_layer.add_child(lv)
	cell_level_labels.append(lv)

# 头顶等级签：纯英文数字，默认字体即可，主控偏青、其它白色，点穿透
func _make_level_label(is_main: bool) -> Label:
	var lv := Label.new()
	lv.add_theme_font_override("font", game_font())
	lv.add_theme_font_size_override("font_size", 14)
	if is_main:
		lv.add_theme_color_override("font_color", Color(0.7, 1.0, 1.0))
	else:
		lv.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	lv.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	lv.add_theme_constant_override("shadow_offset_x", 1)
	lv.add_theme_constant_override("shadow_offset_y", 1)
	lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lv

# 从末尾删一个细胞（精灵、速度、年龄、等级、等级签一起删，主控下标 0 永不动）
func _free_last_cell() -> void:
	var last: Sprite2D = cell_sprites.pop_back()
	var last_lv: Label = cell_level_labels.pop_back()
	cell_vels.pop_back()
	cell_ages.pop_back()
	cell_levels.pop_back()
	last_lv.queue_free()
	last.queue_free()

# 出生渐变 + 存活计时：年龄一直累积（等级用它算），缩放到头就停在统一大小
func _grow_cells(delta: float) -> void:
	for i in range(cell_sprites.size()):
		cell_ages[i] += delta
		if cell_ages[i] >= GROW_TIME:
			continue
		var t: float = clampf(cell_ages[i] / GROW_TIME, 0.0, 1.0)
		var smooth: float = t * t * (3.0 - 2.0 * t)
		var max_s: float = MAIN_MAX_SCALE if i == 0 else CELL_MAX_SCALE
		var s: float = max_s * (0.1 + 0.9 * smooth)
		cell_sprites[i].scale = Vector2(s, s)

# 其它细胞升级：存活每满 40 秒升 1 级，上限为主控当前等级减一（至少 1 级）
# 主控等级直接跟技能系统走（最高 30 级已在 SkillSystemStub 里封顶）
func _update_other_levels(_delta: float) -> void:
	var main_lv: int = mini(GameManager.get_level(), 30)
	if not cell_levels.is_empty() and cell_levels[0] != main_lv:
		cell_levels[0] = main_lv
		cell_level_labels[0].text = "lv.%d" % main_lv
	var cap: int = maxi(main_lv - 1, 1)
	for i in range(1, cell_levels.size()):
		var lv: int = mini(1 + int(cell_ages[i] / OTHER_LEVEL_UP_TIME), cap)
		if lv != cell_levels[i]:
			cell_levels[i] = lv
			cell_level_labels[i].text = "lv.%d" % lv

# 等级签跟随：每帧贴到各自细胞正上方
func _update_level_labels() -> void:
	for i in range(cell_sprites.size()):
		cell_level_labels[i].position = cell_sprites[i].position + Vector2(-14, -36)

# ---- 敌方 ----
# 逻辑层敌军涨数只攒进池子，画面按 0.3~0.6 秒一个滴出来（比增殖快，基本跟得上）
func _on_enemy_count_changed(count: int) -> void:
	label_enemy.text = "敌军数量：%d" % count
	_enemy_pending = maxi(count - _enemy_spawned_total, 0)
	while _enemy_spawned_total > count and not enemy_sprites.is_empty():
		_remove_enemy_at(enemy_sprites.size() - 1)
		_enemy_spawned_total -= 1

func _update_enemy_spawning(delta: float) -> void:
	if _enemy_pending <= 0:
		return
	if enemy_sprites.size() >= MAX_VISUAL:
		_enemy_pending = 0
		return
	_enemy_spawn_timer += delta
	if _enemy_spawn_timer < _enemy_next_in:
		return
	_enemy_spawn_timer = 0.0
	_enemy_next_in = rng.randf_range(0.3, 0.6)
	_spawn_enemy()
	_enemy_pending -= 1
	_enemy_spawned_total += 1

# 出生一个敌军：红色，同尺寸。3级在家附近冒出来，4级围堵后全图自由生成
func _spawn_enemy() -> void:
	var hunting: bool = GameManager.enemy_hunting()
	var home := Vector2.ZERO
	var pos: Vector2
	if hunting:
		pos = _find_free_spot()
	else:
		home = ENEMY_SPAWN_POINTS[rng.randi_range(0, ENEMY_SPAWN_POINTS.size() - 1)]
		pos = _find_spot_near(home)
	var sp := Sprite2D.new()
	sp.texture = cell_texture
	sp.position = pos
	sp.scale = Vector2.ONE * CELL_MAX_SCALE * 0.1
	sp.modulate = Color(1.0, 0.45, 0.45)
	cell_layer.add_child(sp)
	enemy_sprites.append(sp)
	enemy_ages.append(0.0)
	enemy_homes.append(home)
	var ang: float = rng.randf_range(0.0, TAU)
	enemy_vels.append(Vector2(cos(ang), sin(ang)) * GameManager.enemy_speed())

# 在家附近找出生点：半径 35 内试 10 次，避开已有细胞，实在没位就直接放
func _find_spot_near(home: Vector2) -> Vector2:
	var min_sep: float = CELL_RADIUS * 2.4
	var max_r: float = DISH_RADIUS - CELL_RADIUS - 4.0
	for i in range(10):
		var p: Vector2 = home + Vector2(rng.randf_range(-35.0, 35.0), rng.randf_range(-35.0, 35.0))
		if p.length() > max_r:
			p = p.normalized() * max_r
		var ok := true
		for sp in cell_sprites:
			if p.distance_to(sp.position) < min_sep:
				ok = false
				break
		if ok:
			for ep in enemy_sprites:
				if p.distance_to(ep.position) < min_sep:
					ok = false
					break
		if ok:
			return p
	return home

# 敌军出生渐变：和我方一样由小到大，年龄照计
func _grow_enemies(delta: float) -> void:
	for i in range(enemy_sprites.size()):
		enemy_ages[i] += delta
		if enemy_ages[i] >= GROW_TIME:
			continue
		var t: float = clampf(enemy_ages[i] / GROW_TIME, 0.0, 1.0)
		var smooth: float = t * t * (3.0 - 2.0 * t)
		var s: float = CELL_MAX_SCALE * (0.1 + 0.9 * smooth)
		enemy_sprites[i].scale = Vector2(s, s)

# 敌方移动：游荡沿直线，围堵追最近的我方细胞（带一点摆动形成包围感）
func _move_enemies(delta: float) -> void:
	var speed: float = GameManager.enemy_speed()
	var hunting: bool = GameManager.enemy_hunting()
	_enemy_time += delta
	var max_center: float = DISH_RADIUS - CELL_RADIUS
	for i in range(enemy_sprites.size()):
		var e: Sprite2D = enemy_sprites[i]
		if hunting and not cell_sprites.is_empty():
			var target: Vector2 = _nearest_player_pos(e.position)
			var want: Vector2 = target - e.position
			if want.length() > 1.0:
				var dir: Vector2 = want.normalized()
				var perp := Vector2(-dir.y, dir.x)
				var wobble: float = 0.35 * sin(_enemy_time * 3.0 + float(i) * 1.7)
				enemy_vels[i] = (dir + perp * wobble).normalized() * speed
		e.position += enemy_vels[i] * delta
		var dist: float = e.position.length()
		if dist > max_center:
			var n: Vector2 = e.position / dist
			e.position = n * max_center
			var v: Vector2 = enemy_vels[i]
			var rv: Vector2 = v - 2.0 * v.dot(n) * n
			if rv.length() > 0.001:
				enemy_vels[i] = rv.normalized() * v.length()
		# 3级拴绳：没围堵时离家超过绳长就拉回并反弹，4级后自由行动
		if not hunting:
			var leash: Vector2 = e.position - enemy_homes[i]
			if leash.length() > ENEMY_TETHER_RADIUS:
				var ln: Vector2 = leash.normalized()
				e.position = enemy_homes[i] + ln * ENEMY_TETHER_RADIUS
				var vv: Vector2 = enemy_vels[i]
				var rvv: Vector2 = vv - 2.0 * vv.dot(ln) * ln
				if rvv.length() > 0.001:
					enemy_vels[i] = rvv.normalized() * vv.length()

# 离 epos 最近的我方细胞位置
func _nearest_player_pos(epos: Vector2) -> Vector2:
	var best: Vector2 = cell_sprites[0].position
	var best_d: float = epos.distance_to(best)
	for k in range(1, cell_sprites.size()):
		var d: float = epos.distance_to(cell_sprites[k].position)
		if d < best_d:
			best_d = d
			best = cell_sprites[k].position
	return best

# 敌军之间只推开不换速，避免叠罗汉
func _separate_enemies() -> void:
	var min_dist: float = CELL_RADIUS * 2.0
	for i in range(enemy_sprites.size()):
		for j in range(i + 1, enemy_sprites.size()):
			var d: Vector2 = enemy_sprites[i].position - enemy_sprites[j].position
			var dist: float = d.length()
			if dist < 0.001 or dist >= min_dist:
				continue
			var n: Vector2 = d / dist
			var overlap: float = (min_dist - dist) * 0.5
			enemy_sprites[i].position += n * overlap
			enemy_sprites[j].position -= n * overlap

# 敌我接触不结算：敌方只出现、不造成伤害，穿过我方细胞继续游荡/围堵

func _remove_enemy_at(i: int) -> void:
	var sp: Sprite2D = enemy_sprites[i]
	enemy_sprites.remove_at(i)
	enemy_vels.remove_at(i)
	enemy_ages.remove_at(i)
	enemy_homes.remove_at(i)
	sp.queue_free()
	_enemy_spawned_total -= 1

# 清空敌军画面与调度（重开 / 退出菜单时用）
func _clear_enemies() -> void:
	for sp in enemy_sprites:
		sp.queue_free()
	enemy_sprites.clear()
	enemy_vels.clear()
	enemy_ages.clear()
	enemy_homes.clear()
	_enemy_pending = 0
	_enemy_spawned_total = 0
	_enemy_spawn_timer = 0.0
	_enemy_next_in = 0.0

# 在培养皿圆内找一个与其他细胞不重叠的出生点，最多试 20 次
func _find_free_spot() -> Vector2:
	var min_sep: float = CELL_RADIUS * 2.4
	var max_r: float = DISH_RADIUS - CELL_RADIUS - 4.0
	for i in range(20):
		var p := _random_point_in_dish(max_r)
		var ok := true
		for sp in cell_sprites:
			if p.distance_to(sp.position) < min_sep:
				ok = false
				break
		for ep in enemy_sprites:
			if p.distance_to(ep.position) < min_sep:
				ok = false
				break
		if ok:
			return p
	return _random_point_in_dish(max_r)

# 在圆内均匀随机取点：角度随机，半径按 sqrt 取，保证中间和边缘密度一致
func _random_point_in_dish(max_r: float) -> Vector2:
	var a: float = rng.randf_range(0.0, TAU)
	var r: float = sqrt(rng.randf()) * max_r
	return Vector2(cos(a), sin(a)) * r

# 直线滑动 + 碰到培养皿圆壁沿法线反射，速率归一回原来大小
# 主控的速度由 _update_main_input 每帧重写，这里只管推位置和碰壁
func _move_cells(delta: float) -> void:
	var max_center: float = DISH_RADIUS - CELL_RADIUS
	for i in range(cell_sprites.size()):
		var sp: Sprite2D = cell_sprites[i]
		sp.position += cell_vels[i] * delta
		var dist: float = sp.position.length()
		if dist > max_center:
			var n: Vector2 = sp.position / dist
			# 拉回皿内
			sp.position = n * max_center
			# 反射：v' = v - 2*(v·n)*n
			var v: Vector2 = cell_vels[i]
			var spd: float = v.length()
			var rv: Vector2 = v - 2.0 * v.dot(n) * n
			if rv.length() > 0.001:
				rv = rv.normalized() * spd
			cell_vels[i] = rv

# 两两碰撞：先沿连线推开，再交换法向速度分量，最后把速率归一回原速率
func _collide_cells() -> void:
	var min_dist: float = CELL_RADIUS * 2.0
	for i in range(cell_sprites.size()):
		for j in range(i + 1, cell_sprites.size()):
			var pi: Vector2 = cell_sprites[i].position
			var pj: Vector2 = cell_sprites[j].position
			var d: Vector2 = pi - pj
			var dist: float = d.length()
			if dist < 0.001 or dist >= min_dist:
				continue
			var n: Vector2 = d / dist
			# 位置修正：各推开一半重叠，避免粘在一起
			var overlap: float = (min_dist - dist) * 0.5
			cell_sprites[i].position = pi + n * overlap
			cell_sprites[j].position = pj - n * overlap
			# 速度：等质量弹性碰撞，交换法向分量
			var v1: Vector2 = cell_vels[i]
			var v2: Vector2 = cell_vels[j]
			var s1: float = v1.length()
			var s2: float = v2.length()
			var v1n: Vector2 = n * v1.dot(n)
			var v2n: Vector2 = n * v2.dot(n)
			var nv1: Vector2 = (v1 - v1n) + v2n
			var nv2: Vector2 = (v2 - v2n) + v1n
			# 按原速率归一（防零向量），即“反向弹开、速率不变”
			if nv1.length() > 0.001:
				nv1 = nv1.normalized() * s1
			else:
				nv1 = -n * s1
			if nv2.length() > 0.001:
				nv2 = nv2.normalized() * s2
			else:
				nv2 = n * s2
			cell_vels[i] = nv1
			cell_vels[j] = nv2
			# 主控被撞后速率可能乱掉，下一帧输入会按规则重写，这里只保底
			if i == 0 and nv1.length() > MAIN_BASE_SPEED * MAIN_SPRINT_MULT:
				cell_vels[0] = nv1.normalized() * MAIN_BASE_SPEED * MAIN_SPRINT_MULT

# 实时状态行：等级倒计时 + 敌军模式，每帧刷新，与当前设置对齐
func _update_realtime_labels() -> void:
	var lv: int = mini(GameManager.get_level(), 30)
	label_level.text = "等级：%d" % lv
	var active := false
	if GameManager.enemy_system != null:
		active = GameManager.enemy_system.get("active") == true
	var mode := "未出现"
	if GameManager.enemy_hunting():
		mode = "围堵中"
	elif active:
		mode = "游荡中"
	label_enemy.text = "敌军数量：%d（%s）" % [enemy_sprites.size(), mode]
	if GameManager.enemy_hunting():
		label_enemy_alert.text = "敌军围堵中！"
		label_enemy_alert.visible = true
	elif active:
		label_enemy_alert.text = "敌军出现！"
		label_enemy_alert.visible = true
	else:
		label_enemy_alert.visible = false
	if label_enemy_alert.visible:
		label_enemy_alert.modulate.a = 0.7 + 0.3 * sin(Time.get_ticks_msec() / 300.0)
	# 状态行：状态机已按新节奏重排，直接显示中文名（敌军细节看横幅和敌军行）
	label_state.text = "状态：" + _state_display_name(GameManager.state_to_string(GameManager.current_state))

func _on_env_changed(name: String, value: float) -> void:
	label_env.text = "环境 %s: %.1f" % [name, value]

# 左上角等级只代表主控（与头顶 lv.数字一致，最高 30）
func _on_level_changed(level: int) -> void:
	label_level.text = "等级: %d" % mini(level, 30)

func _on_ending_triggered(ending_id: String) -> void:
	var desc := ending_id
	if ending_id == "player_win":
		desc = "player_win（玩家胜：细胞数>50）"
	label_ending.text = "结局: %s" % desc

func _on_game_state_changed(state: String) -> void:
	label_state.text = "状态：" + _state_display_name(state)

# 状态机中文名：SELECT准备 / GROW成长期 / ENV发展期 / ENEMY敌军期 / END已结束
func _state_display_name(state: String) -> String:
	match state:
		"SELECT":
			return "准备"
		"GROW":
			return "成长期"
		"ENV":
			return "发展期"
		"ENEMY":
			return "敌军期"
		"END":
			return "已结束"
	return state
