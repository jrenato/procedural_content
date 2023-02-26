extends Node2D
class_name MSTDungeon

# Emitted when all the rooms stabilized.
signal rooms_placed

const Room : PackedScene = preload("res://MSTDungeon/Utils/mst_room.tscn")

# Maximum number of generated rooms.
@export var max_rooms := 60
# Controls the number of paths we add to the dungeon after generating it,
# limiting player backtracking.
@export var reconnection_factor := 0.025

var _rng := RandomNumberGenerator.new()
var _data := {}
var _path: AStar2D = null
var _sleeping_rooms := 0
var _mean_room_size := Vector2.ZERO

@onready var rooms: Node2D = $Rooms
@onready var level: TileMap = $Level


func _ready() -> void:
	#	await(self, "rooms_placed")
	connect("rooms_placed", _rooms_placed)
	_rng.randomize()
	_generate()


# This is for visual feedback. We just re-render the rooms every frame.
func _process(_delta: float) -> void:
	level.clear()
	for room in rooms.get_children():
		for offset in room as MSTRoom:
			level.set_cell(
				0, # layer
				Vector2i(offset.x, offset.y), # coords
				0, # source_id
				Vector2i(0, 0), # atlas_coords
				0 # alternative_tile
			)


# Places the rooms and starts the physics simulation. Once the simulation is done
# ("rooms_placed" gets emitted), it continues by assigning tiles in the Level node.
func _generate() -> void:
	# Generate `max_rooms` rooms and set them up
	for _i in range(max_rooms):
		var room : MSTRoom = Room.instantiate()
		#room.connect("sleeping_state_changed", _on_Room_sleeping_state_changed)
		#room.sleeping_state_changed.connect(_on_Room_sleeping_state_changed)
		room.dungeon = self
		room.setup(_rng, level)
		rooms.add_child(room)

		_mean_room_size += room.size
	_mean_room_size /= rooms.get_child_count()
	# Wait for all rooms to be positioned in the game world.
#	await(self, "rooms_placed")


func _rooms_placed() -> void:
	rooms.queue_free()
	# Draws the tiles on the `level` tilemap.
	level.clear()
	for point in _data:
		level.set_cellv(point, 0)


func _is_main_room(room: MSTRoom) -> bool:
	return room.size.x > _mean_room_size.x and room.size.y > _mean_room_size.y


# Adds room tile positions to `_data`.
func _add_room(room: MSTRoom) -> void:
	for offset in room:
		_data[offset] = null


# Adds both secondary room and corridor tile positions to `_data`. Secondary rooms are the ones
# intersecting the corridors.
func _add_corridors():
	# Stores existing connections in its keys.
	var connected := {}

	# Checks if points are connected by a corridor. If not, adds a corridor.
	for point1_id in _path.get_points():
		for point2_id in _path.get_point_connections(point1_id):
			var point1 := _path.get_point_position(point1_id)
			var point2 := _path.get_point_position(point2_id)
			if Vector2(point1_id, point2_id) in connected:
				continue

			point1 = level.world_to_map(point1)
			point2 = level.world_to_map(point2)
			_add_corridor(point1.x, point2.x, point1.y, Vector2.AXIS_X)
			_add_corridor(point1.y, point2.y, point2.x, Vector2.AXIS_Y)

			# Stores the connection between point 1 and 2.
			connected[Vector2(point1_id, point2_id)] = null
			connected[Vector2(point2_id, point1_id)] = null


# Adds a specific corridor (defined by the input parameters) to `_data`. It also adds all
# secondary rooms intersecting the corridor path.
func _add_corridor(start: int, end: int, constant: int, axis: int) -> void:
	var t : int = min(start, end)
	while t <= max(start, end):
		var point := Vector2.ZERO
		match axis:
			Vector2.AXIS_X:
				point = Vector2(t, constant)
			Vector2.AXIS_Y:
				point = Vector2(constant, t)

		t += 1
		for room in rooms.get_children():
			if _is_main_room(room):
				continue

			var top_left: Vector2 = level.world_to_map(room.position - room.size / 2)
			var bottom_right: Vector2 = level.world_to_map(room.position + room.size / 2)
			if (
				top_left.x <= point.x
				and point.x < bottom_right.x
				and top_left.y <= point.y
				and point.y < bottom_right.y
			):
				_add_room(room)
				t = bottom_right[axis]
		_data[point] = null


# Once all rooms have stabilized it calcualtes a playable dungeon `_path` using the MST
# algorithm. Based on the calculated `_path`, it populates `_data` with room and corridor tile
# positions.
#
# It emits the "rooms_placed" signal when it finishes so we can begin the tileset placement.
func notify_sleeping_room() -> void:
	_sleeping_rooms += 1
	if _sleeping_rooms < max_rooms:
		return

	var main_rooms := []
	var main_rooms_positions := []
	for room in rooms.get_children():
		if _is_main_room(room):
			main_rooms.push_back(room)
			main_rooms_positions.push_back(room.position)

	_path = MSTUtils.mst(main_rooms_positions)

	for point1_id in _path.get_point_ids():
		for point2_id in _path.get_point_ids():
			if (
				point1_id != point2_id
				and not _path.are_points_connected(point1_id, point2_id)
				and _rng.randf() < reconnection_factor
			):
				_path.connect_points(point1_id, point2_id)

	for room in main_rooms:
		_add_room(room)
	_add_corridors()

	set_process(false)
	emit_signal("rooms_placed")
