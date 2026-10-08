extends Node

func _ready():
	# 1. 游戏一启动，主界面（空灵）音乐自动播放
	if not $主界面.playing:
		$主界面.play()
	
	# 2. 游戏界面（活泼）音乐静音待命
	if not $游戏界面.playing:
		$游戏界面.play()
	$游戏界面.volume_db = -80.0 # 最低音量（静音）

# 点击“开始”按钮时调用的函数
func play_upbeat_music():
	# 确保游戏界面音乐持续播放
	if not $游戏界面.playing:
		$游戏界面.play()
	
	# 使用 Tween 在 4 秒内，将游戏界面音乐从 -80dB 渐强到 -5dB
	var tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property($游戏界面, "volume_db", -5.0, 4.0)
	
	# 同时把主界面音乐慢慢压低
	var tween2 = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween2.tween_property($主界面, "volume_db", -100.0, 4.0)
