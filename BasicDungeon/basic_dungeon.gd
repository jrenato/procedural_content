extends Node2D


@export var level_size : Vector2 = Vector2(100, 80)
# rooms_size.x = minimum size
# rooms_size.y = maximum size
@export var rooms_size : Vector2 = Vector2(10, 14)
@export var rooms_max : int = 15

@onready var camera: Camera2D = $Camera2D
@onready var level: TileMap = $Level

const FACTOR := 1.0 / 8.0


func _ready() -> void:
	_setup_camera()
	_generate()


func _setup_camera() -> void:
	camera.position = level.map_to_local(level_size / 2)
	var z : float = 1 / (max(level_size.x, level_size.y) / 8)
	camera.zoom = Vector2(z, z)
	print(camera.zoom)


func _generate() -> void:
	level.clear()
	for vector in BasicGenerator.generate(level_size, rooms_size, rooms_max):
		level.set_cell(
				0, # layer
				Vector2i(vector.x, vector.y), # coords
				0, # source_id
				Vector2i(0, 0), # atlas_coords
				0 # alternative_tile
			)
