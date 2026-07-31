class_name WorldSeed
extends RefCounted

const DEFAULT_TEXT := "无尽边境"
const _SEED_MASK := 0x7fffffffffffffff


static func from_text(seed_text: String) -> int:
	var normalized := seed_text.strip_edges()
	if normalized.is_empty():
		normalized = DEFAULT_TEXT
	if normalized.is_valid_int():
		return int(normalized)
	var context := HashingContext.new()
	var error := context.start(HashingContext.HASH_SHA256)
	if error != OK:
		push_error("Unable to initialize stable seed hash: %s" % error_string(error))
		return 0
	context.update(normalized.to_utf8_buffer())
	var digest := context.finish()
	var result := int(digest[0] & 0x7f)
	for index in range(1, 8):
		result = (result << 8) | int(digest[index])
	return result & _SEED_MASK


static func derive(world_seed: int, seed_domain: StringName, generation_version := GameVersion.GENERATION_VERSION) -> int:
	return from_text("%d|%s|generation:%d" % [world_seed, seed_domain, generation_version])


static func for_chunk(world_seed: int, layer: StringName, chunk: Vector2i, generation_type: StringName) -> int:
	return from_text("%d|%s|%d|%d|%s|generation:%d" % [
		world_seed,
		layer,
		chunk.x,
		chunk.y,
		generation_type,
		GameVersion.GENERATION_VERSION,
	])


static func to_noise_seed(seed_64: int) -> int:
	var folded := int((seed_64 ^ (seed_64 >> 32)) & 0x7fffffff)
	return folded if folded != 0 else 1
