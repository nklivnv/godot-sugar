@abstract class_name Signals extends Object



# --- Object: ---

static func connect_object(object: Object, signal_name: StringName, callback: Callable, flags: ConnectFlags = 0) -> void:
	if object and object.has_signal(signal_name) and not object.is_connected(signal_name, callback):
		object.connect(signal_name, callback, flags)

static func disconnect_object(object: Object, signal_name: StringName, callback: Callable) -> void:
	if object and object.has_signal(signal_name) and  object.is_connected(signal_name, callback):
		object.disconnect(signal_name, callback)

static func reconnect_object(object: Object, signal_name: StringName, callback: Callable, flags: ConnectFlags = 0) -> void:
	swap_object(object, object, signal_name, callback)

static func swap_object(old: Object, new: Object, signal_name: StringName, callback: Callable, flags: ConnectFlags = 0) -> void:
	disconnect_object(old, signal_name, callback)
	connect_object(new, signal_name, callback, flags)

static func update_object(object: Object, signal_name: StringName, callback: Callable, active: bool, flags: ConnectFlags = 0) -> void:
	if active: reconnect_object(object, signal_name, callback, flags)
	else: disconnect_object(object, signal_name, callback)



# --- Object Arrays: ---

static func connect_objects(objects: Array, signal_name: StringName, callback: Callable, flags: ConnectFlags = 0) -> void:
	for object: Object in objects: connect_object(object, signal_name, callback, flags)

static func disconnect_objects(objects: Array, signal_name: StringName, callback: Callable) -> void:
	for object: Object in objects: disconnect_object(object, signal_name, callback)

static func swap_objects(old_objects: Array, new_objects: Array, signal_name: StringName, callback: Callable, flags: ConnectFlags = 0) -> void:
	disconnect_objects(old_objects, signal_name, callback)
	connect_objects(new_objects, signal_name, callback, flags)



# --- Signal: ---

static func connect_signal(signal_: Signal, callback: Callable, flags: ConnectFlags = 0) -> void:
	if not signal_.is_connected(callback): signal_.connect(callback, flags)

static func disconnect_signal(signal_: Signal, callback: Callable) -> void:
	if signal_.is_connected(callback): signal_.disconnect(callback)

static func reconnect_signal(signal_: Signal, callback: Callable, flags: ConnectFlags = 0) -> void:
	swap_signal(signal_, signal_, callback, flags)

static func swap_signal(old: Signal, new: Signal, callback: Callable, flags: ConnectFlags = 0) -> void:
	disconnect_signal(old, callback)
	connect_signal(new, callback, flags)

static func update_signal(signal_: Signal, callback: Callable, active: bool, flags: ConnectFlags = 0) -> void:
	if active: reconnect_signal(signal_, callback, flags)
	else: disconnect_signal(signal_, callback)



# --- Until: ---

class Connection:
	
	var _signal: Signal
	var _callback: Callable
	var _flags: ConnectFlags = 0
	
	func _init(signal_: Signal, callback: Callable, flags: ConnectFlags = 0) -> void:
		_signal = signal_
		_callback = callback
		_flags = flags
	
	func realize() -> int: return _signal.connect(_callback, _flags)
	func cancel() -> void: _signal.disconnect(_callback)


static func connect_signals_until(connections: Array[Connection], disconnect_signal: Signal) -> void:
	for connection in connections:
		connection.realize()
	
	var cleaner: Callable = func() -> void:
		for connection in connections:
			connection.cancel()
	
	disconnect_signal.connect(cleaner, CONNECT_ONE_SHOT)


static func connect_signal_until(signal_: Signal, callback: Callable, disconnect_signal: Signal, flags: ConnectFlags = 0) -> void:
	signal_.connect(callback, flags)
	disconnect_signal.connect(signal_.disconnect.bind(callback), CONNECT_ONE_SHOT)
