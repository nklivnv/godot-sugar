class_name StateShifter
extends RefCounted


var states: Array = []
var state: int = -1
var default_value: Variant

func _init(p_states: Array, init_state: int = 0, p_default_value: Variant = null) -> void:
	states = p_states
	state = init_state if states else -1 
	default_value = p_default_value

func is_at_front() -> bool: return not states or state == 0
func is_at_back() -> bool: return not states or state == len(states) - 1 

func shift(offset: int = 1, wrap_index: bool = true, skip_equals: bool = true, from_index: int = state) -> void:
	if not states: state = -1; return
	
	var size: int = len(states)
	var target_index: int = wrapi(from_index + offset, 0, size) if wrap_index else clampi(from_index + offset, 0, size - 1)
	
	if skip_equals and states[target_index] == states[from_index]:
		var step: int = 1 if offset >= 0 else -1
		for i in range(1, size):
			var next_idx: int = target_index + (i * step)
			if not wrap_index and (next_idx < 0 or next_idx >= size): break
			
			var actual_idx: int = wrapi(next_idx, 0, size) if wrap_index else next_idx
			if states[actual_idx] != states[from_index]:
				target_index = actual_idx
				break
	
	state = target_index


func shift_from_value(what: Variant, offset: int = 1, wrap_index: bool = true, skip_equals: bool = true, from_index: int = state, default_index: int = from_index, ) -> void:
	if not states: state = -1; return
	var found_index: int = Arrays.find(states, what, from_index, true)
	shift(offset, wrap_index, skip_equals, default_index if found_index == -1 else found_index)


func get_shifted(offset: int = 1, wrap_index: bool = true, skip_equals: bool = true, from_index: int = state) -> Variant:
	shift(offset, wrap_index, skip_equals, from_index)
	return get_value()


func get_shifted_from_value(what: Variant, offset: int = 1, wrap_index: bool = true, skip_equals: bool = true, from_index: int = state, default_index: int = from_index) -> Variant:
	shift_from_value(what, offset, wrap_index, skip_equals, from_index, default_index, )
	return get_value()


func get_value() -> Variant: 
	return states[state] if states and state >= 0 and state < len(states) else default_value
