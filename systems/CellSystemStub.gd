extends "res://core/SystemBase.gd"
## 细胞系统占位实现。
## 作用：模拟细胞自动增殖，细胞数变化时广播 cell_count_changed。
var cell_count: int = 1
var growth_per_sec: float = 3.0
var _accum: float = 0.0

func init() -> void:
	cell_count = 1
	_accum = 0.0
	print("[CellSystemStub] init，初始细胞数 = 1")
	EventBus.cell_count_changed.emit(cell_count)

func tick(delta: float) -> void:
	_accum += delta * growth_per_sec
	if _accum >= 1.0:
		var gain: int = int(_accum)
		_accum -= float(gain)
		cell_count += gain
		print("[CellSystemStub] 增殖 +%d，当前 = %d" % [gain, cell_count])
		EventBus.cell_count_changed.emit(cell_count)
