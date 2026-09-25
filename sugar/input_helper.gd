@abstract class_name InputHelper extends Object


static var _press_times_ms: Dictionary[StringName, int] = {}
#static var _sequence_count: Dictionary[StringName, int] = {}


static func _check_release_time(action: StringName, threshold_ms: int, check_less_than: bool) -> bool:
	if Input.is_action_just_pressed(action): _press_times_ms[action] = Time.get_ticks_msec()
	if not Input.is_action_just_released(action): return false
	
	var press_time_ms: int = _press_times_ms.get(action, -1)
	if press_time_ms == -1:
		return false
	#_press_times_ms.erase(action) # Maybe?
	var held_ms: int = Time.get_ticks_msec() - press_time_ms
	return (held_ms < threshold_ms) if check_less_than else (held_ms >= threshold_ms)


static func is_action_released_earlier(action: StringName, threshold: float = 0.2) -> bool:
	return _check_release_time(action, int(threshold * 1000.0), true)


static func is_action_released_later(action: StringName, threshold: float = 0.2) -> bool:
	return _check_release_time(action, int(threshold * 1000.0), false)


static func is_action_long_pressed(action: StringName, threshold: float = 0.25) -> bool:
	if Input.is_action_just_pressed(action): _press_times_ms[action] = Time.get_ticks_msec()
	elif Input.is_action_just_released(action): _press_times_ms[action] = -1
	
	var press_time_ms: int = _press_times_ms.get(action, -1)
	if Input.is_action_pressed(action) and press_time_ms > 0:
		if Time.get_ticks_msec() - press_time_ms > threshold * 1000.0:
			_press_times_ms[action] = -1
			return true
	return false


#static func is_action_multiple_pressed(action: StringName, count: int = 2, timeout: float = 0.5) -> bool


#static func is_action_repeatedly_pressed(action: StringName, count: int = 2, timeout: float = 0.5) -> bool:
	#if count <= 0: return false
	#elif count == 1: return Input.is_action_just_pressed(action)
	#
	#if not Input.is_action_just_pressed(action): return false
	#
	#var now_ms: int = Time.get_ticks_msec()
	#var last_ms: int = _press_time.get(action, -1_000_000)
	#var timeout_ms: int = int(timeout * 1000.0)
	#var current_count: int = (_sequence_count.get(action, 0) + 1) if now_ms - last_ms <= timeout_ms else 1
	#
	#_press_time[action] = now_ms
	#
	#if current_count >= count:
		#_sequence_count[action] = 0
		#return true
	#else:
		#_sequence_count[action] = current_count
		#return false
