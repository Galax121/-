extends CanvasLayer

@onready var label: Label = $HpLabel

func _ready() -> void:
	label.position = Vector2(20, 20)

func _process(_delta) -> void:
	var stats = get_tree().root.find_child("CellCombatStats", true, false)
	if stats == null:
		return
	label.text = "血量: %.0f / %.0f" % [stats.hp, stats.max_hp]
