extends Node2D

enum Type { SIDE, LR, LRB, LRT, LRTB }

const BOTTOM_OPENED := [Type.LRB, Type.LRTB]
const BOTTOM_CLOSED := [Type.LR, Type.LRT]

var room_size := Vector2.ZERO
var cell_size := Vector2.ZERO

var _rng := RandomNumberGenerator.new()


func _notification(what: int) -> void:
	if what == Node.NOTIFICATION_SCENE_INSTANTIATED:
		_rng.randomize()

		var room: TileMap = $Side.get_child(0)
		room_size = room.get_used_rect().size
		#cell_size = room.cell_size
		cell_size = Vector2(room.cell_quadrant_size, room.cell_quadrant_size)


func get_room_data(type: int) -> Array:
	var group: Node2D = get_child(type)
	var index := _rng.randi_range(0, group.get_child_count() - 1)
	var room: TileMap = group.get_child(index)

	var data := []
	for v in room.get_used_cells(0):
		#data.push_back({"offset": v, "cell": room.get_cellv(v)})
		data.push_back({"offset": v, "cell": room.get_cell_source_id(0, v)})
	return data
