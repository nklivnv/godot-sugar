@abstract
@tool
extends Object
class_name Arrays



static func is_index_valid(array: Variant, index: int) -> bool:
	var length: int = len(array)
	return index >= -length and index < length

static func get_or(array: Variant, index: int, default: Variant = null) -> Variant:
	return array[index] if Utils.is_array(array) and is_index_valid(array, index) else default


static func set_with_resize(array: Variant, index: int, value: Variant, default: Variant = null) -> void:
	assert(Utils.is_array(array))
	if not is_index_valid(array, index): resize(array, index + 1, default)
	array[index] = value


static func empty() -> Array: return []
static func filled_custom(length: int, constructor: Callable) -> Array: return range(length).map(constructor.unbind(1))
static func filled(length: int, value: Variant = null) -> Array:
	var array: Array = []
	array.resize(length)
	if value != null: array.fill(value)
	return array


static func resize(array: Variant, length: int, default: Variant = null) -> void:
	assert(Utils.is_array(array))
	var old_length: int = len(array)
	array.resize(length)
	if default != null:
		for i in range(old_length, len(array)):
			array[i] = default


static func resized(array: Array, length: int, default: Variant = null) -> Array:
	var duplicate := array.duplicate()
	resize(duplicate, length, default)
	return duplicate


static func reversed(array: Array) -> Array:
	var duplicate := array.duplicate()
	duplicate.reverse()
	return duplicate


static func resize_custom(array: Array, length: int, constructor: Callable) -> void:
	resize_indexed(array, length, constructor.unbind(1))


static func resize_indexed(array: Array, length: int, index_constructor: Callable) -> void:
	var old_length: int = len(array)
	array.resize(length)
	for i in range(old_length, length):
		array[i] = index_constructor.call(i)


static func repeat(array: Array, repeats: int = 1) -> Array:
	if repeats == 0 or array.is_empty(): return []
	
	var source: Array = array
	if repeats < 0:
		source = array.duplicate()
		source.reverse()
	
	var result: Array
	for i in absi(repeats):
		result.append_array(source)
	return result

 
static func scale(array: Array, multiplier: float = 1.0) -> void:
	var old_length: int = len(array)
	var new_length: int = floori(old_length * absf(multiplier))
	
	if old_length == 0 or is_zero_approx(multiplier) or new_length <= 0:
		array.clear()
		return
	
	if multiplier < 0: array.reverse()
	resize_indexed(array, new_length, func(i: int) -> Variant: return array[wrapi(i, 0, old_length)])


static func scaled(array: Array, multiplier: float = 1) -> Array:
	var duplicate: Array = array.duplicate()
	scale(duplicate, multiplier)
	return duplicate


static func assigned(array: Array, ...arrays: Array) -> Array:
	var duplicate: Array = array.duplicate()
	for a: Array in arrays:
		duplicate.assign(a)
	return duplicate


static func sorted(array: Array) -> Array:
	var duplicate: Array = array.duplicate()
	duplicate.sort()
	return duplicate


static func filtered(array: Array, predicate: Callable, inverse: bool = false) -> Array:
	return array.filter(predicate) if not inverse else array.filter(func(i: Variant) -> bool: return not predicate.call(i))


## ({name = 1}, {name = 2}, {name = 3}, "name", Operator.is_equal.bind(2)) => [{name = 2}]
static func key_filtered(array: Array, key: Variant, predicate: Callable, inverse: bool = false) -> Array:
	return array.filter(_key_filtered_match_key.bind(key, predicate, inverse))

static func _key_filtered_match_key(item: Variant, key: Variant, predicate: Callable, inverse: bool) -> bool:
	return predicate.call(item.get(key)) != inverse


## Применяет преобразование только только к прошедшим проверку элементам
## ([1,2,3,4], add(10), greater(2)) => [1,2,13,14]
static func map_if(array: Array, converter: Callable, predicate: Callable, negate: bool = false) -> Array:
	return array.map(func(item: Variant) -> Variant: return converter.call(item) if predicate.call(item) != negate else item)


static func counts(array: Array) -> Dictionary[Variant, int]:
	var _unique: Array = unique(array)
	return Dicts.create(_unique, _unique.map(array.count))


static func avg_weighted(values: Array, weights: PackedFloat32Array) -> Variant:
	if len(values) == 1: return values[0]
	return sum(muls(values, weights)) / sumf(weights)


