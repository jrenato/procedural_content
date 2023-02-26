class_name BasicRoom


var rect: Rect2

var position : Vector2 = Vector2.ZERO :
	set(value):
		pass
	get:
		return rect.position
var end : Vector2 = Vector2.ZERO :
	set(value):
		pass
	get:
		return rect.end
var center : Vector2 = Vector2.ZERO :
	set(value):
		pass
	get:
		return 0.5 * (rect.position + rect.end)

var _rect_area: float
var _iter_index: int


func _init(rect: Rect2) -> void:
	update(rect)


func update(rect: Rect2) -> void:
	self.rect = rect.abs()
	_rect_area = rect.get_area()


func _iter_init(_arg) -> bool:
	_iter_index = 0
	return _iter_is_running()


func _iter_next(_arg) -> bool:
	_iter_index += 1
	return _iter_is_running()


func _iter_get(_arg) -> Vector2:
	var offset := BasicUtils.index_to_xy(rect.size.x, _iter_index)
	return rect.position + offset


func _iter_is_running() -> bool:
	return _iter_index < _rect_area


func intersects(room: BasicRoom) -> bool:
	return rect.intersects(room.rect)


func get_position() -> Vector2:
	return rect.position


func get_end() -> Vector2:
	return rect.end


func get_center() -> Vector2:
	return 0.5 * (rect.position + rect.end)

