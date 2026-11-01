## Use it for big data computation chains with early exit


class_name LazyFlow
extends RefCounted


class Batch extends RefCounted:
	
	const SIZE: int = 2**12
	
	var items: Array = []
	
	func clear() -> void: items.clear()
	func size() -> int: return items.size()


@abstract class LazyIterator extends RefCounted:
	@abstract func advance(batch: Batch) -> bool


class ArrayIterator extends LazyIterator:
	var _arr: Variant
	var _idx: int = 0
	
	func _init(p_arr: Variant) -> void:
		assert(Utils.is_array(p_arr))
		_arr = p_arr
	
	func advance(batch: Batch) -> bool:
		if _idx >= len(_arr): return false
		batch.items = _arr.slice(_idx, _idx + Batch.SIZE)
		_idx += Batch.SIZE
		return true


class FilterIterator extends LazyIterator:
	var _source: LazyIterator
	var _predicate: Callable
	
	func _init(p_source: LazyIterator, p_pred: Callable) -> void:
		_source = p_source
		_predicate = p_pred
	
	func advance(batch: Batch) -> bool:
		while _source.advance(batch):
			batch.items = batch.items.filter(_predicate)
			if not batch.items.is_empty(): return true
		return false


class MapIterator extends LazyIterator:
	var _source: LazyIterator
	var _transform: Callable

	func _init(p_source: LazyIterator, p_mod: Callable) -> void:
		_source = p_source
		_transform = p_mod
	
	func advance(batch: Batch) -> bool:
		if not _source.advance(batch): return false
		batch.items = batch.items.map(_transform)
		return true


class TakeIterator extends LazyIterator:
	var _source: LazyIterator
	var _limit: int
	var _taken: int = 0
	
	func _init(p_source: LazyIterator, p_count: int) -> void:
		_source = p_source
		_limit = p_count
	
	func advance(batch: Batch) -> bool:
		if _taken >= _limit: return false
		if not _source.advance(batch): return false
		var remaining: int = _limit - _taken
		if batch.size() > remaining: batch.items = batch.items.slice(0, remaining)
		_taken += batch.size()
		return true


class SkipIterator extends LazyIterator:
	var _source: LazyIterator
	var _to_skip: int
	var _skipped: int = 0
	
	func _init(p_source: LazyIterator, p_count: int) -> void:
		_source = p_source
		_to_skip = p_count
	
	func advance(batch: Batch) -> bool:
		while _skipped < _to_skip:
			if not _source.advance(batch): return false
			var remaining: int = _to_skip - _skipped
			if batch.size() <= remaining:
				_skipped += batch.size()
				batch.clear()
			else:
				batch.items = batch.items.slice(remaining)
				_skipped = _to_skip
				return true
		return _source.advance(batch)



var _head: LazyIterator

func _init(p_head: LazyIterator = null) -> void: _head = p_head

static func iter(array: Array) -> LazyFlow: return LazyFlow.new(ArrayIterator.new(array))
func filter(f: Callable)       -> LazyFlow: return LazyFlow.new(FilterIterator.new(_head, f))
func map(f: Callable)          -> LazyFlow: return LazyFlow.new(MapIterator.new(_head, f))
func take(n: int)              -> LazyFlow: return LazyFlow.new(TakeIterator.new(_head, n))
func skip(n: int)              -> LazyFlow: return LazyFlow.new(SkipIterator.new(_head, n))


 
# ==============================================================================
# Terminal methods
# ==============================================================================

func to_array() -> Array:
	var result: Array = []
	var batch := Batch.new()
	while _head.advance(batch):
		result.append_array(batch.items)
	return result


func reduce(reductor: Callable, accum: Variant = null) -> Variant:
	var result: Variant = accum
	var batch := Batch.new()
	while _head.advance(batch):
		for item in batch.items:
			result = reductor.call(result, item)
	return result


func any(predicate: Callable) -> bool:
	var batch := Batch.new()
	while _head.advance(batch):
		if batch.items.any(predicate): return true
	return false


func all(predicate: Callable) -> bool:
	var batch := Batch.new()
	while _head.advance(batch):
		if not batch.items.all(predicate): return false
	return true



# ==============================================================================
# Benchmark
# ==============================================================================

