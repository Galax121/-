extends Node
## 全局事件总线（Autoload 单例）。
## 作用：只定义信号，不写逻辑，各系统用 emit 发送，UI 用 connect 订阅。
signal cell_count_changed(count: int)
signal env_changed(name: String, value: float)
signal level_changed(level: int)
signal ending_triggered(ending_id: String)
signal game_state_changed(state: String)
