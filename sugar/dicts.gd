@abstract
extends Object
class_name Dicts


static func filter_keys(dict: Dictionary, predicate: Callable, inverted: bool = false) -> void:
	for key in dict.keys().filter(predicate if inverted else Bound.negate(predicate)):
		dict.erase(key)


static func create(keys: Array, values: Array, default: Variant = null) -> Dictionary:
	
	var result := Dictionary({},
		keys.get_typed_builtin(), keys.get_typed_class_name(), keys.get_typed_script(),
		values.get_typed_builtin(), values.get_typed_class_name(), values.get_typed_script())
	
	var resized_values: Array = Arrays.resized(values, len(keys), default)
	
	for i in len(keys):
		result.set(keys[i], resized_values[i])
	
	return result


static func from_keys(keys: Array, callable: Callable) -> Dictionary: return create(keys, keys.map(callable))


static func filled(keys: Array, value: Variant, type_key := TYPE_NIL, type_value := TYPE_NIL) -> Dictionary:
	var dict: Dictionary = {} if [type_key, type_value].all(Operator.is_equal.bind(TYPE_NIL)) else Dictionary({}, type_key, "", null, type_value, "", null)
	for key in keys:
		dict[key] = value
	return dict


static func intersection(a: Dictionary, b: Dictionary) -> Dictionary:
	var result: Dictionary
	for key in a:
		if key in b: result[key] = key
	return result


enum ConflictMode { OLD, NEW, SKIP }


## === KEYS: ===
## Merge(overwrite = true):  true  true  NEW
## Merge(overwrite = false): true  true  OLD
## XOR:                      true  true  SKIP
## Difference (A - B):       true  false SKIP
## Difference (B - A):       false true  SKIP
## Update Existing:          true  false NEW
## Keep Existing:            true  false OLD
## Intersection:             false false NEW
## Intersection:             false false OLD
## Take Only New:            false true  NEW
## Fill Missing:             false true  OLD
## Empty / Clear:            false false SKIP


static func updated(a: Dictionary, b: Dictionary, include_unmatched_a: bool, include_unmatched_b: bool, conflict_mode: ConflictMode) -> Dictionary:
	var result: Dictionary = {}
	
	# 1. Unique A-keys:
	if include_unmatched_a:
		for key in a:
			if key not in b: result[key] = a[key]
	
	# 2. Unique B-keys:
	if include_unmatched_b:
		for key in b:
			if key not in a: result[key] = b[key]
	
	# 3. Conflicts:
	if conflict_mode != ConflictMode.SKIP:
		for key in (a if len(a) < len(b) else b):
			if key in a and key in b:
				result[key] = a[key] if conflict_mode == ConflictMode.OLD else b[key]
	
	return result



static func keys_replaced(dict: Dictionary, keys: Array, default: Variant = null) -> Dictionary:
	var result: Dictionary
	for key in keys: result[key] = dict.get(key, default)
	return result


static func filtered(dict: Dictionary, key_value_predicate: Callable, inverted: bool = false) -> Dictionary:
	var result: Dictionary
	
	for key in dict:
		var value: Variant = dict[key]
		if key_value_predicate.call(key, value) != inverted:
			result[key] = value
	
	return result


static func key_filtered(dict: Dictionary, predicate: Callable, inverted: bool = false) -> Dictionary:
	var result: Dictionary = {}
	
	for key in dict:
		if predicate.call(key) != inverted:
			result[key] = dict[key]
	
	return result


static func value_filtered(dict: Dictionary, predicate: Callable, inverted: bool = false) -> Dictionary:
	var result: Dictionary = {}
	
	for key in dict:
		var value: Variant = dict[key]
		if predicate.call(value) != inverted:
			result[key] = value
	
	return result


static func set_if_empty(dict: Dictionary, key: Variant, value: Variant) -> void:
	if key not in dict: dict[key] = value


## "a,b:,c:1,d:e:2,,f:3" => {"a": null, "b": "", "c": "1", "d": "e:2", "f": "3"}
static func from_compressed_string(string: String, default: Variant = null, delimiter: String = ",", indicator: String = ":") -> Dictionary:
	var result: Dictionary = {}
	for slice: String in string.split(delimiter):
		slice = slice.strip_edges()
		if slice.is_empty(): continue
		
		var pair: PackedStringArray = slice.split(indicator, true, 1)
		var key: String = pair[0].strip_edges()
		if key.is_empty(): continue
		
		result[key] = pair[1].strip_edges() if len(pair) > 1 else default
	return result


#static func erase_keys(dict: Dictionary, predicate: Callable, inverted: bool = false) -> void:
#	var invalid_keys: Array
#	for key in dict: if predicate.call(key) != inverted: invalid_keys.append(key)
#	for key in invalid_keys: dict.erase(key)
