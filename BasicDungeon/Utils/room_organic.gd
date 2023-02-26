extends BasicRoom
class_name BasicRoomOrganic


const FACTOR := 1.0 / 8.0

var _data: Array
var _data_size: int


func _init(new_rect: Rect2) -> void:
	super(new_rect)
	pass


func _iter_get(_arg) -> Vector2:
	return _data[_iter_index]


func update(new_rect: Rect2) -> void:
	super(new_rect)
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var unit := FACTOR * new_rect.size
	var order := [
		new_rect.grow_individual(-unit.x, 0, -unit.x, unit.y - new_rect.size.y),
		new_rect.grow_individual(unit.x - new_rect.size.x, -unit.y, 0, -unit.y),
		new_rect.grow_individual(-unit.x, unit.y - new_rect.size.y, -unit.x, 0),
		new_rect.grow_individual(0, -unit.y, unit.x - new_rect.size.x, -unit.y)
	]
	var poly = []
	for index in range(order.size()):
		var rect_current: Rect2 = order[index]
		var is_even := index % 2 == 0
		var poly_partial := []
		for r in range(rng.randi_range(1, 2)):
			poly_partial.push_back(Vector2(
				rng.randf_range(rect_current.position.x, rect_current.end.x),
				rng.randf_range(rect_current.position.y, rect_current.end.y)
			))
		poly_partial.sort_custom(func(a, b): return BasicUtils.lessv_x(a, b) if is_even else BasicUtils.lessv_y(a, b))
		if index > 1:
			poly_partial.reverse()
		poly += poly_partial

	_data = []
	for x in range(new_rect.position.x, new_rect.end.x):
		for y in range(new_rect.position.y, new_rect.end.y):
			var point := Vector2(x, y)
			if Geometry2D.is_point_in_polygon(point, poly):
				_data.push_back(point)
	_data_size = _data.size()


func _iter_is_running() -> bool:
	return _iter_index < _data_size