# [-1, 0, 1] -> [0, 0.333, 0.667]
static func get_weight_fractions(weights: PackedFloat32Array) -> PackedFloat32Array:
	if weights.is_empty(): return []
	var duplicate: Array = Array(weights)
	var min_value: float = duplicate.min()
	if min_value < 0.0: duplicate = duplicate.map(Operator.addf.bind(-min_value)) # подняли до положительных
	var length: int = len(duplicate)
	var total: float = sumf(duplicate)
	if is_zero_approx(total): return filled(length, 1.0 / length)
	return duplicate.map(Operator.mulf.bind(1.0 / total))


static func set_sum_normalized(weights: PackedFloat32Array, index: int, value: float, p_sum: float = 1.0) -> void:
	var length: int = len(weights)
	if length == 1:
		weights[0] = p_sum
		return
	
	weights[index] = value
	
	var other_indices: PackedInt32Array = filtered(range(len(weights)), is_same.bind(index), true)
	var others := Array(other_indices).map(weights.get)
	
	if others.all(is_zero_approx):
		var each: float = (p_sum - value) / (length - 1)
		for i in other_indices:
			weights[i] = each
	else:
		var sum_others: float = Operator.sumf(others)
		var factor: float = (p_sum - value) / sum_others
		for i in other_indices:
			weights[i] *= factor


static func get_sum_normalized(array: PackedFloat32Array, index: int, value: float, p_sum: float = 1.0) -> PackedFloat32Array:
	var duplicate: PackedFloat32Array = array.duplicate()
	set_sum_normalized(duplicate, index, value, p_sum)
	return duplicate


static func sum(array: Array) -> Variant: return array.slice(1).reduce(Operator.add, array[0])
static func sumi(array: Array) -> int: return array.reduce(Operator.addi, 0)
static func sumf(array: Array) -> float: return array.reduce(Operator.addf, 0.0)
static func sum_2d(array: Array) -> Vector2: return array.reduce(Operator.add_2d, Vector2.ZERO)
static func sum_3d(array: Array) -> Vector3: return array.reduce(Operator.add_3d, Vector3.ZERO)


static func prod(array: Array) -> Variant: return array.slice(1).reduce(Operator.mul, array[0])
static func prodi(array: Array) -> int: return array.reduce(Operator.muli, 0)
static func prodf(array: Array) -> float: return array.reduce(Operator.mulf, 0.0)
static func prod_2d(array: Array) -> Vector2: return array.reduce(Operator.mul_2d, Vector2.ONE)
static func prod_3d(array: Array) -> Vector3: return array.reduce(Operator.mul_3d, Vector3.ONE)


static func avg(array: Array) -> Variant: return sum(array) / len(array)
static func avgf(array: PackedFloat32Array) -> float: return sumf(array) / len(array)
static func avg_2d(array: PackedVector2Array) -> Vector2: return sum_2d(array) / len(array)
static func avg_3d(array: PackedVector3Array) -> Vector3: return sum_3d(array) / len(array)


static func interpolate(values: Array, normalized_weight: float, interpolator: Callable = lerp, wrap_mode: bool = false) -> Variant:
	var length: int = len(values)
	assert(length > 0, "Utils.interpolate(...) - len(values) > 0 != true")
	if length == 1: return values[0]
	
	normalized_weight = wrapf(normalized_weight, 0.0, 1.0) if wrap_mode else clampf(normalized_weight, 0.0, 1.0)
	
	var float_index: float = normalized_weight * (length - 1)
	var index_a: int = floori(float_index)
	var index_b: int = ceili(float_index)
	var local_weight: float = float_index - index_a
	
	if index_b >= length:
		index_b = length - 1
		local_weight = 1.0
	
	return interpolator.call(values[index_a], values[index_b], local_weight)


# WARNING: 90% - что неправтльно это:
static func interpolate_weighted(values: Array, weights: PackedFloat32Array, normalized_weight: float, interpolator: Callable = lerpf, wrap_mode: bool = false) -> Variant:
	var length: int = len(values)
	assert(length > 0, "Utils.interpolate_weighted(...) - len(values) > 0 != true")
	if length == 1: return values[0]
	
	var weight_fractions: PackedFloat32Array = get_weight_fractions(weights)
	weight_fractions.resize(length)
	
	normalized_weight = wrapf(normalized_weight, 0.0, 1.0) if wrap_mode else clampf(normalized_weight, 0.0, 1.0)
	
	var weighted_sum: Variant = sum(muls(values, weight_fractions))
	return interpolator.call(values[0], weighted_sum, normalized_weight)


