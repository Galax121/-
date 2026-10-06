extends Node

func _ready():
	# 游戏一开始，两首音乐同时播放（但活泼层是静音的）
	$主界面.play()
	$游戏界面.play()
	$游戏界面.volume_db = -80.0

# 玩家每次升级时，调用这个函数
func update_music_layer(level: int):
	# 将 1级 到 20级 映射到 音量-80（静音） 到 音量-5（正常）
	var target_db = remap(level, 1, 20, -80.0, -5.0)
	target_db = clamp(target_db, -80.0, -5.0)
	
	print("音乐系统：当前等级 ", level, "，目标活泼层音量 ", target_db, "dB")
	
	# 使用 Tween 平滑过渡，千万不要瞬间切歌
	var tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property($游戏界面, "volume_db", target_db, 3.0) # 花3秒慢慢推上去
	
	# 把空灵层慢慢降下来
	var target_ambient_db = remap(level, 1, 20, -10.0, -25.0)
	var tween2 = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween2.tween_property($主界面, "volume_db", target_ambient_db, 3.0)
