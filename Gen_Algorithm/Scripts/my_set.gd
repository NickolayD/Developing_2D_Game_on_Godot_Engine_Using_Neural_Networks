class_name MySet


var _data: Dictionary = {}


func add(nums: Variant) -> void:
	if nums is Array:
		for element in nums:
			_data[element] = true 
	else:
		_data[nums] = true


func get_length() -> int:
	return len(_data)


func remove(element) -> void:
	_data.erase(element)


func has(element: int) -> bool:
	return _data.has(element)


func to_array() -> Array:
	return _data.keys()


func _to_string() -> String:
	return str(_data.keys())
