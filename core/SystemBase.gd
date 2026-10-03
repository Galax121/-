class_name SystemBase
extends RefCounted
## 所有游戏系统的基类。
## 作用：统一接口，GameManager 只调用 init() 和 tick(delta)。
## Stub 继承它，以后换真实系统时接口不变。
func init() -> void:
	pass

func tick(_delta: float) -> void:
	pass
