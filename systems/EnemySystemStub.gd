extends "res://core/ICellSystem.gd"
## 敌方细胞系统占位实现（以后副程 A 接手做真 AI 时重写这里）。
## 规则：
## 1. 主控3级时 GameManager 调 activate()，之前 tick 什么都不干。
## 2. 增殖速度与我方相同（growth_per_sec 两边保持一致）。
## 3. 主控4级时 GameManager 调 set_hunt(true)，移速提到与我方主控相同并围堵。
## 4. 数量无上限；任何一方胜利（END）后 GameManager 停 tick，自然停止增殖。

# 当前敌军总数
var enemy_count: int = 0
# 与 CellSystemStub.growth_per_sec 保持一致
var growth_per_sec: float = 1.5
# 是否已登场 / 是否围堵中
var active: bool = false
var hunting: bool = false
# 慢速（游荡，比主控慢）；快速（围堵，与主控普速相同）
var slow_speed: float = 30.0
var fast_speed: float = 45.0
# 小数累加器
var _accum: float = 0.0

# 初始化：清零待命，并广播一次
func init() -> void:
	enemy_count = 0
	_accum = 0.0
	growth_per_sec = 1.5
	active = false
	hunting = false
	print("[EnemySystemStub] init，等待主控3级激活")
	EventBus.enemy_count_changed.emit(enemy_count)

# 每帧调用：没激活直接返回；激活后按增殖速度累加
func tick(delta: float) -> void:
	if not active:
		return
	_accum += delta * growth_per_sec
	if _accum >= 1.0:
		var gain: int = int(_accum)
		_accum -= float(gain)
		spawn_cell(gain)

# 主控3级时由 GameManager 调用，敌军登场（慢速游荡）
func activate() -> void:
	if active:
		return
	active = true
	print("[EnemySystemStub] 敌方出现（慢速游荡）")

# 主控4级时由 GameManager 调用：移速提到围堵档，增殖速度显著增加
func set_hunt(on: bool = true) -> void:
	hunting = on
	if hunting:
		growth_per_sec = 4.0
		print("[EnemySystemStub] 敌方加速围堵，增殖提速！")

# 当前移速：Main.gd 画面每帧读这个走
func current_speed() -> float:
	return fast_speed if hunting else slow_speed

# 接口实现：生成 count 个敌军
func spawn_cell(count: int = 1) -> void:
	enemy_count += maxi(count, 0)
	EventBus.enemy_count_changed.emit(enemy_count)

# 接口实现：阵亡 count 个敌军，不低于 0
func kill_cell(count: int = 1) -> void:
	enemy_count = maxi(enemy_count - maxi(count, 0), 0)
	EventBus.enemy_count_changed.emit(enemy_count)

# 接口实现：受伤按 amount 向上取整扣敌军
func damage_cell(amount: float) -> void:
	kill_cell(int(ceil(amount)))
