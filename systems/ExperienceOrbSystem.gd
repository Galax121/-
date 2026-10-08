extends "res://core/SystemBase.gd"
## Configurable ambient experience-orb production and XP values for future enemy drops.
signal orb_spawn_requested(xp_value: int, is_resume_bonus: bool)

const XP_SMALL: int = 4
const XP_MEDIUM: int = 9
const XP_LARGE: int = 22
const XP_ELITE: int = 60
const XP_BOSS: int = 200

const TARGET_XP_PER_MINUTE: float = 525.0
const AMBIENT_ORB_XP: int = XP_LARGE

var _xp_accumulator: float = 0.0

func init() -> void:
	_xp_accumulator = 0.0

func tick(delta: float) -> void:
	_xp_accumulator += delta * TARGET_XP_PER_MINUTE / 60.0
	while _xp_accumulator >= float(AMBIENT_ORB_XP):
		_xp_accumulator -= float(AMBIENT_ORB_XP)
		orb_spawn_requested.emit(AMBIENT_ORB_XP, false)

func spawn_resume_bonus() -> void:
	orb_spawn_requested.emit(40, true)

func spawn_enemy_drop(enemy_size: String) -> void:
	var xp_value: int
	match enemy_size:
		"small":
			xp_value = XP_SMALL
		"medium":
			xp_value = XP_MEDIUM
		"large":
			xp_value = XP_LARGE
		"elite":
			xp_value = XP_ELITE
		"boss":
			xp_value = XP_BOSS
		_:
			push_warning("Unknown enemy size for XP drop: %s" % enemy_size)
			return
	orb_spawn_requested.emit(xp_value, false)
