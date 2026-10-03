class_name IEnvironmentSystem
extends SystemBase
## 环境系统接口（主程维护，副程只看不改）。
## 作用：规定“环境”必须会哪几件事。副程 B 的真实环境系统必须继承本文件，
## 并把下面三个方法全部重写。已有样板：res://systems/EnvironmentSystemStub.gd。
##
## 【副程实现步骤】共三步，不要改本文件：
##   1. 新建自己的文件，如 res://systems/EnvironmentSystem.gd，
##      第一行只写：extends "res://core/IEnvironmentSystem.gd"
##   2. 把下面 set_temperature / get_temperature / apply_to_cells 三个函数
##      原样抄过去，删掉函数体里的 push_error，写进自己的真实逻辑。
##      init() 和 tick(delta) 照旧保留（从 SystemBase 继承来的规矩不变）。
##   3. 温度变了就广播：EventBus.env_changed.emit("temperature", temperature)
##      写完后把文件交给主程，主程用 TeamAPI.install_all() 换装。

# 设置温度。占位实现直接报错，提醒子类必须重写。
func set_temperature(value: float) -> void:
	push_error("[IEnvironmentSystem] 子类必须重写 set_temperature()")
	assert(false, "IEnvironmentSystem.set_temperature 未实现")

# 读取当前温度。
func get_temperature() -> float:
	push_error("[IEnvironmentSystem] 子类必须重写 get_temperature()")
	assert(false, "IEnvironmentSystem.get_temperature 未实现")
	return 36.5

# 把环境对细胞的影响算成一个倍率返回（如 1.0 正常、0.5 减半、1.5 加速）。
# 副程 A 以后用这个倍率乘自己的生长速度。占位约定：恒返回 1.0。
func apply_to_cells(_cell_count: int) -> float:
	push_error("[IEnvironmentSystem] 子类必须重写 apply_to_cells()")
	assert(false, "IEnvironmentSystem.apply_to_cells 未实现")
	return 1.0
