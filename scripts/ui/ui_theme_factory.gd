class_name UIThemeFactory
extends RefCounted

const FONT_PATH := "res://assets/fonts/NotoSansCJKsc-ProjectSubset.otf"


static func create_theme() -> Theme:
	var result := Theme.new()
	var font := load(FONT_PATH) as Font
	if font != null:
		result.default_font = font
	result.default_font_size = 16
	return result
