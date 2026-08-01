class_name ChunkGenerationJob
extends RefCounted

var world_seed: int
var chunk_position: Vector2i
var result: ChunkData
var worker_task_id := -1


func _init(seed: int, coordinate: Vector2i) -> void:
	world_seed = seed
	chunk_position = coordinate


func execute() -> void:
	worker_task_id = WorkerThreadPool.get_caller_task_id()
	result = TerrainGenerator.new(world_seed).generate_chunk(chunk_position)