#static func interpolate_lengthed(values: Array, lengths: PackedFloat32Array, normalized_weight: float, interpolator: Callable = lerpf, wrap_mode: bool = false) -> Variant:
	#var length: int = len(values)

static func interpolate_arrays(
	arrays: Array, 
	weights: PackedFloat32Array, 
	interpolator: Callable = lerp, 
	default_value: Variant = 0.0, 
	default_weight: float = 0.0
) -> Array:
	# 1. Фильтруем валидные массивы
	var valid_arrays: Array = arrays.filter(func(a: Variant) -> bool: return Utils.is_array(a) and not a.is_empty())
	if valid_arrays.is_empty(): 
		return []

	# 2. Вычисляем шаговые коэффициенты
	var acc_w: float = 0.0
	var steps: Array[float] = []
	for i: int in arrays.size():
		if Utils.is_array(arrays[i]) and not arrays[i].is_empty():
			var w: float = weights[i] if i < weights.size() else default_weight
			acc_w += w
			steps.append(w / acc_w if acc_w > 0.0 else 0.5)

	# 3. Схлопываем через zip_with. 
	# Используем синтаксис ...items для приема переменного числа аргументов
	return zip_with(valid_arrays, func(...items: Array) -> Variant:
		return range(1, items.size()).reduce(
			func(blend: Variant, idx: int) -> Variant: 
				return interpolator.call(blend, items[idx], steps[idx]), 
			items[0] # Исправлено: берем первый элемент items[0], а не весь массив items
		), false, default_value)



static func shifted_from(array: Array, from: int, offset: int = 1) -> Variant:
	return array[wrapi(from + offset, 0, len(array))] if array else null


static func shifted(array: Array, value: Variant, offset: int = 1) -> Variant:
	return shifted_from(array, array.find(value), offset)


static func has_sub_sequence(seq: Array, sub_seq: Array) -> bool: return is_sub_sequence(sub_seq, seq)
static func is_sub_sequence(sub_seq: Array, seq: Array) -> bool:
	var sub_seq_length: int = len(sub_seq)
	if sub_seq_length == 0: return true
	for i in range(len(seq) - sub_seq_length + 1):
		if seq.slice(i, i + sub_seq_length) == sub_seq: return true
	return false


#region ELEMENTWISE ############################################################


## Поэлементное сложение
static func addsf(a: PackedFloat32Array, b: PackedFloat32Array, shortest_array: bool = false, default_value: float = 0.0) -> PackedFloat32Array:
	
	var a_length: int = len(a)
	var b_length: int = len(b)
	
	var result_length: int = mini(a_length, b_length) if shortest_array else maxi(a_length, b_length)
	var c: PackedFloat32Array
	c.resize(result_length)
	
	for i in len(c):
		var a_value: float = a[i] if i < a_length else default_value
		var b_value: float = b[i] if i < b_length else default_value
		c[i] = a_value + b_value
	
	return c


## Поэлементное перемножение
static func muls(a: Array, b: Array, shortest_length: bool = false) -> Array:
	return range(mini(len(a), len(b)) if shortest_length else maxi(len(a), len(b))).map(func(i: int) -> Variant: return a[i] * b[i])



static func mulsf(a: PackedFloat32Array, b: PackedFloat32Array, shortest_length: bool = false, default_value: float = 1.0) -> PackedFloat32Array:
	
	var a_length: int = len(a)
	var b_length: int = len(b)
	
	var result_length: int = mini(a_length, b_length) if shortest_length else maxi(a_length, b_length)
	var c: PackedFloat32Array
	c.resize(result_length)
	
	for i in len(c):
		var a_value: float = a[i] if i < a_length else default_value
		var b_value: float = b[i] if i < b_length else default_value
		c[i] = a_value * b_value
	
	return c


#static func lerpsf(array: PackedFloat32Array, normalized_weight: float, wrap_mode: bool = false) -> float:
	#if not array:
		#printerr("Arrays.lerpfs(...) - array.is_empty() != false")
		#return NAN
	#
	#if len(array) == 1:
		#return array[0]
	#
	#normalized_weight = wrapf(normalized_weight, 0, 1) if wrap_mode else clampf(normalized_weight, 0, 1)
	#
	#var i := int(normalized_weight * (len(array) - 1))
	#var a: float = array[i]
	#var b: float = array[i+1] if i+1 < len(array) else array[0]
	#
	#var lerp_weight: float = normalized_weight * (len(array) - 1) - i
	#return lerpf(a, b, lerp_weight)


