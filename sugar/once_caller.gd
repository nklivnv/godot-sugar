@abstract class_name OnceCaller extends Object


static var _queue: Dictionary[Callable, bool]


static func _call_queue_and_clear() -> void:
	var batch := _queue
	_queue = {}
	for callable: Callable in batch:
		if callable.is_valid():
			callable.call()


static func call_deferred_once(callable: Callable, replace: bool = false) -> void:
	if not replace and callable in _queue: return
	if not _queue: _call_queue_and_clear.call_deferred()
	_queue[callable] = true


static func erase(callable: Callable) -> void: _queue.erase(callable)
static func clear() -> void: _queue.clear()
