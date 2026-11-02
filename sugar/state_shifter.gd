class_name StateShifter
extends RefCounted


var states: Array = []
var state: int = -1
var wrap_mode: bool = true
var default_value: Variant = null


func _init(p_states: Array, init_state: int = 0, p_wrap_mode: bool = true, p_default_value: Variant = null) -> void:
	states = p_states
	state = init_state if states else -1 
	wrap_mode = p_wrap_mode
	default_value = p_default_value


func is_at_front() -> bool: return not states or state == 0
func is_at_back() -> bool: return not states or state == len(states) - 1 


func shift(offset: int = 1, skip_equals: bool = true, from_index: int = state) -> bool:
	if not states:
		var was_active: bool = state != -1
		state = -1
		return was_active
	
	var old: int = state
	var size: int = len(states)
	var target_index: int = wrapi(from_index + offset, 0, size) if wrap_mode else clampi(from_index + offset, 0, size - 1)
	
	if skip_equals and states[target_index] == states[from_index]:
		var step: int = 1 if offset >= 0 else -1
		
		for i in range(1, size):
			var next_index: int = target_index + i * step
			if not wrap_mode and (next_index < 0 or next_index >= size): break
			
			var check: int = wrapi(next_index, 0, size) if wrap_mode else next_index
			if states[check] != states[from_index]:
				target_index = check
				break
	
	state = target_index
	return state != old


func shift_from_value(what: Variant, offset: int = 1, skip_equals: bool = true, from_index: int = state, default_index: int = from_index) -> void:
	if not states: state = -1; return
	var found_index: int = Arrays.find_wrapped(states, what, from_index)
	shift(offset, skip_equals, default_index if found_index == -1 else found_index)


func get_shifted(offset: int = 1, skip_equals: bool = true, from_index: int = state) -> Variant:
	shift(offset, skip_equals, from_index)
	return get_value()


func get_shifted_from_value(what: Variant, offset: int = 1, skip_equals: bool = true, from_index: int = state, default_index: int = from_index) -> Variant:
	shift_from_value(what, offset, skip_equals, from_index, default_index)
	return get_value()


func get_value() -> Variant: 
	return states[state] if states and state >= 0 and state < len(states) else default_value