#static func lerps_3d(array: PackedVector3Array, normalized_weight: float, wrap_mode: bool = false) -> Vector3:
	#if not array:
		#printerr("Arrays.lerps_3d(...) - array.is_empty() =! false")
		#return Vector3.INF
	#
	#if len(array) == 1:
		#return array[0]
	#
	#normalized_weight = wrapf(normalized_weight, 0, 1) if wrap_mode else clampf(normalized_weight, 0, 1)
	#
	#var i := int(normalized_weight * (len(array) - 1))
	#
	#var a: Vector3 = array[i]
	#var b: Vector3 = array[i+1] if i+1 < len(array) else array[0]
	#
	#var lerp_weight: float = normalized_weight * (len(array) - 1) - i
	#return a.lerp(b, lerp_weight)


## ([0,3], [3,2,1], min, false, 0) => [0,1,0]
static func zip_with(arrays: Array, function: Callable, shortest_length: bool = false, default_value: Variant = null) -> Array:
	return [] if arrays.is_empty() else range(arrays.map(len).reduce(mini if shortest_length else maxi)).map(
		func(i: int) -> Variant: return function.callv(arrays.map(
			func(arr: Array) -> Variant: return arr[i] if i < len(arr) else default_value)))


static func vector_length_squared(array: Array[float]) -> float: return sumf(mulsf(array, array))
static func vector_length(array: Array[float]) -> float: return sqrt(vector_length_squared(array))

static func vector_normalized(vector: PackedFloat32Array) -> PackedFloat32Array:
	var reverse_length: float = 1.0 / vector_length(vector)
	return Array(vector).map(Operator.mulf.bind(reverse_length))


#endregion ELEMENTWISE #########################################################
#region SETS ###################################################################


static func unique(array: Array) -> Array:
	var dict: Dictionary
	for item: Variant in array: dict[item] = null
	return Array(dict.keys(), array.get_typed_builtin(), array.get_typed_class_name(), array.get_typed_script())


static func sets_intersects(a: Array, b: Array) -> bool: return a.any(b.has) if len(a) < len(b) else b.any(a.has)
static func is_sub_set(subset: Array, p_set: Array) -> bool: return subset.all(p_set.has)


static func sets_intersection(a: Array, b: Array) -> Array:
	return unique(a.filter(b.has) if len(a) < len(b) else b.filter(a.has))


static func sets_union(a: Array, b: Array) -> Array:
	return unique(a + sets_difference(b, a))


static func sets_difference(a: Array, b: Array) -> Array:
	return unique(a.filter(func(item: Variant) -> bool: return item not in b))


static func sets_xor(a: Array, b: Array) -> Array:
	return sets_union(sets_difference(a, b), sets_difference(b, a))


#endregion SETS ################################################################
#region ITERATIONS #############################################################


# TODO нет поиска по ключу
#static func find(array: Array, what: Variant, from: int = 0, default: Variant = null, key: String = "") -> Variant:
	#if not key:
		#var index: int = array.find(what, from)
		#return array[index] if index >= 0 else default
	
	#else:
		#var use_property_path: bool = ":" in key
		#for i in len(array):
			#var object: Variant = array[i]
			#var value: Variant = object.get_indexed(key) if use_property_path else object.get(key)
			#print(value)
			#if value == what: return value
	
	#return default


## ([1, 2], min) => 1
## ([1], min) => 1
## ([], min) => null
static func safe_reduce(array: Array, reductor: Callable, default: Variant = null) -> Variant:
	return array.slice(1).reduce(reductor, array[0]) if array else default


static func reduce_while(array: Array, reductor: Callable, result_predicate: Callable, init_value: Variant = null) -> Variant:
	var result: Variant = init_value
	for item in array:
		var next_result = reductor.call(result, item)
		if not result_predicate.call(next_result): return result
		result = next_result
	return result


## (['a','b','a','b'], 'a', 2, true) => 0
static func find(array: Array, what: Variant, from: int = 0, cyclic: bool = true) -> int:
	var found_index: int = array.find(what, from)
	if found_index == -1 and cyclic and from > 0: return array.slice(0, from).find(what)
	return found_index


static func find_custom(array: Array, predicate: Callable, from: int = 0, cyclic: bool = true) -> int:
	var found_index: int = array.find_custom(predicate, from)
	if found_index == -1 and cyclic and from > 0: return array.slice(0, from).find_custom(predicate, from)
	return found_index


