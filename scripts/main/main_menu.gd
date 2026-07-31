extends Control

const COLOR_TEXT := Color("e7f5e5")
const COLOR_MUTED := Color("91a99a")
const COLOR_ACCENT := Color("f5c96a")

var _settings_panel: PanelContainer


func _ready() -> void:
	theme = UIThemeFactory.create_theme()
	_build_interface()
	LogManager.info("MainMenu", "Main menu ready")


func _build_interface() -> void:
	var backdrop := PixelBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 72)
	margin.add_theme_constant_override("margin_right", 72)
	margin.add_theme_constant_override("margin_top", 56)
	margin.add_theme_constant_override("margin_bottom", 48)
	add_child(margin)

	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 64)
	margin.add_child(layout)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 10)
	layout.add_child(copy)

	var eyebrow := Label.new()
	eyebrow.text = "A PROCEDURAL SURVIVAL ODYSSEY"
	eyebrow.add_theme_font_size_override("font_size", 15)
	eyebrow.add_theme_color_override("font_color", COLOR_ACCENT)
	copy.add_child(eyebrow)

	var title := Label.new()
	title.text = "无尽边境"
	title.add_theme_font_size_override("font_size", 74)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	copy.add_child(title)

	var english := Label.new()
	english.text = "INFINITE FRONTIER"
	english.add_theme_font_size_override("font_size", 25)
	english.add_theme_color_override("font_color", Color("66bd88"))
	copy.add_child(english)

	var description := Label.new()
	description.text = "每一粒种子，都是一片从未有人抵达的世界。\n探索、采集、生存——然后越过下一条地平线。"
	description.add_theme_font_size_override("font_size", 17)
	description.add_theme_color_override("font_color", COLOR_MUTED)
	description.add_theme_constant_override("line_spacing", 7)
	copy.add_child(description)

	var status := Label.new()
	status.text = "VERSION %s  ·  OFFLINE  ·  DETERMINISTIC" % GameVersion.VERSION
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", Color("6f8c7b"))
	copy.add_child(status)

	var menu_panel := PanelContainer.new()
	menu_panel.name = "MenuPanel"
	menu_panel.custom_minimum_size = Vector2(338, 0)
	menu_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu_panel.add_theme_stylebox_override("panel", _panel_style())
	layout.add_child(menu_panel)

	var menu_margin := MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", 32)
	menu_margin.add_theme_constant_override("margin_right", 32)
	menu_margin.add_theme_constant_override("margin_top", 34)
	menu_margin.add_theme_constant_override("margin_bottom", 34)
	menu_panel.add_child(menu_margin)

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 14)
	menu_margin.add_child(menu)

	var heading := Label.new()
	heading.text = "开始远征"
	heading.add_theme_font_size_override("font_size", 26)
	heading.add_theme_color_override("font_color", COLOR_TEXT)
	menu.add_child(heading)

	var subheading := Label.new()
	subheading.name = "VersionLabel"
	subheading.text = "工程基础版本"
	subheading.add_theme_color_override("font_color", COLOR_MUTED)
	menu.add_child(subheading)
	menu.add_child(HSeparator.new())

	menu.add_child(_make_button("新建世界", _on_new_game, true))
	var continue_button := _make_button("继续游戏", _on_continue_game)
	continue_button.disabled = true
	continue_button.tooltip_text = "首个存档将在 V0.7.0 开放"
	menu.add_child(continue_button)
	menu.add_child(_make_button("设置", _on_settings))
	menu.add_child(_make_button("退出", _on_quit))

	var footer := Label.new()
	footer.name = "OfflineFooter"
	footer.text = "完全本地运行 · 不连接 API · 不使用生成式 AI"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.custom_minimum_size = Vector2(0, 38)
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color("5c7366"))
	menu.add_child(footer)

	_settings_panel = _build_settings_panel()
	_settings_panel.visible = false
	add_child(_settings_panel)

	var debug_panel := DebugPanel.new()
	add_child(debug_panel)


func _make_button(label_text: String, callback: Callable, primary := false) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0, 52)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("07121d") if primary else COLOR_TEXT)
	button.add_theme_stylebox_override("normal", _button_style(Color("f5c96a") if primary else Color("173329")))
	button.add_theme_stylebox_override("hover", _button_style(Color("ffdc87") if primary else Color("24533e")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("d4a84f") if primary else Color("10271f")))
	button.add_theme_stylebox_override("disabled", _button_style(Color("15221f")))
	button.pressed.connect(callback)
	return button


func _build_settings_panel() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	overlay.position = Vector2(-235, -190)
	overlay.custom_minimum_size = Vector2(470, 380)
	overlay.add_theme_stylebox_override("panel", _panel_style(Color("0a171f")))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	overlay.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	var title := Label.new()
	title.text = "设置"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	column.add_child(title)
	column.add_child(_make_toggle("全屏显示", "video/fullscreen"))
	column.add_child(_make_toggle("垂直同步", "video/vsync"))
	column.add_child(_make_toggle("显示性能面板", "accessibility/show_fps"))
	var volume_label := Label.new()
	volume_label.text = "主音量"
	volume_label.add_theme_color_override("font_color", COLOR_MUTED)
	column.add_child(volume_label)
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = float(SettingsManager.get_value("audio/master_volume", 0.8))
	volume.value_changed.connect(func(value: float): SettingsManager.set_value("audio/master_volume", value))
	column.add_child(volume)
	column.add_spacer(false)
	column.add_child(_make_button("保存并返回", _close_settings, true))
	return overlay


func _make_toggle(label_text: String, setting_key: String) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.text = label_text
	toggle.button_pressed = bool(SettingsManager.get_value(setting_key, false))
	toggle.add_theme_font_size_override("font_size", 16)
	toggle.add_theme_color_override("font_color", COLOR_TEXT)
	toggle.toggled.connect(func(value: bool): SettingsManager.set_value(setting_key, value))
	return toggle


func _panel_style(color := Color("0b1b24e8")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("315a48")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 16
	return style


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.12)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _on_new_game() -> void:
	GameManager.start_new_game()


func _on_continue_game() -> void:
	EventBus.notify("存档功能将在 V0.7.0 开放")


func _on_settings() -> void:
	_settings_panel.visible = true


func _close_settings() -> void:
	SettingsManager.save_settings()
	_settings_panel.visible = false


func _on_quit() -> void:
	GameManager.quit_game()
