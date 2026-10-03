@abstract
extends Object
class_name PropertyListener


enum Flags {
	DEFERRED      = 0b1,
	ONE_SHOT      = 0b10,
	
	BIND_OBJECT   = 0b100,
	BIND_PROPERTY = 0b1000,
	BIND_VALUE    = 0b10000,
	
	BIND_OBJECT_AND_VALUE = 0b10100,
}

class ListenData extends RefCounted:
	var value: Variant
	var callback: Callable
	var flags: Flags


# Dictionary[instance_id (int), Dictionary[property_name (StringName), Array[ListenData]]]
static var _listen_data: Dictionary[int, Dictionary] = {}


static func _static_init() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree: tree.process_frame.connect(_process)


static func _process() -> void:
	var _free_quit: Array[int] = []
	
	for instance_id: int in _listen_data:
		var object: Object = instance_from_id(instance_id)
		if not is_instance_valid(object):
			_free_quit.append(instance_id)
			continue
		
		_process_object_properties(object, _listen_data[instance_id])
		
		if _listen_data[instance_id].is_empty(): _free_quit.append(instance_id)
	
	for instance_id: int in _free_quit: 
		_listen_data.erase(instance_id)


static func _process_object_properties(object: Object, properties: Dictionary) -> void:
	var properties_to_remove: Array[StringName] = []
	
	for property: StringName in properties:
		var listeners: Array = properties[property]
		var current_value: Variant = object.get(property)
		
		_process_property_listeners(object, property, current_value, listeners)
		
		if listeners.is_empty():
			properties_to_remove.append(property)
	
	for property: StringName in properties_to_remove: 
		properties.erase(property)


static func _process_property_listeners(object: Object, property: StringName, current_value: Variant, listeners: Array) -> void:
	var listeners_to_remove: Array[ListenData] = []
	
	for data: ListenData in listeners:
		if not data.callback.is_valid():
			listeners_to_remove.append(data)
			continue
		
		if data.value != current_value:
			data.value = current_value
			_execute_callback(object, property, data)
			
			if data.flags & Flags.ONE_SHOT: listeners_to_remove.append(data)
	
	for data: ListenData in listeners_to_remove:
		listeners.erase(data)


static func _execute_callback(object: Object, property: StringName, data: ListenData) -> void:
	var final_callback: Callable = data.callback
	
	if data.flags & Flags.BIND_VALUE:    final_callback = final_callback.bind(data.value)
	if data.flags & Flags.BIND_PROPERTY: final_callback = final_callback.bind(property)
	if data.flags & Flags.BIND_OBJECT:   final_callback = final_callback.bind(object)
	
	if data.flags & Flags.DEFERRED: final_callback.call_deferred()
	else:                           final_callback.call()


static func call_on_changed(object: Object, property: StringName, callback: Callable, flags: Flags = 0) -> void:
	if not is_instance_valid(object): return
	
	var instance_id: int = object.get_instance_id()
	if instance_id not in _listen_data: 
		_listen_data[instance_id] = {}
	
	if property not in _listen_data[instance_id]:
		_listen_data[instance_id][property] = [] as Array[ListenData]
	
	var listeners: Array = _listen_data[instance_id][property]
	for data: ListenData in listeners:
		if data.callback == callback:
			return
	
	var data: ListenData = ListenData.new()
	data.value = object.get(property)
	data.callback = callback
	data.flags = flags
	
	listeners.append(data)


static func erase(object: Object, property: StringName, callback: Callable = Callable()) -> void:
	if not is_instance_valid(object): return
	var instance_id: int = object.get_instance_id()
	
	if not _listen_data.has(instance_id) or not _listen_data[instance_id].has(property): return
	
	if callback.is_null(): _listen_data[instance_id].erase(property)
	else:
		var listeners: Array = _listen_data[instance_id][property]
		for data: ListenData in listeners:
			if data.callback == callback:
				listeners.erase(data)
				break
		if listeners.is_empty(): _listen_data[instance_id].erase(property)
	if _listen_data[instance_id].is_empty(): _listen_data.erase(instance_id)


static func clear() -> void: _listen_data.clear()
