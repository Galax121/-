extends "res://core/SystemBase.gd"
## 结局系统占位实现。
## 作用：只做判定，被 GameManager 每帧调用，返回 "" 继续，否则返回结局 id。
var win_cell_count: int = 50
var draw_time: float = 60.0

func init() -> void:
	print("[EndingSystemStub] init，胜利：细胞数 > %d，平局：时间 > %.1f 秒" % [win_cell_count, draw_time])

func tick(_delta: float) -> void:
	pass

func check_ending(cell_count: int, elapsed: float) -> String:
	if cell_count > win_cell_count:
		return "player_win"
	if elapsed > draw_time:
		return "draw"
	return ""