static func benchmark() -> void:
	var main_loop := Engine.get_main_loop()
	var scene_tree := main_loop as SceneTree
	
	var rest := func() -> void: await scene_tree.create_timer(0.1).timeout if scene_tree else true
	
	var runner := func() -> void:
		print_rich("[color=cyan][b]=== LazyFlow BENCHMARK START ===[/b][/color]\n")
		
		var test_size := 300_000
		var source_array: Array = []
		source_array.resize(test_size)
		for i in range(test_size):
			source_array[i] = randi_range(1, 1000)
			
		var skip_count := 10_000
		var is_even := func(x: int) -> bool: return x % 2 == 0
		var multiply_by_ten := func(x: int) -> int: return x * 10
		var greater_than_5k := func(x: int) -> bool: return x > 5000

		var _warmup = LazyFlow.iter(source_array).skip(1).filter(is_even).map(multiply_by_ten).filter(greater_than_5k).take(5).to_array()
		_warmup.clear()
		
		await rest.call()
		
		# --------------------------------------------------------------------------
		# TEST 1: Full Execution
		# --------------------------------------------------------------------------
		print_rich("[color=yellow][b]Test 1: Full Execution (Size: %d) -> [4 Steps: Skip -> Filter -> Map -> Filter][/b][/color]" % test_size)
		var t1_results := {}
		
		# 1.1 Standard for
		var time_start := Time.get_ticks_usec()
		var res_for: Array = []
		var current_idx := 0
		for item in source_array:
			if current_idx < skip_count:
				current_idx += 1
				continue
			if item % 2 == 0:
				var mapped = item * 10
				if mapped > 5000:
					res_for.append(mapped)
		t1_results["Standard 'for'"] = Time.get_ticks_usec() - time_start
		
		await rest.call()
		
		# 1.2 Eager Chain
		time_start = Time.get_ticks_usec()
		var res_greedy: Array = source_array.slice(skip_count).filter(is_even).map(multiply_by_ten).filter(greater_than_5k)
		t1_results["Eager Chain"] = Time.get_ticks_usec() - time_start
		
		await rest.call()
		
		# 1.3 LazyFlow
		time_start = Time.get_ticks_usec()
		var res_lazy := LazyFlow.iter(source_array).skip(skip_count).filter(is_even).map(multiply_by_ten).filter(greater_than_5k).to_array()
		t1_results["LazyFlow"] = Time.get_ticks_usec() - time_start
		
		_print_benchmark_results(t1_results)
		assert(res_for == res_greedy and res_greedy == res_lazy, "Error: TEST 1 results do not match!")
		print_rich("[color=gray]Validation: Results are identical.[/color]\n")

		await rest.call()

		# --------------------------------------------------------------------------
		# TEST 2: Short-Circuit / Early Exit
		# --------------------------------------------------------------------------
		var take_count := 1000
		print_rich("[color=yellow][b]Test 2: Early Exit (Take %d) -> [5 Steps: Skip -> Filter -> Map -> Filter -> Take][/b][/color]" % take_count)
		var t2_results := {}
		
		# 2.1 Standard for
		time_start = Time.get_ticks_usec()
		var res_for_take: Array = []
		var current_idx_take := 0
		for item in source_array:
			if current_idx_take < skip_count:
				current_idx_take += 1
				continue
			if item % 2 == 0:
				var mapped = item * 10
				if mapped > 5000:
					res_for_take.append(mapped)
					if res_for_take.size() == take_count:
						break
		t2_results["Standard 'for'"] = Time.get_ticks_usec() - time_start
		
		await rest.call()
		
		# 2.2 Eager Chain
		time_start = Time.get_ticks_usec()
		var res_greedy_take := source_array.slice(skip_count).filter(is_even).map(multiply_by_ten).filter(greater_than_5k).slice(0, take_count)
		t2_results["Eager Chain"] = Time.get_ticks_usec() - time_start
		
		await rest.call()
		
		# 2.3 LazyFlow
		time_start = Time.get_ticks_usec()
		var res_lazy_take := LazyFlow.iter(source_array).skip(skip_count).filter(is_even).map(multiply_by_ten).filter(greater_than_5k).take(take_count).to_array()
		t2_results["LazyFlow"] = Time.get_ticks_usec() - time_start
		
		_print_benchmark_results(t2_results)
		assert(res_for_take == res_greedy_take and res_greedy_take == res_lazy_take, "Error: TEST 2 results do not match!")
		print_rich("[color=gray]Validation: Results are identical.[/color]\n")
		
		print_rich("[color=cyan][b]=== LazyFlow BENCHMARK END ===[/b][/color]")

	runner.call()


static func _print_benchmark_results(results: Dictionary) -> void:
	var sorted_methods: Array = results.keys()
	sorted_methods.sort_custom(func(a, b): return results[a] < results[b])
	
	var ranks = [
		{"place": "1st place", "color": "forest_green"},
		{"place": "2nd place", "color": "gold"},
		{"place": "3rd place", "color": "crimson"}
	]
	
	for idx in range(sorted_methods.size()):
		var method = sorted_methods[idx]
		var time = results[method]
		var rank = ranks[idx]
		print_rich("%-10s: [color=%s][b]%d μs (%s)[/b][/color]" % [rank.place, rank.color, time, method])
