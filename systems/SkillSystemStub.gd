extends "res://core/SystemBase.gd"
## 主控经验与等级系统。经验只由经验球收集获得。

# 当前等级（即主控等级）
var level: int = 1
# 累计经验与当前等级内的经验进度
var total_experience: int = 0
var experience: int = 0
var exp_to_next: int = 22
const MAX_LEVEL: int = 30

func init() -> void:
	level = 1
	total_experience = 0
	experience = 0
	exp_to_next = xp_required_for_level(level)
	EventBus.level_changed.emit(level)
	EventBus.experience_changed.emit(total_experience, experience, exp_to_next)

static func xp_required_for_level(current_level: int) -> int:
	return roundi(22.0 * pow(1.13, float(maxi(current_level - 1, 0))))

func add_experience(amount: int) -> void:
	if amount <= 0 or level >= MAX_LEVEL:
		return
	var leveled_up := false
	total_experience += amount
	experience += amount
	while level < MAX_LEVEL and experience >= exp_to_next:
		experience -= exp_to_next
		level += 1
		EventBus.level_changed.emit(level)
		leveled_up = true
		exp_to_next = xp_required_for_level(level) if level < MAX_LEVEL else 0
	if level >= MAX_LEVEL:
		experience = 0
	if leveled_up:
		print("[SkillSystemStub] 升级！当前等级 = %d" % level)
	EventBus.experience_changed.emit(total_experience, experience, exp_to_next)

# 只读：返回当前等级内的经验和升到下一级所需经验，供经验条使用。
func get_upgrade_progress() -> Vector2:
	return Vector2(float(experience), float(exp_to_next))
