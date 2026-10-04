extends "res://core/ICellSystem.gd"
## 细胞系统占位实现（副程 A 的抄作业样板）。
## 作用：模拟细胞自动增殖，细胞数变化时广播 cell_count_changed。
## 接口方法 spawn_cell / kill_cell / damage_cell 在此已有最简实现，
## 真实系统把这三个函数体换成自己的逻辑即可，函数名和参数不许改。

# 当前细胞总数
var cell_count: int = 1
# 每秒平均增长多少个细胞（调小则全场变慢，胜利来得更晚）
var growth_per_sec: float = 1.5
# 小数累加器，避免每帧都只能加整数
var _accum: float = 0.0

# 初始化：重置为 1 个细胞，并广播一次
func init() -> void:
	cell_count = 1
	_accum = 0.0
	print("[CellSystemStub] init，初始细胞数 = 1")
	EventBus.cell_count_changed.emit(cell_count)

# 每帧调用：按 growth_per_sec 累加，满 1 个就真正增加
func tick(delta: float) -> void:
	_accum += delta * growth_per_sec
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
