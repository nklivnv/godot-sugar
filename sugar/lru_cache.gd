class_name LruCache
extends RefCounted


var _callable: Callable
var _max_size: int
var _cache: Dictionary[int, Variant]
var _order: Dictionary[int, bool]


func _init(callable: Callable, max_size: int = 128) -> void:
	_callable = callable
	_max_size = max_size


func call_cached(...args: Array) -> Variant: return call_cachedv(args)


func call_cachedv(args: Array) -> Variant:
	var key: int = args.hash()
	
	if _cache.has(key):
		_order.erase(key)
		_order[key] = true
		return _cache[key]
	
	var result: Variant = _callable.callv(args)
	
	if _max_size > 0 and _cache.size() >= _max_size:
		var oldest_key: int = 0
		for k: int in _order:
			oldest_key = k
			break
			
		_cache.erase(oldest_key)
		_order.erase(oldest_key)
	
	_cache[key] = result
	_order[key] = true
	return result


func clear() -> void:
	_cache.clear()
	_order.clear()
