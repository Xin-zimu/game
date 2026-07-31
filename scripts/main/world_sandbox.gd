extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")


func _ready() -> void:
	GameManager.current_state = GameManager.State.PLAYING
	GameManager.current_scene_path = GameManager.GAME_SCENE
	_build_world()
	LogManager.info("WorldSandbox", "V0.2.0 movement sandbox ready")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		GameManager.return_to_menu()


func _build_world() -> void:
	add_child(SandboxTerrain.new())
	_add_obstacle(Vector2(-350, -180), Vector2(180, 88), Color("66513a"))
	_add_obstacle(Vector2(110, -270), Vector2(120, 120), Color("3d6045"))
	_add_obstacle(Vector2(390, 130), Vector2(220, 70), Color("604b38"))
	_add_obstacle(Vector2(-540, 300), Vector2(90, 220), Color("355741"))
	_add_obstacle(Vector2(110, 390), Vector2(130, 95), Color("5b4e3e"))
	var player := PLAYER_SCENE.instantiate() as PlayerCharacter
	player.position = Vector2.ZERO
	add_child(player)
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	canvas.add_child(GameplayHud.new())
	canvas.add_child(DebugPanel.new())


func _add_obstacle(center: Vector2, size_value: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size_value
	collision.shape = shape
	body.add_child(collision)
	var visual := ObstacleVisual.new()
	visual.configure(size_value, color)
	body.add_child(visual)
	add_child(body)
