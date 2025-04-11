# UImanager.gd 示例
extends CanvasLayer  # 或者你也可以挂在 Panel 上

@export var instructions_label: Label

func show_instructions(text: String) -> void:
	instructions_label.text = text
	# 同时将整个 UI 显示出来
	self.visible = true

func hide_instructions() -> void:
	self.visible = false
