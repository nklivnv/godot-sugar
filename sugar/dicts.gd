@abstract
extends Object
class_name Dicts



static func create(keys: Array, values: Array, default: Variant = null) -> Dictionary:
	
	var result := Dictionary({},
		keys.get_typed_builtin(), keys.get_typed_class_name(), keys.get_typed_script(),
		values.get_typed_builtin(), values.get_typed_class_name(), values.get_typed_script())
	
	var resized_values: Array = Arrays.resized(values, len(keys), default)
	
	for i in len(keys):
		result.set(keys[i], resized_values[i])
	
	return result


static func filled(keys: Array, value: Variant, type_key := TYPE_NIL, type_value := TYPE_NIL) -> Dictionary:
	var dictionary: Dictionary = {} if [type_key, type_value].all(Operator.is_equal.bind(TYPE_NIL)) else Dictionary({}, type_key, "", null, type_value, "", null)
	for key in keys:
		dictionary[key] = value
	return dictionary


enum ConflictMode { OLD, NEW, SKIP }

## Merge(overwrite = true)					(a, b, true, true, NEW)
## Merge(overwrite = false)					(a, b, true, true, OLD)
## Difference:											(a, b, true, false, SKIP)
## Intersection:										(a, b, false, false, NEW)
## XOR:															(a, b, true, true, SKIP)
## Update_existing:									(a, b, true, false, NEW)
## Fill_missing:										(a, b, true, true, OLD)

## 1.		Merge / Overwrite:						true	true		(ConflictMode.NEW)
## 2.		Merge / Keep Old:							true	true		(ConflictMode.OLD)
## 3.		Keys XOR:											true	true		(ConflictMode.SKIP)
## 4.		Keys Subtract (A - B):				true	false		(ConflictMode.SKIP)
## 5.		Update Existing Keys:					true	false		(ConflictMode.NEW)
## 6.		Keep Existing Keys:						true	false		(ConflictMode.OLD)
## 7.		Keys Intersection (New):			false	false		(ConflictMode.NEW)
## 8.		Keys Intersection (Old):			false	false		(ConflictMode.OLD)
## 9.		Take Only New Keys:						false	true		(ConflictMode.NEW)
## 10.	Fill Missing Keys:						false	true		(ConflictMode.OLD)
## 11.	Keys Subtract (B - A):				false	true		(ConflictMode.SKIP)
## 12.	Empty / Clear:								false	false		(ConflictMode.SKIP)


static func updated(a: Dictionary, b: Dictionary, include_unmatched_a: bool, include_unmatched_b: bool, conflict_mode: ConflictMode) -> Dictionary:
	var result: Dictionary = {}
	
	# 1. Unique A-keys:
	if include_unmatched_a:
		for key in a:
			if not b.has(key):
				result[key] = a[key]
	
	# 2. Unique B-keys:
	if include_unmatched_b:
		for key in b:
			if not a.has(key):
				result[key] = b[key]
	
	# 3. Conflicts:
	if conflict_mode != ConflictMode.SKIP:
		for key in (a if len(a) < len(b) else b):
			if a.has(key) and b.has(key):
				result[key] = a[key] if conflict_mode == ConflictMode.OLD else b[key]
				
	return result


static func key_merged(dictionary: Dictionary, keys: Array, overwrite: bool = false) -> Dictionary:
	return dictionary.merged(create(keys, []), overwrite)


static func key_updated(dictionary: Dictionary, keys: Array, default: Variant = null) -> Dictionary:
	var result := dictionary.duplicate()
	for key in dictionary:
		if key not in keys: result.erase(key)
	for key in keys:
		if key not in result: result[key] = default
	return result


#static func find_key(dict: Dictionary, predicate: Callable, default: Variant = null) -> Variant:
	#for key: Variant in dict:
		#if predicate.call(key): return key
	#return default


static func key_filtered(dict: Dictionary, predicate: Callable) -> Dictionary:
	var result: Dictionary = dict.duplicate()
	for key: Variant in result:
		if not predicate.call(key):
			result.erase(key)
	return result


static func value_filtered(dict: Dictionary, predicate: Callable) -> Dictionary:
	var result: Dictionary = dict.duplicate()
	for key: Variant in result:
		var value: Variant = result[key]
		if not predicate.call(value):
			result.erase(key)
	return result
