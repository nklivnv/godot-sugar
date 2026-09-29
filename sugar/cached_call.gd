class_name CachedCall
extends RefCounted


var _callable: Callable
var _cache: Dictionary[int, Variant]


func _init(callable: Callable) -> void: _callable = callable

func is_cached(...args: Array) -> bool: return is_cachedv(args)
func is_cachedv(args: Array) -> bool: return _cache.has(args.hash())

func call_cached(...args: Array) -> Variant: return call_cachedv(args)
func call_cachedv(args: Array) -> Variant:
	var key := args.hash()
	if _cache.has(key): return _cache[key]
	var result: Variant = _callable.callv(args)
	_cache[key] = result
	return result

func call_recached(...args: Array) -> Variant: return call_recachedv(args)
func call_recachedv(args: Array) -> Variant:
	var key := args.hash()
	var result: Variant = _callable.callv(args)
	_cache[key] = result
	return result

func clear_cache() -> void: _cache.clear()
func clear_cached(...args: Array) -> void: _cache.erase(args.hash())
