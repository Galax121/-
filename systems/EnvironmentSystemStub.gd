extends "res://core/IEnvironmentSystem.gd"
## 环境系统占位实现（副程 B 的抄作业样板）。
## 作用：模拟温度正弦波动，广播 env_changed("temperature", 温度)。
## 接口方法 set_temperature / get_temperature / apply_to_cells 在此已有最简实现，
## 真实系统把这三个函数体换成自己的逻辑即可，函数名和参数不许改。
## 注意：Stub 的 tick() 每帧会重算温度盖掉 set 的值，仅演示用，真实系统自己定。

# 当前温度
var temperature: float = 36.5
# 内部计时，用来算正弦波
var _time: float = 0.0

# 初始化：重置温度并广播一次
func init() -> void:
	_time = 0.0
	temperature = 36.5
	print("[EnvironmentSystemStub] init，初始温度 = 36.5")
	EventBus.env_changed.emit("temperature", temperature)

# 每帧调用：温度在 36.5 上下 +-5 度缓慢波动
func tick(delta: float) -> void:
	_time += delta
	temperature = 36.5 + 5.0 * sin(_time * 0.5)
	EventBus.env_changed.emit("temperature", temperature)

# 接口实现：设置温度并广播
func set_temperature(value: float) -> void:
	temperature = value
	EventBus.env_changed.emit("temperature", temperature)

# 接口实现：读取当前温度
func get_temperature() -> float:
	return temperature

# 接口实现：占位恒返回 1.0（环境正常），真实系统按温度/pH/毒素算倍率
func apply_to_cells(_cell_count: int) -> float:
	return 1.0
