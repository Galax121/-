class_name ICellSystem
extends SystemBase
## 细胞系统接口（主程维护，副程只看不改）。
## 作用：规定“细胞”必须会哪几件事。副程 A 的真实细胞系统必须继承本文件，
## 并把下面三个方法全部重写。已有样板：res://systems/CellSystemStub.gd。
##
## 【副程实现步骤】共三步，不要改本文件：
##   1. 新建自己的文件，如 res://systems/CellSystem.gd，
##      第一行只写：extends "res://core/ICellSystem.gd"
##   2. 把下面 spawn_cell / kill_cell / damage_cell 三个函数原样抄过去，
##      删掉函数体里的 push_error，写进自己的真实逻辑。
##      init() 和 tick(delta) 照旧保留（从 SystemBase 继承来的规矩不变）。
##   3. 数量变了就广播：EventBus.cell_count_changed.emit(cell_count)
##      写完后把文件交给主程，主程用 TeamAPI.install_all() 换装。

# 生成 count 个细胞。占位实现直接报错，提醒子类必须重写。
func spawn_cell(count: int = 1) -> void:
	push_error("[ICellSystem] 子类必须重写 spawn_cell()")
	assert(false, "ICellSystem.spawn_cell 未实现")

# 死亡（移除）count 个细胞，数量不能小于 0。
func kill_cell(count: int = 1) -> void:
	push_error("[ICellSystem] 子类必须重写 kill_cell()")
	assert(false, "ICellSystem.kill_cell 未实现")

# 受伤：按 amount 扣减，掉多少细胞由实现自己定（占位约定：向上取整扣细胞）。
func damage_cell(amount: float) -> void:
	push_error("[ICellSystem] 子类必须重写 damage_cell()")
	assert(false, "ICellSystem.damage_cell 未实现")
