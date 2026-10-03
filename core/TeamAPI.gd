class_name TeamAPI
extends RefCounted
## 团队接口契约文件（主程维护，副程只看不改）。
## 作用：一页纸说清三件事——谁在哪写、必须实现哪几个函数、用什么信号跟别人说话。
##
## 分工映射（只许改自己名下的文件）：
##   副程 A（细胞与战斗）：res://systems/CellSystem.gd、res://systems/EnemySystem.gd
##   副程 B（环境与成长）：res://systems/EnvironmentSystem.gd、res://systems/GrowthSystem.gd
##   副程 C（UI 与元系统）：res://main/ 下新建 Hud.gd、SkillPanel.gd、EndingScreen.gd
##   主程独占（谁都不许改）：autoload/EventBus.gd、autoload/GameManager.gd、
##     core/SystemBase.gd、core/TeamAPI.gd（本文件）、project.godot、main/Main.tscn 根节点
##
## 系统脚本三件套（A 和 B 的每个系统文件都必须照抄）：
##   extends "res://core/SystemBase.gd"   # 第一行，必须是这一句
##   func init() -> void                  # 开局调用一次，重置自己的数
##   func tick(delta: float) -> void      # 每帧调用一次，用 delta 推进
##
## 说话方式（不许直调别人的变量和函数，只能二选一）：
##   1. 广播：EventBus.cell_count_changed.emit(n) 等，UI 收到后自己更新
##   2. 读数：GameManager.get_cell_count()、get_level()、get_temperature()
##
## 信号字典（名字写死，拼错就收不到）：
##   cell_count_changed(count: int)   # A 发，C 收
##   env_changed(name: String, value: float)  # B 发，C 收，name 如 "temperature"
##   level_changed(level: int)         # B 发，C 收
##   ending_triggered(ending_id: String)  # 主程发，C 收，取值 "player_win" / "draw"
##   game_state_changed(state: String) # 主程发，C 收，取值 SELECT/GROW/ENV/ENEMY/END

# 副程真实系统写好后，主程用这一个函数整体换装，不用逐个调 set_*。
# 传 null 表示该位置继续用 Stub 占位。
static func install_all(cell_sys = null, env_sys = null, skill_sys = null, ending_sys = null) -> void:
	if cell_sys != null:
		assert_valid_system(cell_sys, "cell")
		GameManager.set_cell_system(cell_sys)
	if env_sys != null:
		assert_valid_system(env_sys, "environment")
		GameManager.set_environment_system(env_sys)
	if skill_sys != null:
		assert_valid_system(skill_sys, "skill")
		GameManager.set_skill_system(skill_sys)
	if ending_sys != null:
		assert_valid_system(ending_sys, "ending")
		GameManager.set_ending_system(ending_sys)

# 校验：是不是合格的系统（有 init 和 tick）。不合格直接报错停住，方便小白定位。
static func assert_valid_system(obj, tag: String) -> void:
	assert(obj != null, "[TeamAPI] %s 系统是 null，请先 .new() 再传入" % tag)
	assert(obj.has_method("init"), "[TeamAPI] %s 系统缺 init()，请照抄 Stub 补上" % tag)
	assert(obj.has_method("tick"), "[TeamAPI] %s 系统缺 tick(delta)，请照抄 Stub 补上" % tag)

# 只读查询：C 组 UI 开局拉一次初始值，避免满屏 "-"。
static func fetch_snapshot() -> Dictionary:
	return {
		"state": GameManager.state_to_string(GameManager.current_state),
		"cells": GameManager.get_cell_count(),
		"level": GameManager.get_level(),
		"temperature": GameManager.get_temperature(),
		"ending": GameManager.ending_id,
	}
