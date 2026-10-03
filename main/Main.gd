extends Node2D
## 主场景脚本，挂在 Main.tscn 根节点 Node2D 上。
## 作用：纯展示，用代码建 UI + 细胞贴图，订阅 EventBus 更新 Label 和画面。
## 细胞运动：出生后缓慢自由滑动，出生不重叠，相撞后按原速率弹开。
## 细胞外观：白色圆形，大小统一，出生时由小到大渐变。
## 培养皿：大灰色圆形边界，细胞碰到后原速反弹。

var label_state: Label
var label_cells: Label
var label_level: Label
var label_env: Label
var label_ending: Label
var label_hint: Label

# 细胞画面相关：容器 + 共享贴图 + 随机数 + 已生成的精灵列表 + 每个细胞的速度和年龄
var cell_layer: Node2D
var cell_texture: Texture2D
var rng := RandomNumberGenerator.new()
var cell_sprites: Array[Sprite2D] = []
var cell_vels: Array[Vector2] = []
var cell_ages: Array[float] = []
# 画面上最多画多少个，避免数量太大卡顿（逻辑数量不受限，Label 照常显示）
const MAX_VISUAL: int = 80
# 运动与碰撞参数：速度慢、细胞半径（碰撞距离 = 两倍半径）
const SPEED_MIN: float = 20.0
const SPEED_MAX: float = 35.0
const CELL_RADIUS: float = 20.0
# 外观参数：所有细胞最大形态统一，出生后用这么久长到最大
const CELL_MAX_SCALE: float = 0.8
const GROW_TIME: float = 0.6
# 培养皿半径（相对 cell_layer 原点），细胞圆心活动范围 = 半径 - 细胞半径
const DISH_RADIUS: float = 280.0

func _ready() -> void:
	rng.randomize()
	_build_cell_layer()
	_build_ui()
	_connect_signals()
	_refresh_all()
	print("[Main] UI 初始化完成，已订阅 EventBus")

# 每帧推细胞运动 + 长大动画 + 碰撞，delta 为帧耗时
func _process(delta: float) -> void:
	_grow_cells(delta)
	_move_cells(delta)
	_collide_cells()

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
	label_state = _make_label(box, "状态: -")
	label_cells = _make_label(box, "细胞数量: -")
	label_level = _make_label(box, "等级: -")
	label_env = _make_label(box, "环境温度: -")
	label_ending = _make_label(box, "结局: -")
	label_hint = _make_label(box, "流程自动运行: SELECT -> GROW -> ENV -> ENEMY -> END")

func _make_label(parent: Control, text: String) -> Label:
	var label := Label.new()
	label.text = text
	var sys_font := SystemFont.new()
	sys_font.font_names = PackedStringArray(["Microsoft YaHei", "SimHei", "PingFang SC", "Noto Sans SC", "sans-serif"])
	label.add_theme_font_override("font", sys_font)
	label.add_theme_font_size_override("font_size", 24)
	parent.add_child(label)
	return label

func _connect_signals() -> void:
	EventBus.cell_count_changed.connect(_on_cell_count_changed)
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

func _on_cell_count_changed(count: int) -> void:
	label_cells.text = "细胞数量: %d" % count
	_sync_cell_visuals(count)

# 按数量补齐细胞精灵：少了就新建（找不重叠的位置 + 随机速度 + 从小开始长），多了就删掉
func _sync_cell_visuals(count: int) -> void:
	var target: int = mini(count, MAX_VISUAL)
	while cell_sprites.size() < target:
		var sp := Sprite2D.new()
		sp.texture = cell_texture
		sp.position = _find_free_spot()
		# 出生时很小，随后在 _grow_cells 里长到统一的最大尺寸
		sp.scale = Vector2.ONE * CELL_MAX_SCALE * 0.1
		sp.modulate = Color(1, 1, 1, 1)
		cell_layer.add_child(sp)
		cell_sprites.append(sp)
		cell_ages.append(0.0)
		# 随机方向、缓慢速率
		var ang: float = rng.randf_range(0.0, TAU)
		var spd: float = rng.randf_range(SPEED_MIN, SPEED_MAX)
		cell_vels.append(Vector2(cos(ang), sin(ang)) * spd)
	while cell_sprites.size() > target:
		var last: Sprite2D = cell_sprites.pop_back()
		cell_vels.pop_back()
		cell_ages.pop_back()
		last.queue_free()

# 出生渐变：用 smoothstep 让缩放从 10% 平滑长到 100%，到时间就停在统一大小
func _grow_cells(delta: float) -> void:
	for i in range(cell_sprites.size()):
		if cell_ages[i] >= GROW_TIME:
			continue
		cell_ages[i] += delta
		var t: float = clampf(cell_ages[i] / GROW_TIME, 0.0, 1.0)
		var smooth: float = t * t * (3.0 - 2.0 * t)
		var s: float = CELL_MAX_SCALE * (0.1 + 0.9 * smooth)
		cell_sprites[i].scale = Vector2(s, s)

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
		if ok:
			return p
	return _random_point_in_dish(max_r)

# 在圆内均匀随机取点：角度随机，半径按 sqrt 取，保证中间和边缘密度一致
func _random_point_in_dish(max_r: float) -> Vector2:
	var a: float = rng.randf_range(0.0, TAU)
	var r: float = sqrt(rng.randf()) * max_r
	return Vector2(cos(a), sin(a)) * r

# 直线滑动 + 碰到培养皿圆壁沿法线反射，速率归一回原来大小
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

func _on_env_changed(name: String, value: float) -> void:
	label_env.text = "环境 %s: %.1f" % [name, value]

func _on_level_changed(level: int) -> void:
	label_level.text = "等级: %d" % level

func _on_ending_triggered(ending_id: String) -> void:
	var desc := ending_id
	if ending_id == "player_win":
		desc = "player_win（玩家胜：细胞数>50）"
	elif ending_id == "draw":
		desc = "draw（平局：时间>60秒）"
	label_ending.text = "结局: %s" % desc

func _on_game_state_changed(state: String) -> void:
	label_state.text = "状态: %s" % state
