class_name IEventBus
extends Node
## 全局事件总线接口（主程维护，副程只看不改）。
## 作用：全项目所有信号的唯一集合。真正的 Autoload 单例是
## res://autoload/EventBus.gd，它继承本文件，所以信号全部可用。
##
## 【副程引用方式】不要改本文件，用法只有两行：
##   发送：EventBus.cell_count_changed.emit(123)
##   订阅：EventBus.cell_count_changed.connect(_on_cell_count_changed)
## 想加新信号时先找主程，主程改好本文件后通知全队。

# 细胞数量变化时发出，参数为当前细胞总数（副程 A 发，副程 C 收）
signal cell_count_changed(count: int)
# 环境值变化时发出，name 如 "temperature"，value 为具体数值（副程 B 发，副程 C 收）
signal env_changed(name: String, value: float)
# 等级变化时发出，参数为当前等级（副程 B 发，副程 C 收）
signal level_changed(level: int)
# 主控经验变化时发出（累计经验、当前等级内经验、下一级所需经验）
signal experience_changed(total_experience: int, experience: int, exp_to_next: int)
# 请求在游戏画面生成经验球；XP 只在玩家收集该球时入账
signal experience_orb_spawn_requested(xp_value: int, is_resume_bonus: bool)
# 结局触发时发出，参数为结局 id，目前只有 "player_win"（主程发，副程 C 收）
signal ending_triggered(ending_id: String)
# 游戏状态机变化时发出，参数为状态名字符串（主程发，副程 C 收）
signal game_state_changed(state: String)
# 敌军数量变化时发出（敌方系统发，Main 收，主控3级登场后才有）
signal enemy_count_changed(count: int)
