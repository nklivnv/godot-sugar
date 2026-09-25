## Use this for computation chains with early exit

class_name LazyPipe
extends RefCounted


const BATCH_SIZE: int = 4096


class PipeBatch extends RefCounted:
	var items: Array = []
	
	func clear() -> void: items.clear()
	func size() -> int: return items.size()


@abstract class LazyIterator extends RefCounted:
	@abstract func advance(batch: PipeBatch) -> bool


class ArrayIterator extends LazyIterator:
	var _arr: Variant
	var _idx: int = 0
	
	func _init(p_arr: Variant) -> void:
		assert(Utils.is_array(p_arr))
		_arr = p_arr
	
	func advance(batch: PipeBatch) -> bool:
		if _idx >= len(_arr): return false
		batch.items = _arr.slice(_idx, _idx + BATCH_SIZE)
		_idx += BATCH_SIZE
		return true


class FilterIterator extends LazyIterator:
	var _source: LazyIterator
	var _predicate: Callable
	
	func _init(p_source: LazyIterator, p_pred: Callable) -> void:
		_source = p_source
		_predicate = p_pred
	
	func advance(batch: PipeBatch) -> bool:
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
	
	func advance(batch: PipeBatch) -> bool:
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
	
	func advance(batch: PipeBatch) -> bool:
		if _taken >= _limit: return false
		if not _source.advance(batch): return false
		var remaining := _limit - _taken
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
	
	func advance(batch: PipeBatch) -> bool:
		while _skipped < _to_skip:
			if not _source.advance(batch): return false
			var remaining := _to_skip - _skipped
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

static func iter(array: Array) -> LazyPipe: return LazyPipe.new(ArrayIterator.new(array))
func filter(f: Callable) -> LazyPipe: return LazyPipe.new(FilterIterator.new(_head, f))
func map(f: Callable) -> LazyPipe: return LazyPipe.new(MapIterator.new(_head, f))
func take(n: int) -> LazyPipe: return LazyPipe.new(TakeIterator.new(_head, n))
func skip(n: int) -> LazyPipe: return LazyPipe.new(SkipIterator.new(_head, n))


 
# ==============================================================================
# 🏁 4. ТЕРМИНАЛЬНЫЕ МЕТОДЫ (ВЫВОД)
# ==============================================================================


func to_array() -> Array:
	var result: Array = []
	var batch := PipeBatch.new()
	while _head.advance(batch):
		result.append_array(batch.items)
	return result


func reduce(reductor: Callable, initial: Variant = null) -> Variant:
	var result: Variant = initial
	var batch := PipeBatch.new()
	while _head.advance(batch):
		for item in batch.items:
			result = reductor.call(result, item)
	return result


func any(predicate: Callable) -> bool:
	var batch := PipeBatch.new()
	while _head.advance(batch):
		if batch.items.any(predicate): return true
	return false


func all(predicate: Callable) -> bool:
	var batch := PipeBatch.new()
	while _head.advance(batch):
		if not batch.items.all(predicate): return false
	return true















static func benchmark() -> void:
	var main_loop := Engine.get_main_loop()
	var scene_tree := main_loop as SceneTree
	
	var rest := func() -> void: await scene_tree.create_timer(0.1).timeout if scene_tree else true
	
	var runner := func() -> void:
		print_rich("[color=cyan][b]=== LazyPipe BENCHMARK START (ISOLATED TIMERS) ===[/b][/color]\n")
		
		var test_size := 300_000
		var source_array: Array = []
		source_array.resize(test_size)
		for i in range(test_size):
			source_array[i] = randi_range(1, 1000)
			
		var skip_count := 10_000
		var is_even := func(x: int) -> bool: return x % 2 == 0
		var multiply_by_ten := func(x: int) -> int: return x * 10
		var greater_than_5k := func(x: int) -> bool: return x > 5000

		var _warmup = LazyPipe.iter(source_array).skip(1).filter(is_even).map(multiply_by_ten).filter(greater_than_5k).take(5).to_array()
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
		
		# 1.3 LazyPipe
		time_start = Time.get_ticks_usec()
		var res_lazy := LazyPipe.iter(source_array).skip(skip_count).filter(is_even).map(multiply_by_ten).filter(greater_than_5k).to_array()
		t1_results["LazyPipe"] = Time.get_ticks_usec() - time_start
		
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
		
		# 2.3 LazyPipe
		time_start = Time.get_ticks_usec()
		var res_lazy_take := LazyPipe.iter(source_array).skip(skip_count).filter(is_even).map(multiply_by_ten).filter(greater_than_5k).take(take_count).to_array()
		t2_results["LazyPipe"] = Time.get_ticks_usec() - time_start
		
		_print_benchmark_results(t2_results)
		assert(res_for_take == res_greedy_take and res_greedy_take == res_lazy_take, "Error: TEST 2 results do not match!")
		print_rich("[color=gray]Validation: Results are identical.[/color]\n")
		
		print_rich("[color=cyan][b]=== LazyPipe BENCHMARK END ===[/b][/color]")

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