static func choose_first(values: Array[Variant], conditions: Array[Callable], default: Variant = null) -> Variant:
	var value_index: int = conditions.find_custom(func(condition: Callable) -> bool: return condition.call())
	return values[value_index] if value_index != -1 else default


static func choose_first_valid(values: Array[Variant], predicates: Array[Callable], default: Variant = null) -> Variant:
	var value_index: int = range(len(values)).find_custom(func(i: int) -> bool: return predicates[i].call(values[i]))
	return values[value_index] if value_index != -1 else default


static func find_first(array: Array, predicate: Callable, from: int = 0, default: Variant = null) -> Variant:
	var index: int = array.find_custom(predicate, from)
	return array[index] if index >= 0 else default


static func find_first_cyclic(array: Array, predicate: Callable, from: int = 0, default: Variant = null) -> Variant:
	var index: int = find_custom(array, predicate, from, true)
	return array[index] if index >= 0 else default


## ([-5, 3, -8], abs, Bound.greater(5)) => -8
## (["лук", "арбалет", "меч"], len, Bound.greater(5)) => "арбалет"
## (["A", "B", "C"], to_lower, Bound.equal("b")) => "B"
static func find_first_custom(array: Array, converter: Callable, predicate: Callable, from: int = 0, default: Variant = null) -> Variant:
	for i in range(from, len(array)):
		var item: Variant = array[i]
		if predicate.call(converter.call(item)): return item
	return default


## ([0, -1, 40, 3], max) => 40
static func find_best(array: Array, comparator: Callable) -> Variant:
	var index: int = find_index(array, comparator)
	return array[index] if index >= 0 else null


## ([$Nearest, $Farthest], func(node: Node3D) -> float: return global_position.get_distance_ti(node.global_position), min) -> $Nearest
static func find_best_keyed(array: Array, converter: Callable, comparator: Callable) -> Variant:
	var index: int = find_index(array.map(converter), comparator)
	return array[index] if index >= 0 else null


## ([0, -1, 40, 3], max) => 2
static func find_index(array: Array, comparator: Callable) -> int:
	return -1 if not array else range(1, len(array)).reduce(
		func(best: int, i: int) -> int: return i if comparator.call(array[i], array[best]) else best, 0)


static func take_while(array: Array, predicate: Callable, deep: bool = false) -> Array:
	for i in len(array):
		if not predicate.call(array[i]):
			return array.slice(0, i, 1, deep)
	return array.duplicate(deep)


static func drop_while(array: Array, predicate: Callable, deep: bool = false) -> Array:
	for i in len(array):
		if not predicate.call(array[i]):
			return array.slice(i, (2**31)-1, 1, deep)
	return array.duplicate(deep)


## Идя последовательно берет take и пропускает skip элементов 
## ([a, b, c, d, e], 1, 1) => [a, c, e]
static func take_skip(array: Array, take: int, skip: int) -> Array:
	var result: Array = []
	for i in range(0, len(array), take + skip):
		result.append_array(array.slice(i, i + take))
	return result


## ([1,2], add.bind(1), mul.bind(2)) -> [1,2].map(add.bind(1)).map(mul.bind(2))
static func map(array: Array, ...functions: Array) -> Array:
	return array.map(func(item: Variant) -> Variant:
		return functions.reduce(func(acc: Variant, f: Callable): return f.call(acc), item))


## (0, 10, 5, 1)	=> [5, 6, 7, 8, 9, 0, 1, 2, 3, 4]
## (0, 10, 5, -1)	=> [5, 4, 3, 2, 1, 0, 9, 8, 7, 6]
## (0, 10, 5, 2)	=> [5, 7, 9, 1, 3]
## (0, 10, 5, -2)	=> [5, 3, 1, 9, 7]
#static func ring_range(a: int, b: int, from: int = a, step: int = 1) -> Array[int]:
	#if step == 0: return []
	#var length: int = b - a
	#var count: int = ceili(float(length) / absi(step))
	#var result: Array[int] = []
	#result.resize(count)
	#for i in count:
		#result[i] = posmod(from - a + i * step, length) + a
	#return result


## ([1,2,3], 0, 6)			=> [1,2,3,1,2,3]
## ([1,2,3], -1, 3)			=> [3,1,2,3]
## ([1,2,3], -1, 3, -1)	=> [3,2,1,3]
static func rotated_slice(array: Array, begin: int, end: int, step: int = 1) -> Array:
	return range(ceili(absf(end - begin) / absf(step))).map(func(i): return array[wrapi(begin + i * step, 0, len(array))])


