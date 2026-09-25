@abstract class_name SignalTools extends Object


# --- Object: ---


static func object_connect(object: Object, signal_name: StringName, callback: Callable, flags: ConnectFlags = 0) -> void:
	if object and object.has_signal(signal_name) and not object.is_connected(signal_name, callback):
		object.connect(signal_name, callback, flags)


static func object_disconnect(object: Object, signal_name: StringName, callback: Callable) -> void:
	if object and object.has_signal(signal_name) and  object.is_connected(signal_name, callback):
		object.disconnect(signal_name, callback)


static func object_reconnect(object: Object, signal_name: StringName, callback: Callable, flags: ConnectFlags = 0) -> void:
	object_swap(object, object, signal_name, callback)


static func object_set_enabled(object: Object, signal_name: StringName, callback: Callable, active: bool, flags: ConnectFlags = 0) -> void:
	if active: object_connect(object, signal_name, callback, flags)
	else: object_disconnect(object, signal_name, callback)


static func object_swap(old: Object, new: Object, signal_name: StringName, callback: Callable, flags: ConnectFlags = 0) -> void:
	object_disconnect(old, signal_name, callback)
	object_connect(new, signal_name, callback, flags)


# --- Object Arrays: ---


static func objects_connect(objects: Array, signal_name: StringName, callback: Callable, flags: ConnectFlags = 0) -> void:
	for object: Object in objects: object_connect(object, signal_name, callback, flags)


static func objects_disconnect(objects: Array, signal_name: StringName, callback: Callable) -> void:
	for object: Object in objects: object_disconnect(object, signal_name, callback)


static func objects_swap(old_objects: Array, new_objects: Array, signal_name: StringName, callback: Callable, flags: ConnectFlags = 0) -> void:
	objects_disconnect(old_objects, signal_name, callback)
	objects_connect(new_objects, signal_name, callback, flags)


# --- Signal: ---


static func signal_connect(signal_: Signal, callback: Callable, flags: ConnectFlags = 0) -> void:
	if not signal_.is_null() and not signal_.is_connected(callback): signal_.connect(callback, flags)


static func signal_disconnect(signal_: Signal, callback: Callable) -> void:
	if not signal_.is_null() and signal_.is_connected(callback): signal_.disconnect(callback)


static func signal_reconnect(signal_: Signal, callback: Callable, flags: ConnectFlags = 0) -> void:
	signal_swap(signal_, signal_, callback, flags)


static func signal_set_enabled(signal_: Signal, callback: Callable, active: bool, flags: ConnectFlags = 0) -> void:
	if active: signal_connect(signal_, callback, flags)
	else: signal_disconnect(signal_, callback)


static func signal_swap(old: Signal, new: Signal, callback: Callable, flags: ConnectFlags = 0) -> void:
	signal_disconnect(old, callback)
	signal_connect(new, callback, flags)


static func signal_custom(signal_a: Signal, signal_b: Signal, a_callback: Callable, b_callback: Callable, active_b: bool = true, a_flags: ConnectFlags = 0, b_flags: ConnectFlags = 0) -> void:
	if active_b:
		signal_disconnect(signal_a, a_callback)
		signal_connect(signal_b, b_callback, a_flags)
	else:
		signal_disconnect(signal_b, b_callback)
		signal_connect(signal_a, a_callback, b_flags)


# --- Callable: ---
#
#
#static func callback_toggle_object(callback: Callable, a: Object, b: Object, signal_name: StringName, flags: ConnectFlags = 0, active_b: bool = true) -> void:
	#object_disconnect(a if active_b else b, signal_name, callback)
	#object_connect(a if active_b else b, signal_name, callback, flags)
#
#
##static func callback_toggle_signal(signal_a: Signal, signal_b: Signal, callback: Callable, flags: ConnectFlags = 0, active_b: bool = true) -> void:
#static func callback_toggle_signal(callback: Callable, signal_a: Signal, signal_b: Signal, flags: ConnectFlags = 0, active_b: bool = true) -> void:
	#signal_disconnect(signal_a if active_b else signal_b, callback)
	#signal_connect(signal_b if active_b else signal_a, callback, flags)
#
#
#static func callback_swap_objects(callback: Callable, old: Object, new: Object, signal_name: StringName, flags: ConnectFlags = 0) -> void:
	#object_swap(old, new, signal_name, callback, flags)
#
#
#static func callback_swap_signals(callback: Callable, old: Signal, new: Signal, flags: ConnectFlags = 0) -> void:
	#swap_signals(old, new, callback, flags)
#

# --- Until: ---


class Connection:
	
	var _signal: Signal
	var _callback: Callable
	var _flags: ConnectFlags = 0
	
	#static func from_dictionary(dict: Dictionary) -> Connection:
		#var signal_: Signal = dict.get("signal", Signal())
		#var callback: Callable = dict.get("callback", Callable())
		#var flags: ConnectFlags = dict.get("flags", 0)
		#return Connection.new(signal_, callback, flags) if not signal_.is_null() and callback.is_valid() else null
	
	func _init(signal_: Signal, callback: Callable, flags: ConnectFlags = 0) -> void:
		_signal = signal_
		_callback = callback
		_flags = flags
	
	func realize() -> int: return _signal.connect(_callback, _flags)
	func cancel() -> void: _signal.disconnect(_callback)


static func signals_connect_until(connections: Array[Connection], disconnect_signal: Signal) -> void:
	for connection in connections:
		connection.realize()
	
	var cleaner: Callable = func() -> void:
		for connection in connections:
			connection.cancel()
	
	disconnect_signal.connect(cleaner, CONNECT_ONE_SHOT)


static func signal_connect_until(signal_: Signal, callback: Callable, disconnect_signal: Signal, flags: ConnectFlags = 0) -> void:
	signal_.connect(callback, flags)
	disconnect_signal.connect(signal_.disconnect.bind(callback), CONNECT_ONE_SHOT)
