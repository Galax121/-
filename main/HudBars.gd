extends CanvasLayer

@onready var hp_bar: ProgressBar = $HPBar
@onready var mp_bar: ProgressBar = $MPBar
@onready var level_label: Label = $LevelLabel
@onready var exp_label: Label = $ExpLabel

func _ready() -> void:
	# 血条
	hp_bar.position = Vector2(20, 20)
	hp_bar.size = Vector2(200, 20)
	hp_bar.show_percentage = false
	# 蓝条
	mp_bar.position = Vector2(20, 50)
	mp_bar.size = Vector2(200, 20)
	mp_bar.show_percentage = false
	# 等级
	level_label.position = Vector2(20, 80)
	# 经验
	exp_label.position = Vector2(20, 110)

func _process(_delta):
	var stats = get_tree().root.find_child("CellCombatStats", true, false)
	if stats == null:
		return
	hp_bar.max_value = stats.max_hp
	hp_bar.value = stats.hp
	mp_bar.max_value = stats.max_mp
	mp_bar.value = stats.mp
	level_label.text = "等级: %d" % stats.level
	exp_label.text = "经验: " + str(int(stats.exp))
