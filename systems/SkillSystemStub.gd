extends "res://core/SystemBase.gd"
## 技能/升级系统占位实现（主控等级）。
## 规则：每存活 40 秒升 1 级，最高 5 级，升级时广播 level_changed。

# 当前等级（即主控等级）
var level: int = 1
# 主控细胞最大等级：满级后停住
const MAX_LEVEL: int = 5
# 升一级要多少秒
const LEVEL_UP_TIME: float = 40.0
# 距上次升级过去的秒数
var _time: float = 0.0

# 初始化：回到 1 级并广播一次
func init() -> void:
	level = 1
	_time = 0.0
	print("[SkillSystemStub] init，初始等级 = 1")
	EventBus.level_changed.emit(level)

# 每帧调用：攒满 40 秒升 1 级
func tick(delta: float) -> void:
	if level >= MAX_LEVEL:
		return
	_time += delta
	if _time >= LEVEL_UP_TIME:
		_time -= LEVEL_UP_TIME
		level += 1
		print("[SkillSystemStub] 升级！当前等级 = %d" % level)
		EventBus.level_changed.emit(level)

# 只读：升级进度（已攒秒数, 满级所需秒数），供 Main.gd 状态显示用
func get_upgrade_progress() -> Vector2:
	return Vector2(_time, LEVEL_UP_TIME)