## ([1,2,3], 1) => [2,3,1]
static func rotated(array: Array, offset: int) -> Array:
	if array.is_empty(): return []
	var index: int = posmod(offset, len(array))
	return array.slice(index) + array.slice(0, index)


#endregion ITERATIONS ##########################################################
#region STRUCTURES #############################################################


## [a,b,c,d,e] => [[a,b], [c,d], [e]]
static func chunked(array: Array, chunk_size: int) -> Array[Array]:
	return range(0, len(array), chunk_size).map(func(i: int) -> Array: return array.slice(i, i + chunk_size))


## [[a,b,c], [d,e]] => [a,b,c,d,e]
static func chainv(arrays: Array) -> Array: #return sum(arrays)
	var result: Array = []
	for array: Array in arrays: result.append_array(array)
	return result


## [[a,b,c], [d,e]] => [a,b,c,d,e]
static func chain(...arrays: Array) -> Array: return chainv(arrays)


## ([1,2,[3,[4,5]],6], false) => [1,2,3,[4,5],6]
## ([1,2,[3,[4,5]],6], true) => [1,2,3,4,5,6]
static func flatten(array: Array, recursive: bool = true) -> Array:
	var result: Array = []
	for a in array:
		result.append_array((flatten(a, true) if recursive else a) if Utils.is_array(a) else [a])
	return result
	#return array.reduce(func(acc: Array, x: Variant): return acc + (x if Utils.is_array(x) else [x]), [])


## [1,2,[3,[4,5]],6] => [1,2,3,4,5,6]
#static func flatten_recursive(array: Array) -> Array:
#	return array.reduce(func(acc: Array, x: Variant): return acc + (flatten_recursive(x) if Utils.is_array(x) else [x]), [])


#endregion STRUCTURES ##########################################################
#region OTHER ##################################################################


static func cosine_similarities(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
	
	if len(a) != len(b):
		printerr("Arrays.cosine_similarity: len(a) != len(b)")
		return NAN
	
	var dot: float = sumf(mulsf(a, b))
	var magnitude_a: float = vector_length(a)
	var magnitude_b: float = vector_length(b)
	
	return dot / (magnitude_a * magnitude_b) if magnitude_a > 0 and magnitude_b > 0 else 0.0


static func has_sequence(owner: Array, sequence: Array) -> bool:
	if not sequence: return true
	for i: int in range(len(owner) - len(sequence) + 1):
		if owner.slice(i, i + len(sequence)) == sequence:
			return true
	return false


static func swaps_and_pops(arrays: Array[Array], index: int) -> void:
	for array in arrays:
		array[index] = array[-1]
		array.pop_back()








static func for_each(array: Array, callable: Callable, ...args: Array) -> void:
	for item: Variant in array:
		callable.callv([item] + args)

static func call_each(array: Array, method: StringName, ...args: Array) -> void:
	callv_each(array, method, args)

static func callv_each(array: Array, method: StringName, args: Array = []) -> void:
	for item: Variant in array:
		if item is Object and item.has_method(method): item.callv(method, args)


static func for_each_if(array: Array, callable: Callable, predicate: Callable) -> void:
	if not predicate.is_valid(): return
	for item: Variant in array:
		if predicate.call(item): callable.call(item)

static func call_each_if(array: Array, method: StringName, predicate: Callable, ...args: Array) -> void:
	callv_each_if(array, method, predicate, args)

static func callv_each_if(array: Array, method: StringName, predicate: Callable, args: Array = []) -> void:
	if not predicate.is_valid(): return
	for item in array:
		if item is Object and item.has_method(method) and predicate.call(item): item.callv(method, args)


static func filtered_for(array: Array, predicate: Callable, callable: Callable) -> void: for_each_if(array, callable, predicate)
static func filtered_call(array: Array, predicate: Callable, method: StringName, ...args: Array) -> void: callv_each_if(array, method, predicate, args)
static func filtered_callv_method(array: Array, predicate: Callable, method: StringName, args: Array) -> void: callv_each_if(array, method, predicate, args)


#static func each_called(array: Array, item_method: StringName, ...args: Array) -> Array:
	#return array.map(Operator.bound_call(item_method, args))
	#return array.map(func(item: Object) -> Variant: return item.callv(item_method, args))


#static func post_called(array: Array, ...callables: Array) -> Array:
	#for item in array:
		#for callable: Callable in callables:
			#callable.call(item)
	#return array
