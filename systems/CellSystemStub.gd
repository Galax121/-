extends "res://core/ICellSystem.gd"
## 细胞系统占位实现（副程 A 的抄作业样板）。
## 作用：模拟细胞自动增殖，细胞数变化时广播 cell_count_changed。
## 接口方法 spawn_cell / kill_cell / damage_cell 在此已有最简实现，
## 真实系统把这三个函数体换成自己的逻辑即可，函数名和参数不许改。

# 当前细胞总数
var cell_count: int = 1
# 每秒平均增长多少个细胞（会按等级上调：等级1 ≈ 基础数×1/30，等级30 ≈ ×1）
# 配合 MAX_LEVEL=30 与 growth_per_sec_full，让分裂真正成为高等级后的爆发
var base_growth: float = 0.22
const MAX_GROWTH_MULT: float = 1.0  # 30级时的增殖倍数（相对 base_growth）
var _current_growth: float = 0.0

# 小数累加器，避免每帧都只能加整数
var _accum: float = 0.0

# 初始化：重置为 1 个细胞，并广播一次
func init() -> void:
	cell_count = 1
	_accum = 0.0
	print("[CellSystemStub] init，初始细胞数 = 1")
	EventBus.cell_count_changed.emit(cell_count)

# 每帧调用：按等级系数增殖，等级越高分裂越快。
# 系数：lv/30，30级才到满档，前期几乎不增殖，逼你冲高等级
func tick(delta: float) -> void:
	var lvl: int = 1
	if GameManager != null and GameManager.skill_system != null:
		lvl = int(GameManager.skill_system.get("level"))
	var mult: float = clampf(float(lvl) / 30.0, 0.03, 1.0)  # 最低3%不至于完全停住
	_current_growth = base_growth * mult
	_accum += delta * _current_growth
	if _accum >= 1.0:
		spawn_cell(int(_accum))
		_accum -= float(int(_accum))

# 接口实现：生成 count 个细胞
func spawn_cell(count: int = 1) -> void:
	cell_count += maxi(count, 0)
	print("[CellSystemStub] 生成 +%d，当前 = %d" % [count, cell_count])
	EventBus.cell_count_changed.emit(cell_count)

# 接口实现：死亡 count 个细胞，不低于 0
func kill_cell(count: int = 1) -> void:
	cell_count = maxi(cell_count - maxi(count, 0), 0)
	print("[CellSystemStub] 死亡 -%d，当前 = %d" % [count, cell_count])
	EventBus.cell_count_changed.emit(cell_count)

# 接口实现：受伤按 amount 向上取整扣细胞
func damage_cell(amount: float) -> void:
	var loss: int = int(ceil(amount))
	print("[CellSystemStub] 受伤 %.1f，折算死亡 %d" % [amount, loss])
	kill_cell(loss)
