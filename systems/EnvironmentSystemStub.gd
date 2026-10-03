extends "res://core/SystemBase.gd"
## 环境系统占位实现。
## 作用：模拟温度正弦波动，广播 env_changed("temperature", 温度)。
var temperature: float = 36.5
var _time: float = 0.0

func init() -> void:
	_time = 0.0
	temperature = 36.5
	print("[EnvironmentSystemStub] init，初始温度 = 36.5")
	EventBus.env_changed.emit("temperature", temperature)

func tick(delta: float) -> void:
	_time += delta
	temperature = 36.5 + 5.0 * sin(_time * 0.5)
	EventBus.env_changed.emit("temperature", temperature)
