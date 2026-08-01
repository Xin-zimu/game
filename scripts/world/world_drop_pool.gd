class_name WorldDropPool
extends Node2D

class DropVisual extends Node2D:
	var item_id: StringName = &""
	var quantity := 0
	var age := 0.0
	var active := false
	var base_position := Vector2.ZERO
	var color := Color.WHITE

	func activate(next_item_id: StringName, next_quantity: int, world_position: Vector2, next_color: Color) -> void:
		item_id = next_item_id
		quantity = next_quantity
		base_position = world_position
		position = world_position
		color = next_color
		age = 0.0
		active = true
		visible = true
		queue_redraw()

	func deactivate() -> void:
		active = false
		visible = false
		item_id = &""
		quantity = 0

	func tick(delta: float) -> void:
		if not active:
			return
		age += delta
		position = base_position + Vector2(0.0, sin(age * 5.5) * 2.0)

	func _draw() -> void:
		if not active:
			return
		var points := PackedVector2Array([Vector2(0, -7), Vector2(7, 0), Vector2(0, 7), Vector2(-7, 0)])
		draw_colored_polygon(points, color)
		draw_polyline(PackedVector2Array([Vector2(0, -7), Vector2(7, 0), Vector2(0, 7), Vector2(-7, 0), Vector2(0, -7)]), color.darkened(0.35), 2.0)
		for index in mini(quantity, 4):
			draw_rect(Rect2(Vector2(-5 + index * 3, 9), Vector2(2, 2)), color.lightened(0.25))


var _capacity := 32
var _catalog: ResourceCatalog
var _pool: Array[DropVisual] = []


func configure(capacity: int, catalog := ResourceCatalog.new()) -> void:
	_capacity = maxi(capacity, 1)
	_catalog = catalog


func _ready() -> void:
	z_index = 8
	if _catalog == null:
		_catalog = ResourceCatalog.new()
	for _index in _capacity:
		var visual := DropVisual.new()
		visual.visible = false
		add_child(visual)
		_pool.append(visual)


func _process(delta: float) -> void:
	for visual in _pool:
		visual.tick(delta)


func spawn_drop(item_id: StringName, quantity: int, world_position: Vector2) -> bool:
	if quantity <= 0:
		return false
	for visual in _pool:
		if not visual.active:
			visual.activate(item_id, quantity, world_position, _catalog.item_color(item_id))
			return true
	var merge_target: DropVisual
	var best_distance := INF
	for visual in _pool:
		if visual.item_id != item_id:
			continue
		var distance := visual.base_position.distance_squared_to(world_position)
		if distance < best_distance:
			best_distance = distance
			merge_target = visual
	if merge_target != null:
		merge_target.quantity += quantity
		merge_target.queue_redraw()
		return true
	return false


func collect_near(world_position: Vector2, radius: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var radius_squared := radius * radius
	for visual in _pool:
		if not visual.active or visual.age < 0.20:
			continue
		if visual.base_position.distance_squared_to(world_position) > radius_squared:
			continue
		result.append({"item_id": visual.item_id, "quantity": visual.quantity})
		visual.deactivate()
	return result


func active_count() -> int:
	var result := 0
	for visual in _pool:
		result += 1 if visual.active else 0
	return result


func capacity() -> int:
	return _capacity
