# CellCombatStats.gd —— 细胞战斗数值（血量/经验/法力/攻击/防御）
# 只动 systems/ 下自己的新文件，不改别人的脚本
# 接入方式：Main.gd 持有主控份（CellCombatStats.new + init_main），每帧把等级/经验
# 只读镜像进来；法力是独立属性，目前无消耗，只展示。屏幕下方三条从它读
extends Node2D
class_name CellCombatStats

# ---------- 角色类型 ----------
enum Kind { MAIN, ALLY, ENEMY }
var kind: Kind = Kind.MAIN

# ---------- 血量 HP ----------
var max_hp: float = 100.0
var hp: float = 100.0

# ---------- 经验 EXP / 等级 ----------
var exp: float = 0.0
var level: int = 1
var exp_to_next: float = 22.0
var level_timer: float = 0.0

# ---------- 法力 MP（只有主控有）----------
var max_mp: float = 100.0
var mp: float = 100.0
var accelerating: bool = false  # 是否在加速

# ---------- 攻防 ----------
var atk: float = 10.0
var def_: float = 0.0

# ---------- 初始化 ----------
func init_main() -> void:
	kind = Kind.MAIN
	max_hp = 100.0
	hp = 100.0
	max_mp = 100.0
	mp = 100.0
	atk = 10.0
	def_ = 0.0
	level = 1
	exp = 0.0
	exp_to_next = 22.0

func init_ally() -> void:
	kind = Kind.ALLY
	max_hp = 30.0
	hp = 30.0
	max_mp = 0.0
	mp = 0.0
	atk = 5.0
	def_ = 0.0
	level = 1
	exp = 0.0
	exp_to_next = 22.0

func init_enemy() -> void:
	kind = Kind.ENEMY
	max_hp = 20.0
	hp = 20.0
	max_mp = 0.0
	mp = 0.0
	atk = 0.0      # 敌军 0，先占位不伤人
	def_ = 0.0
	level = 1
	exp = 0.0

# ---------- 加速开关（主控专用：每秒扣 30 MP）----------
func set_accelerating(on: bool) -> void:
	if kind != Kind.MAIN:
		return
	accelerating = on

# ---------- 受伤公式：max(伤害 - DEF, 1) ----------
func take_damage(amount: float) -> void:
	var real: float = max(amount - def_, 1.0)
	hp = max(hp - real, 0.0)
	# hp <= 0 时由外部判断死亡（kill_cell）

# ---------- 每帧更新（已停用）----------
# 注意：升级权威在 SkillSystemStub，体力在 Main.gd 管理，
# 这里不再自己跑，避免两套 pacing 打架。本对象只存数 + 提供受伤公式。
func _process(_delta: float) -> void:
	pass

# ---------- 升级属性成长 ----------
func apply_level_up() -> void:
	if kind == Kind.MAIN:
		def_ += 2.0
		if level >= 4:
			atk = 15.0
		else:
			atk = 10.0
		max_hp = 100.0
		hp = max_hp
	elif kind == Kind.ALLY:
		def_ += 1.0
		atk = 5.0
		max_hp = 30.0
		hp = max_hp
	# 敌军无升级
func _ready() -> void:
	init_main()
	print("主控细胞属性已启动，HP:", hp, " MP:", mp)
