extends Node2D


func _ready() -> void:
	_build_placeholder_world()
	LogManager.info("GameShell", "Game shell ready")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		GameManager.return_to_menu()


func _build_placeholder_world() -> void:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.theme = UIThemeFactory.create_theme()
	var background := ColorRect.new()
	background.color = Color("102a2d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	canvas.add_child(screen)
	screen.add_child(background)
	var center := VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.position = Vector2(-300, -130)
	center.custom_minimum_size = Vector2(600, 260)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	screen.add_child(center)
	var title := Label.new()
	title.text = "远征准备完成"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("e7f5e5"))
	center.add_child(title)
	var copy := Label.new()
	copy.text = "V0.1.0 已建立稳定工程骨架。\n玩家与摄像机将在 V0.2.0 进入世界。"
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_theme_font_size_override("font_size", 18)
	copy.add_theme_color_override("font_color", Color("91a99a"))
	center.add_child(copy)
	var button := Button.new()
	button.text = "返回主菜单  [Esc]"
	button.custom_minimum_size = Vector2(260, 50)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(GameManager.return_to_menu)
	center.add_child(button)
	screen.add_child(DebugPanel.new())
