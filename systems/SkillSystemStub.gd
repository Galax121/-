extends "res://core/SystemBase.gd"
## 技能/升级系统占位实现。
## 作用：模拟经验涨满自动升级，升级时广播 level_changed。
var level: int = 1
var exp: float = 0.0
var exp_to_next: float = 20.0
# 主控细胞最大等级：满级后不再涨经验
const MAX_LEVEL: int = 5

func init() -> void:
	level = 1
	exp = 0.0
	exp_to_next = 20.0
	print("[SkillSystemStub] init，初始等级 = 1")
	EventBus.level_changed.emit(level)

func tick(delta: float) -> void:
	if level >= MAX_LEVEL:
		return
	exp += delta * 8.0
	if exp >= exp_to_next:
		exp -= exp_to_next
		level += 1
		exp_to_next *= 1.5
		print("[SkillSystemStub] 升级！当前等级 = %d" % level)
		EventBus.level_changed.emit(level)
