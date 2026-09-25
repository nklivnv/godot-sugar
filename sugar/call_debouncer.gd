extends RefCounted
class_name CallDebouncer


var _callable: Callable
var _requested: bool


static func create_with_signals(callable: Callable, request_signal: Signal, try_call_signal: Signal) -> CallDebouncer:
	var debouner := CallDebouncer.new(callable)
	request_signal.connect(debouner.request)
	try_call_signal.connect(debouner.try_call)
	return debouner


func _init(callable: Callable) -> void: _callable = callable

func request() -> void: _requested = true

func try_call(...args: Array) -> Variant:
	if not _requested: return null
	_requested = false
	return _callable.callv(args)
