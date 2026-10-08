extends "res://core/SystemBase.gd"
## 技能/升级系统（经验值版）。
## 规则：吃经验升级，升级时广播 level_changed，最高 30 级。

# 当前等级（即主控等级）
var level: int = 1
# 主控细胞最大等级：满级后停住
const MAX_LEVEL: int = 30

# 当前经验值
var current_exp: float = 0.0
# 升下一级所需经验
var exp_to_next: float = 22.0

# 初始化：回到 1 级并广播一次
func init() -> void:
	level = 1
	current_exp = 0.0
	exp_to_next = get_exp_to_next_level()
	print("[SkillSystem] init，初始等级 = 1，升下一级所需经验 = %d" % exp_to_next)
	EventBus.level_changed.emit(level)

# 每帧调用：这里是测试用的自动加经验，正式接经验球时要把 add_exp 删掉！
func tick(delta: float) -> void:
	# ⚠️ 仅用于测试！每帧加10点经验，让你能立刻看到升级。
	# 正式接经验球或击杀逻辑的时候，务必把这行注释掉或删掉！
	add_exp(10.0 * delta)

# 核心公式：升下一级所需经验 (22 * 1.13^(lv-1))
func get_exp_to_next_level() -> float:
	return round(22.0 * pow(1.13, level - 1.0))

# 核心逻辑：增加经验并处理升级
func add_exp(amount: float) -> void:
	if level >= MAX_LEVEL:
		return
	current_exp += amount
	# 只要经验够了就升级（允许一次加大量经验连升多级）
	while current_exp >= get_exp_to_next_level() and level < MAX_LEVEL:
		current_exp -= get_exp_to_next_level()
		level += 1
		print("[SkillSystem] 升级！当前等级 = %d，下一级所需经验 = %d" % [level, get_exp_to_next_level()])
		EventBus.level_changed.emit(level)
	exp_to_next = get_exp_to_next_level()

# 只读：升级进度（当前经验, 升下一级所需经验），供 Main.gd 状态显示用
func get_upgrade_progress() -> Vector2:
	return Vector2(current_exp, exp_to_next)
