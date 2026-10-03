extends "res://core/IEventBus.gd"
## 全局事件总线（Autoload 单例）。
## 信号定义全部在父接口 res://core/IEventBus.gd 里，这里不重复写。
## 全项目统一用 EventBus.xxx.emit() 发送、EventBus.xxx.connect() 订阅。
## 要加新信号时改父接口文件，不要改这里。
