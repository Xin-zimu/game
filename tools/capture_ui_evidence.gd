extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var output_path := ""
	var requested_size := Vector2i(1280, 720)
	var fullscreen := false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-output="):
			output_path = argument.trim_prefix("--evidence-output=")
		elif argument.begins_with("--evidence-size="):
			var parts := argument.trim_prefix("--evidence-size=").split("x")
			if parts.size() == 2:
				requested_size = Vector2i(int(parts[0]), int(parts[1]))
		elif argument == "--evidence-fullscreen":
			fullscreen = true
	if output_path.is_empty() or requested_size.x < 1280 or requested_size.y < 720:
		printerr("Usage: --evidence-output=<path> --evidence-size=<width>x<height>")
		quit(2)
		return
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(requested_size)
	var scene := (load("res://scenes/main/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await create_timer(1.5).timeout
	var event_bus := root.get_node_or_null("EventBus")
	if event_bus != null:
		event_bus.emit_signal("resource_prompt_changed", "[E] 采集树木 · 耐久 3")
	await process_frame
	RenderingServer.force_draw(false)
	await process_frame
	var image := root.get_texture().get_image()
	if image.is_empty():
		printerr("Viewport capture returned an empty image")
		quit(3)
		return
	var absolute_output := ProjectSettings.globalize_path(output_path)
	var error := image.save_png(absolute_output)
	if error != OK:
		printerr("Could not save UI evidence to %s: %s" % [absolute_output, error_string(error)])
		quit(4)
		return
	print("Saved %dx%d UI evidence: %s" % [image.get_width(), image.get_height(), absolute_output])
	scene.queue_free()
	await process_frame
	quit(0)
