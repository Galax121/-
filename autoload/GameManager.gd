extends Node
## 全局游戏管理器（Autoload，主程序入口）。
## 作用：1.管状态机 SELECT->GROW->ENV->ENEMY->END 2._process 推 tick 3.查结局 4.set_* 供替换
enum GameState { SELECT, GROW, ENV, ENEMY, END }

const CellSystemScript: GDScript = preload("res://systems/CellSystemStub.gd")
const EnvironmentSystemScript: GDScript = preload("res://systems/EnvironmentSystemStub.gd")
const SkillSystemScript: GDScript = preload("res://systems/SkillSystemStub.gd")
const EndingSystemScript: GDScript = preload("res://systems/EndingSystemStub.gd")

var current_state: int = GameState.SELECT
var elapsed: float = 0.0
var state_timer: float = 0.0
var ending_id: String = ""
# 是否已点开始：没点之前停在菜单界面，_process 不推进
var started: bool = false

# 不写类型，方便以后替换成真实系统
var cell_system = null
var environment_system = null
var skill_system = null
var ending_system = null

func _ready() -> void:
	if cell_system == null:
		cell_system = CellSystemScript.new()
	if environment_system == null:
		environment_system = EnvironmentSystemScript.new()
	if skill_system == null:
		skill_system = SkillSystemScript.new()
	if ending_system == null:
		ending_system = EndingSystemScript.new()
	cell_system.init()
	environment_system.init()
	skill_system.init()
	ending_system.init()
	_change_state(GameState.SELECT)
	print("[GameManager] 游戏启动，当前状态 = SELECT（自动选细胞）")

func _process(delta: float) -> void:
	# 没点开始就不跑，停在菜单界面
	if not started:
		return
	if current_state == GameState.END:
		return
	elapsed += delta
	state_timer += delta
	_tick_current(delta)
	if _check_ending():
		return
	_update_state_flow()

func _tick_current(delta: float) -> void:
	match current_state:
		GameState.SELECT:
			pass
		GameState.GROW:
			cell_system.tick(delta)
			skill_system.tick(delta)
		GameState.ENV:
			cell_system.tick(delta)
			skill_system.tick(delta)
			environment_system.tick(delta)
		GameState.ENEMY:
			cell_system.tick(delta)
			skill_system.tick(delta)
			environment_system.tick(delta)
			print("[GameManager] 敌人出现（占位）... 当前细胞数 = %d" % get_cell_count())

func _update_state_flow() -> void:
	match current_state:
		GameState.SELECT:
			if state_timer >= 2.0:
				print("[GameManager] 自动选择细胞完成，进入 GROW")
				_change_state(GameState.GROW)
		GameState.GROW:
			if get_cell_count() >= 10 or state_timer >= 10.0:
				print("[GameManager] 成长阶段完成，进入 ENV")
				_change_state(GameState.ENV)
		GameState.ENV:
			if state_timer >= 10.0:
				print("[GameManager] 环境变化完成，进入 ENEMY")
				_change_state(GameState.ENEMY)
		GameState.ENEMY:
			if state_timer >= 15.0:
				if get_cell_count() > 30:
					_trigger_ending("player_win")
				else:
					_trigger_ending("draw")

func _check_ending() -> bool:
	if ending_system != null and ending_system.has_method("check_ending"):
		var result: String = ending_system.check_ending(get_cell_count(), elapsed)
		if result != "":
			_trigger_ending(result)
			return true
	return false

func _change_state(new_state: int) -> void:
	current_state = new_state
	state_timer = 0.0
	var state_name: String = state_to_string(new_state)
	print("[GameManager] 状态切换 -> %s" % state_name)
	EventBus.game_state_changed.emit(state_name)

func _trigger_ending(id: String) -> void:
	if current_state == GameState.END:
		return
	ending_id = id
	print("[GameManager] 结局触发：%s" % id)
	EventBus.ending_triggered.emit(id)
	_change_state(GameState.END)

# 从菜单点“开始”后调用：重置所有系统并开始推进，支持重开一局
func start_game() -> void:
	cell_system.init()
	environment_system.init()
	skill_system.init()
	ending_system.init()
	elapsed = 0.0
	ending_id = ""
	started = true
	_change_state(GameState.SELECT)
	print("[GameManager] 玩家点开始，进入游戏")

# 退出到菜单：停住推进，画面由 Main.gd 藏起来
func stop_to_menu() -> void:
	started = false
	print("[GameManager] 退出到菜单，模拟暂停")

func state_to_string(state: int) -> String:
	match state:
		GameState.SELECT:
			return "SELECT"
		GameState.GROW:
			return "GROW"
		GameState.ENV:
			return "ENV"
		GameState.ENEMY:
			return "ENEMY"
		GameState.END:
			return "END"
	return "UNKNOWN"

# 替换接口：以后有真实系统时调用注入
func set_cell_system(system) -> void:
	cell_system = system

func set_environment_system(system) -> void:
	environment_system = system

func set_skill_system(system) -> void:
	skill_system = system

func set_ending_system(system) -> void:
	ending_system = system

# 只读接口：供 Main.gd 显示和结局判定用
func get_cell_count() -> int:
	if cell_system != null:
		var v = cell_system.get("cell_count")
		if v != null:
			return int(v)
	return 0

func get_level() -> int:
	if skill_system != null:
		var v = skill_system.get("level")
		if v != null:
			return int(v)
	return 1

func get_temperature() -> float:
	if environment_system != null:
		var v = environment_system.get("temperature")
		if v != null:
			return float(v)
	return 36.5
