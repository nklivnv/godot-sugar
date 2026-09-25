@abstract class_name OnceCaller extends Object # SingleCall, OnceCaller, CallDebouncer


static var _queue: Dictionary[Callable, bool]


static func call_deferred_once(callable: Callable) -> void:
	if callable in _queue: return
	_queue[callable] = true
	callable.call_deferred()
	erase.call_deferred(callable)


#static func request(callable: Callable) -> void: call_deferred_once(callable)
static func erase(callable: Callable) -> void: _queue.erase(callable)
static func clear() -> void: _queue.clear()
