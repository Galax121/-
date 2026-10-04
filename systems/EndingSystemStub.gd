extends "res://core/SystemBase.gd"
## 结局系统占位实现：只做判定，不存数据。
## GameManager 每帧调用 check_ending()，返回 "" 表示无结局，返回非空表示结局 id。
## 目前只有一种胜利：我方细胞数 > 50 即 player_win。

# 细胞数超过这个值则玩家胜利
var win_cell_count: int = 50

# 初始化：打印阈值，方便新手理解
func init() -> void:
	print("[EndingSystemStub] init，胜利条件：细胞数 > %d" % win_cell_count)

# 占位 tick：结局判定不需要每帧内部推进，留空即可
func tick(_delta: float) -> void:
	pass

# 结局判定函数，被 GameManager 每帧调用
# cell_count：当前细胞数，elapsed：从游戏开始经过的秒数（目前不用，留给以后）
# 返回值："" = 继续游戏，"player_win" = 玩家胜
func check_ending(cell_count: int, _elapsed: float) -> String:
	if cell_count > win_cell_count:
		return "player_win"
	return ""
