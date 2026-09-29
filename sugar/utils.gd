@abstract
extends Object
class_name Utils


#region Utils #################################################################

static func is_node_in_all_groups(node: Node, groups: Array[StringName]) -> bool: return groups and groups.all(node.is_in_group)
static func is_node_in_any_group(node: Node, groups: Array[StringName]) -> bool: return groups.any(node.is_in_group)
static func is_node_not_in_any_group(node: Node, groups: Array[StringName]) -> bool: return not groups.any(node.is_in_group)


static func get_nodes_in_groups(tree: SceneTree, pass_all: Array[StringName] = [], pass_any: Array[StringName] = [], exclude: Array[StringName] = []) -> Array[Node]:
	if not tree or not (pass_all or pass_any): return []
	var first_group: StringName = pass_all[0] if pass_all else pass_any[0]
	var candidates: Array[Node] = tree.get_nodes_in_group(first_group)
	return get_nodes_group_filter(candidates, pass_all, pass_any, exclude)


static func get_nodes_group_filter(nodes: Array[Node], pass_all: Array[StringName] = [], pass_any: Array[StringName] = [], exclude: Array[StringName] = []) -> Array[Node]:
	if not nodes or not (pass_all or pass_any): return []
	if pass_all: nodes = nodes.filter(is_node_in_all_groups.bind(pass_all))
	if pass_any: nodes = nodes.filter(is_node_in_any_group.bind(pass_any))
	if exclude:  nodes = nodes.filter(is_node_not_in_any_group.bind(exclude))
	return nodes



static func call_or_connect(callable: Callable, predicate: Callable, p_signal: Signal) -> void:
	if predicate.call(): callable.call()
	p_signal.connect(callable, CONNECT_ONE_SHOT)


static func is_geometry_instance_on_screen_3d(viewport: Viewport, instance: GeometryInstance3D) -> bool:
	if not viewport: return false
	if not instance or not instance.is_visible_in_tree(): return false
	
	var camera: Camera3D = viewport.get_camera_3d()
	if not camera: return false
	
	var distance_sq: float = camera.global_position.distance_squared_to(instance.global_position)
	if instance.visibility_range_begin > 0.0 and distance_sq < instance.visibility_range_begin * instance.visibility_range_begin: return false
	if instance.visibility_range_end > 0.0 and distance_sq > instance.visibility_range_end * instance.visibility_range_end: return false
	var global_aabb: AABB = instance.global_transform * instance.get_aabb()
	
	return is_aabb_in_convex(camera.get_frustum(), global_aabb)



static func is_dictionary_valid_access(dictionary: Dictionary, key: Variant, only_exists: bool = false) -> bool: return dictionary is Dictionary and (not only_exists or key in dictionary)
static func is_object_valid_access(object: Variant, property: Variant) -> bool: return object is Object and (property is StringName or property is String) and property in object
static func is_array_valid_access(array: Variant, index: Variant) -> bool: return is_array(array) and index is int and Arrays.is_index_valid(array, index) #and [].is_same_typed([])


## Для обновления больших массивов внутри _process с пропусками
## Позволяет итерироваться разреженно
## <= 1: [0, 1, 2, 3,...]
##    2: [0, 2, 4, 6,...]
##    3: [0, 3, 6, 9,...]
##    4: [0, 4, 8, 12,...]
#static func process_dithered_range(count: int, groups: int = 2, offset: int = 0) -> Array:
#	return range(count) if groups <= 1 else range(wrapi(Engine.get_process_frames() + offset, 0, groups), count, groups)

## <= 0: [0, 1, 2, 3,...]
##    1: [0, 2, 4, 6,...]
##    2: [0, 3, 6, 9,...]
##    3: [0, 4, 8, 12,...]
static func _dithered_range(count, skips: int = 0, offset: = 0) -> Array:
	if skips <= 0: return range(count)
	var step: int = skips + 1 
	var start_index = wrapi(offset, 0, step)
	return range(start_index, count, step)

static func process_dithered_range(count: int, skips: int = 0, offset: int = 0) -> Array:
	return _dithered_range(count, skips, Engine.get_process_frames() + offset)


static func clear_children(node: Node, include_internal: bool = false) -> void:
	for child in node.get_children(include_internal):
		child.queue_free()



static func grid_map_get_unused_cells(grid_map: GridMap) -> Array[Vector3i]:
	var used: Array[Vector3i] = grid_map.get_used_cells()
	if used.is_empty(): return []
	
	var start := Vector3i(used.reduce(zip_3d.bind(minf)))
	var end := Vector3i(used.reduce(zip_3d.bind(maxf)))
	
	var used_dict: Dictionary[Vector3i, bool] = Dictionary(Dicts.filled(used, true), TYPE_VECTOR3I, "", null, TYPE_BOOL, "", null)
	var unused: Array[Vector3i] = []
	
	for x in range(start.x, end.x + 1):
		for y in range(start.y, end.y + 1):
			for z in range(start.z, end.z + 1):
				var cell := Vector3i(x, y, z)
				if cell not in used_dict: unused.append(cell)
	
	return unused


static func grid_map_get_aabb(grid_map: GridMap) -> AABB:
	var used := grid_map.get_used_cells()
	if used.is_empty(): return AABB()
	var start := Vector3i(used.reduce(zip_3d.bind(minf)))
	var end := Vector3i(used.reduce(zip_3d.bind(maxf)))
	return AABB(start, start.abs() + end.abs())



enum TableAlignment { LEFT, CENTER, RIGHT }


static func print_table(data: Array, column_count: int, alignment := TableAlignment.LEFT, fill := " ", separator := " | ") -> void:
	var widths := PackedInt32Array()
	widths.resize(column_count)
	widths.fill(0)
	
	for i in len(data):
		var col: int = i % column_count
		widths[col] = maxi(widths[col], len(str(data[i])))
	
	var row := PackedStringArray()
	for i in len(data):
		var col: int = i % column_count
		var txt: String = str(data[i])
		var pad: int = widths[col] - len(txt)
		var left: int = 0 if alignment == TableAlignment.LEFT else (pad if alignment == TableAlignment.RIGHT else pad / 2)
		
		row.append(fill.repeat(left) + txt + fill.repeat(pad - left))
		
		if col == column_count - 1 or i == data.size() - 1:
			print(separator.join(row))
			row.clear()


#static func format_usec(usec: float, decimals: int = 3) -> String:
	#if usec >= 1e6: return String.num(float(usec) / 1e6, decimals) + " sec"
	#if usec >= 1e3: return String.num(float(usec) / 1e3, decimals) + " msec"
	#return "%d usec" % usec

static func format_usec(usec: float, decimals: int = 3) -> String:
	if usec >= 1e6: return String.num(usec / 1e6, decimals) + " (sec)"
	if usec >= 1e3: return String.num(usec / 1e3, decimals) + " (ms)"
	if usec >= 1.0: return String.num(usec, decimals) + " (us)"
	return String.num(usec * 1000.0, decimals) + " (ns)"


static func is_same_typed(value: Variant, ...values: Array) -> bool: return values.map(typeof).all(is_same.bind(typeof(value)))# if values else true


static func toggle_property(object: Object, property: StringName, primary: Variant = true, secondary: Variant = false) -> void:
	object.set(property, toggled(object.get(property), primary, secondary))


static func toggle_indexed(object: Object, property: String, primary: Variant = true, secondary: Variant = false) -> void:
	object.set_indexed(property, toggled(object.get_indexed(property), primary, secondary))


static func swap(object: Object, property_a: StringName, property_b: StringName) -> void:
	if object and property_a in object and property_b in object:
		var a: Variant = object.get(property_a)
		var b: Variant = object.get(property_b)
		object.set(property_a, b)
		object.set(property_b, a)


static func swaps(a: Object, a_property: StringName, b: Object, b_property: StringName) -> void:
	if a and a_property in a and b and b_property in b:
		var a_value: Variant = a.get(a_property)
		var b_value: Variant = b.get(b_property)
		a.set(a_property, b_value)
		b.set(b_property, a_value)


static func shift_property(object: Object, property: StringName, min_value: Variant, max_value: Variant, offset: Variant = 1, wrapped: bool = true) -> void:
	if wrapped: shift_property_wrapped(object, property, min_value, max_value, offset)
	else: shift_property_clamped(object, property, min_value, max_value, offset)


static func shift_property_wrapped(object: Object, property: StringName, min_value: Variant, max_value: Variant, offset: Variant = 1) -> void:
	object.set(property, wrap(object.get(property) + offset, min_value, max_value))


static func shift_property_clamped(object: Object, property: StringName, min_value: Variant, max_value: Variant, offset: Variant = 1) -> void:
	object.set(property, clamp(object.get(property) + offset, min_value, max_value))


static func get_class_property_names(type: StringName, no_inheritance: bool = false, usage: PropertyUsageFlags = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE) -> PackedStringArray:
	return ClassDB.class_get_property_list(type, no_inheritance) \
		.filter(func(p: Dictionary) -> bool: return p.usage & usage) \
		.map(Bound.getter("name"))


static func get_object_property_names(object: Object, usage: PropertyUsageFlags = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE) -> PackedStringArray:
	return [] if not object else object.get_property_list() \
		.filter(func(p: Dictionary) -> bool: return p.usage & usage) \
		.map(Bound.getter("name"))


static func get_object_method_names(object: Object, flags: MethodFlags = MethodFlags.METHOD_FLAGS_DEFAULT) -> PackedStringArray:
	return [] if not object else object.get_method_list() \
		.filter(func(d: Dictionary) -> bool: return d.flags & flags) \
		.map(Bound.getter("name"))


static func transact(
	from: Object, from_property: StringName, 
	to: Object, to_property: StringName, 
	delta: float, 
	take_factor: float = 1.0, give_factor: float = 1.0, 
	from_min: float = 0.0, from_max: float = 1.0, 
	to_min: float = 0.0, to_max: float = 1.0
) -> void:
	
	var from_value: float = from.get(from_property)
	var to_value: float = to.get(to_property)
	
	if to_value < to_min or to_value > to_max: return
	if from_value < from_min or from_value > from_max: return
	
	var allowed_delta_by_from: float = 0.0
	if take_factor > 0.0:
		allowed_delta_by_from = maxf(0.0, from_value - from_min) / take_factor
		
	var allowed_delta_by_to: float = 0.0
	if give_factor > 0.0:
		allowed_delta_by_to = maxf(0.0, to_max - to_value) / give_factor

	var actual_delta: float = minf(delta, allowed_delta_by_from)
	actual_delta = minf(actual_delta, allowed_delta_by_to)
	
	if actual_delta <= 0.0: return

	var taken: float = actual_delta * take_factor
	var given: float = actual_delta * give_factor
	
	from.set(from_property, from_value - taken)
	to.set(to_property, to_value + given)


#static func transact(from: Object, from_property: StringName, to: Object, to_property: StringName, delta: float, give_factor: float = 1.0, from_min: float = 0.0, from_max: float = 1.0, to_min: float = 0.0, to_max: float = 1.0) -> void:
	#
	#var from_value: float = from.get(from_property)
	#var to_value: float = to.get(to_property)
	#
	#if to_value < to_min or to_max > to_max: return
	#
	#var can_take: float = maxf(0.0, from_value - from_min)
	#var can_give: float = maxf(0.0, to_max - to_value)
	#
	#var desired_taken: float = minf(delta, can_take)
	#var desired_given: float = desired_taken * give_factor
	#
	#var given: float = minf(desired_given, can_give)
	#var taken: float = (given / give_factor) if give_factor != 0 else 0.0
	#
	#from.set(from_property, from_value - taken)
	#to.set(to_property, to_value + given)


static func get_resource_or_node(parent: Node, path: NodePath) -> Object:
	if not parent: return null
	
	var found: Array = parent.get_node_and_resource(path)
	
	var node: Node =         found[0]
	var resource: Resource = found[1]
	
	return resource if resource else node


static func object_get_indexed(parent: Node, path: NodePath) -> Variant:
	if not parent: return
	
	var found: Array = parent.get_node_and_resource(path)
	
	var node: Node              = found[0]
	var resource: Resource      = found[1]
	var property_path: NodePath = found[2]
	
	var object: Object = resource if resource else node
	return object.get_indexed(property_path) if object and property_path else object


static func default(value: Variant, default_value: Variant = null, invalid_value: Variant = null) -> Variant:
	return default_value if is_same(value, invalid_value) else value


## (SphereShape3D.new(), Bound.setter("radius", 1_000))
static func with(value: Variant, callable: Callable) -> Variant:
	callable.call(value)
	return value


## (Node3D.new(), { position = Vector3.LEFT, rotation = Vector3(PI, 0, 0) })
static func with_properties(value: Variant, properties: Dictionary[StringName, Variant]) -> Variant:
	for property in properties:
		value.set(property, properties[property])
	return value


static func get_viewport_camera_3d(node: Node) -> Camera3D:
	var viewport: Viewport = node.get_viewport() if node else null
	return viewport.get_camera_3d() if viewport else null


static func get_viewport_or_editor_camera_3d(node: Node, editor_viewport: int = 0) -> Camera3D:
	var viewport: Viewport = EditorInterface.get_editor_viewport_3d(editor_viewport) if Engine.is_editor_hint() else node.get_viewport() if node else null
	return viewport.get_camera_3d() if viewport else null


static func find_child_flat(parent: Node, predicate: Callable, owned: bool = true, include_internal: bool = true) -> Node:
	if not parent: return null
	for i in parent.get_child_count(include_internal):
		var child := parent.get_child(i, include_internal)
		if owned and child.owner != parent.owner and child.owner != parent: continue
		if predicate.call(child): return child
	return null


static func find_child_recursive_dfs(parent: Node, predicate: Callable, owned: bool = true, include_internal: bool = true) -> Node:
	if not parent: return null
	for i in parent.get_child_count(include_internal):
		var child := parent.get_child(i, include_internal)
		if (not owned or child.owner == parent.owner or child.owner == parent) and predicate.call(child): 
			return child
		var found := find_child_recursive_dfs(child, predicate, owned, include_internal)
		if found: return found
	return null


static func find_child_recursive_bfs(parent: Node, predicate: Callable, owned: bool = true, include_internal: bool = true) -> Node:
	var found := find_child_flat(parent, predicate, owned, include_internal)
	if found: return found
	for i in parent.get_child_count(include_internal):
		found = find_child_recursive_bfs(parent.get_child(i, include_internal), predicate, owned, include_internal)
		if found: return found
	return null


static func is_instance_of_string(obj: Object, type_string: String) -> bool:
	if not obj: return false
	if obj.is_class(type_string): return true
	
	var script: Script = obj.get_script()
	
	while script:
		if script.get_global_name() == type_string: return true
		script = script.get_base_script()
	
	return false


## >>	create_children(self, [
## >>		Node.new(),
## >>		range(3).map(Node.new.unbind(1)),
## >>		{ type = Node, name = "Node",
## >>			get_children = [
## >>				{ type = Node3D, position = Vector3.ONE},
## >>				Node.new() }])
static func create_children(parent: Node, children_data: Array) -> void:
	for data: Variant in children_data:
		if data is Node: parent.add_child(data)
		elif data is Array: create_children(parent, data)
		elif data is Dictionary:
			var node: Node = data.type.new()
			for property: String in data:
				match property:
					&"type": continue
					&"get_children": create_children(node, data.get_children)
					_:  node.set(property, data[property])
			parent.add_child(node)


#endregion Utils ###############################################################
#region Operator ###############################################################


static func setted(object: Object, property: StringName, value: Variant) -> Object:
	if object: object.set(property, value)
	return object


static func is_number(what: Variant) -> bool: return typeof(what) in [TYPE_FLOAT, TYPE_INT]


static func is_vector(what: Variant) -> bool: return typeof(what) in [
	TYPE_VECTOR2, TYPE_VECTOR2I,
	TYPE_VECTOR3, TYPE_VECTOR3I,
	TYPE_VECTOR4, TYPE_VECTOR4I]


static func is_array(what: Variant) -> bool: return typeof(what) in [
	TYPE_ARRAY,
	TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY,
	TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY,
	TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_VECTOR4_ARRAY,
	TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_COLOR_ARRAY]


static func is_sequence(what: Variant) -> bool:
	return is_array(what) or is_vector(what) or typeof(what) in [TYPE_STRING, TYPE_STRING_NAME, TYPE_COLOR]


#endregion Operator ############################################################
#region Math ###################################################################


static func lerp3(a: Variant, b: Variant, c: Variant, weight: float) -> float:
	var clamped_weight: float = clampf(weight, 0.0, 1.0)
	return lerp(a, b, clamped_weight * 2.0) if clamped_weight < 0.5 else lerp(b, c, clamped_weight * 2.0 - 1.0)


# Arrays.safe_reduce([...], Funcs.zip_3d.bind(minf)) -> вектор минимальных компонент
# ((0,1,2), (2,1,0), min) => (0,1,0)
static func zip_3d(a: Vector3, b: Vector3, comparator: Callable) -> Vector3:
	return Vector3(comparator.call(a.x, b.x), comparator.call(a.y, b.y), comparator.call(a.z, b.z))


static func vector3_wrap(value: Vector3, min_value: Vector3, max_value: Vector3) -> Vector3:
	return Vector3(
		wrapf(value.x, min_value.x, max_value.x),
		wrapf(value.y, min_value.y, max_value.y),
		wrapf(value.z, min_value.z, max_value.z),
	)

static func vector3_wrapf(value: Vector3, min_value: float, max_value: float) -> Vector3:
	return Vector3(
		wrapf(value.x, min_value, max_value),
		wrapf(value.y, min_value, max_value),
		wrapf(value.z, min_value, max_value),
	)

static func cwrapf(value: float, min: float, max: float) -> float: return max if is_equal_approx(value, max) else wrapf(value, min, max)


static func roundf_to(value: float, decimals: int = 0) -> float:
	return snappedf(value, 10.0 ** -decimals)


static func ceilf_to(value: float, decimals: int = 0) -> float:
	var multiplier: float = 10.0 ** decimals
	return ceilf(value * multiplier) / multiplier


static func floorf_to(value: float, decimals: int = 0) -> float:
	var multiplier: float = 10.0 ** decimals
	return floorf(value * multiplier) / multiplier


static func is_closer(from: float, to: float, than: float) -> bool: return absf(from - to) < absf(from - than)
static func get_closest(from: float, a: float, b: float) -> float: return a if absf(from - a) < absf(from - b) else b
static func get_furthest(from: float, a: float, b: float) -> float: return a if absf(from - a) > absf(from - b) else b

static func get_nearest_2d(from: Vector2, a: Vector2, b: Vector2) -> Vector2: return a if from.distance_squared_to(a) < from.distance_squared_to(b) else b
static func get_nearest_3d(from: Vector3, a: Vector3, b: Vector3) -> Vector3: return a if from.distance_squared_to(a) < from.distance_squared_to(b) else b


static func remap_clamped(value: float, istart: float, istop: float, ostart: float, ostop: float) -> float:
	return clampf(remap(value, istart, istop, ostart, ostop), minf(ostart, ostop), maxf(ostart, ostop))

static func remap_wrapped(value: float, istart: float, istop: float, ostart: float, ostop: float) -> float:
	return wrapf(remap(value, istart, istop, ostart, ostop), ostart, ostop)

static func toggled(value: Variant, primary: Variant = true, secondary: Variant = false) -> Variant:
	return primary if value != primary else secondary

static func align_basis(basis: Basis, vector: Vector3, axis: Vector3.Axis = Vector3.AXIS_Y) -> Basis:
	var direction: Vector3 = vector.normalized()
	var x: Vector3 = basis.x
	var y: Vector3 = basis.y
	var z: Vector3 = basis.z

	match axis:
		Vector3.AXIS_X:
			x = direction
			y = (basis.y - x * basis.y.dot(x)).normalized()
			z = x.cross(y).normalized()
		Vector3.AXIS_Y:
			y = direction
			x = (basis.x - y * basis.x.dot(y)).normalized()
			z = x.cross(y).normalized()
		Vector3.AXIS_Z:
			z = direction
			x = (basis.x - z * basis.x.dot(z)).normalized()
			y = z.cross(x).normalized()
	
	return Basis(x, y, z)


static func clamp_basis(a: Basis, b: Basis, a_axis := Vector3.FORWARD, max_angle: float = PI) -> Basis:
	var v1: Vector3 = a * a_axis
	var v2: Vector3 = b * a_axis
	var angle: float = v1.angle_to(v2)
	if angle <= max_angle: return b
	var q := Quaternion(v1, v2)
	var q_clamped: Quaternion = Quaternion(q.get_axis(), max_angle)
	return Basis(q_clamped) * a


static func point_rotated_around(point: Vector3, axis: Vector3, angle: float, pivot: Vector3 = Vector3.ZERO) -> Vector3:
	return pivot + (point - pivot).rotated(axis, angle)


static func transform_rotated_around(transform: Transform3D, axis: Vector3, angle: float, point: Vector3) -> Transform3D:
	return Transform3D(
		transform.basis.rotated(axis, angle),
		point + (transform.origin - point).rotated(axis, angle))


static func transform_euler_rotated_around(transform: Transform3D, global_euler: Vector3, point: Vector3) -> Transform3D:
	var rotation_transform := Transform3D(Basis.from_euler(global_euler), Vector3.ZERO)
	var pivot_transform := Transform3D(Basis(), point) * rotation_transform * Transform3D(Basis(), -point)
	return pivot_transform * transform


static func centered_2d(vector: Vector2) -> Vector2: return (vector - Vector2.ONE) * 0.5
static func centered_3d(vector: Vector3) -> Vector3: return (vector - Vector3.ONE) * 0.5


static func clamp_length_3d(vector: Vector3, min_length: float = 0.0, max_length: float = 1.0, default_direction := Vector3.ZERO) -> Vector3:
	var direction: Vector3 = default_direction if vector.is_zero_approx() else vector.normalized()
	return direction * clampf(vector.length(), min_length, max_length)


static func clamp_distance_3d(a: Vector3, b: Vector3, min_distance: float, max_distance: float, default_direction := Vector3.ZERO) -> Vector3:
	var direction: Vector3 = default_direction if a.is_equal_approx(b) else a.direction_to(b)
	return a + direction * clampf(a.distance_to(b), min_distance, max_distance)


#static func clamp_distance_3d(a: Vector3, b: Vector3, min_distance: float, max_distance: float) -> Vector3:
	#var length: float = a.distance_to(b)
	#return a if is_zero_approx(length) else b + b.direction_to(a) * clampf(length, min_distance, max_distance)


static func get_noise_gradient(noise: Noise, point: Vector3, delta: float = 0.01) -> Vector3:
	if not noise or is_zero_approx(delta): return Vector3.ZERO
	
	var base_noise := noise.get_noise_3dv(point)
	
	var grad_x := noise.get_noise_3dv(point + Vector3(delta, 0, 0)) - base_noise
	var grad_y := noise.get_noise_3dv(point + Vector3(0, delta, 0)) - base_noise
	var grad_z := noise.get_noise_3dv(point + Vector3(0, 0, delta)) - base_noise
	
	return Vector3(grad_x, grad_y, grad_z) / delta


#region Interpolation ##########################################################


## log_lerpf
static func glerpf(a: float, b: float, weight: float) -> float:
	a = maxf(a, 1e-3)
	b = maxf(b, 1e-3)
	return a * pow(b / a, weight)


static func lerp_2d(a: Vector2, b: Vector2, weight: Vector2) -> Vector2:
	return Vector2(lerpf(a.x, b.x, weight.x), lerpf(a.y, b.y, weight.y))


static func lerp_3d(a: Vector3, b: Vector3, weight: Vector3) -> Vector3:
	return Vector3(lerpf(a.x, b.x, weight.x), lerpf(a.y, b.y, weight.y), lerpf(a.z, b.z, weight.z))


# b + (a - b) * exp(-decay * delta)
# Critically Damped Spring
# Frame-rate independent Lerp
static func exp_decay_f(a: float, b: float, delta: float) -> float: return lerp(a, b, 1.0 - exp(-delta))
static func exp_decay_v2(a: Vector2, b: Vector2, delta: float) -> Vector2: return a.lerp(b, 1.0 - exp(-delta))
static func exp_decay_v3(a: Vector3, b: Vector3, delta: float) -> Vector3: return a.lerp(b, 1.0 - exp(-delta))


# hookes_law_f:
#static func damped_spring_f(displacement: float, current_velocity: float, stiffness: float, damping: float) -> float:
	#return (stiffness * displacement) - (damping * current_velocity)

# hookes_law_v3:
static func damped_spring_3d(displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)


static func limit_distance_2d(a: Vector2, b: Vector2, max_distance: float) -> Vector2:
	return b + (a - b).limit_length(max_distance)

static func limit_distance_3d(a: Vector3, b: Vector3, max_distance: float) -> Vector3:
	return b + (a - b).limit_length(max_distance)


static func lerpf_clamped(a: float, b: float, weight: float) -> float:
	return clampf(lerpf(a, b, weight), a, b)


## English: 32 - 126
## Russion: 1040 - 1103
static func interpolate_string(from: String, to: String, weight: float, min_char: int = 32, max_char: int = 1103) -> String:
	var result := ""
	var new_length := roundi(lerpf(len(from), len(to), weight))
	for i in new_length:
		var t: float = i / float(maxi(new_length - 1, 1))
		var code_from := ord(from[roundi(t * (len(from) - 1))])
		var code_to := ord(to[roundi(t * (len(to) - 1))])
		result += char(wrapi(roundi(lerpf(code_from, code_to, weight)), min_char, max_char + 1))
	return result


#static func resource_interpolator(a: Variant, b: Variant, weight: float) -> Variant:
	#match typeof(a):
		#TYPE_INT, TYPE_FLOAT: return lerp(a, b, weight)
		#TYPE_STRING, TYPE_STRING_NAME: return lerp_string(a, b, weight)
		#TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_VECTOR3, TYPE_VECTOR3I, TYPE_VECTOR4, TYPE_VECTOR4I, TYPE_COLOR: return a.lerp(b, weight)
	#return null


static func interpolate_resources(a: Resource, b: Resource, weight: float, interpolator: Callable = lerp, deep: bool = false) -> Resource:
	if not a and not b: return null
	if a and not b: return a
	if b and not a: return b
	
	var resource_property_names: PackedStringArray = ClassDB.class_get_property_list("Resource").map(Bound.getter("name"))
	var property_names: PackedStringArray = Array(get_object_property_names(a)).filter(Bound.not_inside(resource_property_names))
	var result := a.duplicate()
	
	for property: StringName in property_names:
		var a_value: Variant = a.get(property)
		var b_value: Variant = b.get(property)
		var interpolated_value: Variant = (interpolate_resources(a_value, b_value, weight, interpolator, deep)
			if deep and is_instance_of(a_value, Resource) else interpolator.call(a_value, b_value, weight))
		result.set(property, interpolated_value)
	
	return result


#endregion Interpolation #######################################################
#endregion Math ################################################################
#region Iteration ##############################################################


static func do_while(callable: Callable, predicate: Callable, max_repeats: int = INF, result_as_parameter: bool = false, default: Variant = null) -> Variant:
	var value: Variant = default
	
	var i: int = 0
	while i < max_repeats:
		value = callable.call(value) if result_as_parameter else callable.call()
		if predicate.call(value): return value
		i += 1
	
	return default


#endregion Iteration ###########################################################
#region Geometry ###############################################################

func is_aabb_in_convex_project(aabb: AABB, planes: Array[Plane]) -> bool:
	for plane in planes:
		var support := aabb.get_support(plane.normal)
		if (support - plane.project(support)).dot(plane.normal) > 0.0:
			return false
	return true


static func is_aabb_in_convex(planes: Array[Plane], aabb: AABB) -> bool:
	
	for plane: Plane in planes:
		# Slowest:
		#if plane.is_point_over(global_aabb.get_support(-plane.normal)): return false
		
		# Middle:
		#if plane.normal.dot(aabb.get_support(plane.normal)) + plane.d < 0.0: return false
		
		# Faster:
		#if plane.distance_to(aabb.get_support(plane.normal)) < 0.0: return false
		
		# Fastest:
		var support := aabb.get_support(plane.normal)
		if (support - plane.project(support)).dot(plane.normal) > 0.0: return false
		
	return true


static func is_point_in_convex(planes: Array[Plane], point: Vector3) -> bool:
	for plane in planes:
		if plane.distance_to(point) < 0.0: return false
	return true



static func cosine_similarity(a: Variant, b: Variant) -> float:
	var a_type: int = typeof(a)
	if a_type == typeof(b) and a_type in [TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4]:
		return (0.0 if a.is_zero_approx() or b.is_zero_approx() else a.dot(b) / (a.length() * b.length()))
	push_error("cosine_similarity(%s, %s): a and b must be same typed vectors" % [str(a), str(b)])
	return 0.0


static func sample_triangle_2d(o: Vector2, a: Vector2, b: Vector2, u: float, v: float) -> Vector2:
	return o + u * (a - o) + v * (b - o)

static func sample_triangle_3d(o: Vector3, a: Vector3, b: Vector3, u: float, v: float) -> Vector3:
	return o + u * (a - o) + v * (b - o)


# WARNING: UNTESTED!
static func get_cross_point_2d(x_start: Vector2, x_end: Vector2, y_start: Vector2, y_end: Vector2, x: float, y: float) -> Vector2:
	var p_x: Vector2 = x_start.lerp(x_end, x)
	var p_y: Vector2 = y_start.lerp(y_end, y)
	var d_x: Vector2 = x_end - x_start
	var d_y: Vector2 = y_end - y_start
	var denom: float = d_x.cross(d_y)
	if absf(denom) < 1e-6:
		return p_x
	var t: float = (p_y - p_x).cross(d_x) / denom
	return p_x + t * d_y



# WARNING: UNTESTED!
func get_triangle_point_2d(o: Vector2, a: Vector2, b: Vector2, uv: Vector2) -> Vector2:
	var u: float = uv.x * (1.0 - uv.y * (5.0 - uv.x - uv.y) / 6.0)
	var v: float = uv.y * (1.0 - uv.x * (5.0 - uv.x - uv.y) / 6.0)
	return sample_triangle_2d(o, a, b, u, v)



static func compute_normals(vertices: PackedVector3Array, indices: PackedInt32Array) -> PackedVector3Array:
	var normals: PackedVector3Array
	normals.resize(len(vertices))
	
	for i in range(0, len(indices), 3):
		var a: Vector3 = vertices[indices[i]]
		var b: Vector3 = vertices[indices[i + 1]]
		var c: Vector3 = vertices[indices[i + 2]]
		
		var normal: Vector3 = (b - a).cross(c - a).normalized()
		
		normals[indices[i]] += normal
		normals[indices[i + 1]] += normal
		normals[indices[i + 2]] += normal
	
	for i in len(normals):
		normals[i] = -normals[i].normalized()
	
	return normals


static func compute_tangents(normals: PackedVector3Array) -> PackedFloat32Array:
	var vertex_count: int = len(normals)
	var tangents: PackedFloat32Array
	tangents.resize(vertex_count * 4)
	
	for i: int in range(vertex_count):
		# Тангенс вдоль оси X (для карты высот)
		var tangent: Vector3 = Vector3.RIGHT
		
		# Ортогонализация к нормали
		var dot: float = tangent.dot(normals[i])
		tangent = (tangent - normals[i] * dot).normalized()
		
		var idx: int = i * 4
		tangents[idx + 0] = tangent.x
		tangents[idx + 1] = tangent.y
		tangents[idx + 2] = tangent.z
		tangents[idx + 3] = 1.0  # w = +1 (бинормаль направлена правильно)
	
	return tangents


#static func merge_meshes(meshes: Array[Mesh]) -> ArrayMesh:
	#
	#var am := ArrayMesh.new()
	#
	#for mesh: Mesh in meshes.filter(is_instance_valid):
		#for surface in mesh.get_surface_count():
			#
#
			#var blend_shapes: Array[Array] = mesh.surface_get_blend_shape_arrays(surface)
			#am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, blend_shapes)
			#
			#var material: Material = mesh.surface_get_material(surface)
			#am.surface_set_material(surface, material)
	#
	#return am


static func _get_face_distribution(faces: PackedVector3Array, count: int) -> PackedInt32Array:
	if count <= 0 or faces.is_empty() or len(faces) % 3 != 0:
		return []
	
	var areas: PackedFloat32Array = range(0, len(faces), 3).map(
		func(i: int) -> float:
			var ab: Vector3 = faces[i+1] - faces[i]
			var ac: Vector3 = faces[i+2] - faces[i]
			return 0.5 * ab.cross(ac).length()
	)
	
	var normalized_areas: PackedFloat32Array = Arrays.vector_normalized(areas)
	var weights: Array[float] = Array(Array(normalized_areas).map(Operator.mulf.bind(count)), TYPE_FLOAT, "", null)
	var on_face_counts: Array[int] = Array(weights.map(floori), TYPE_INT, "", null)
	
	var remaining := count - Arrays.sumi(on_face_counts)
	if remaining > 0:
		var remainders := Array(weights.map(func(w: float) -> float: return w - float(floori(w))), TYPE_FLOAT, "", null)
		var indices := range(len(remainders))
		indices.sort_custom(func(i: int, j: int) -> bool: return remainders[i] > remainders[j])
		for i in range(remaining):
			on_face_counts[indices[i]] += 1
	
	return on_face_counts

	#var transforms: Array[Transform3D]
	#
	#for face_idx in len(on_face_counts):
		#var on_face_count: int = on_face_counts[face_idx]
		#for i in on_face_count:
			#var a: Vector3 = faces[face_idx * 3 + 0]
			#var b: Vector3 = faces[face_idx * 3 + 1]
			#var c: Vector3 = faces[face_idx * 3 + 2]
			#var origin: Vector3 = Funcs.rand_in_triangle_3d(a, b, c)
			#
			#var ab: Vector3 = b - a
			#var ac: Vector3 = c - a
			#var normal: Vector3 = ab.cross(ac).normalized()
			#var x: Vector3 = Vector3.RIGHT if abs(normal.y) < 0.99 else Vector3.FORWARD
			#var basis := Basis(x, normal, normal.cross(x))
			#
			#transforms.append(Transform3D(basis, origin))
	#
	#return transforms


static func scatter_points_on_faces(faces: PackedVector3Array, count: int) -> PackedVector3Array:
	var positions: PackedVector3Array = []
	var on_face_counts := _get_face_distribution(faces, count)
	
	for face_idx in len(on_face_counts):
		var a: Vector3 = faces[face_idx * 3 + 0]
		var b: Vector3 = faces[face_idx * 3 + 1]
		var c: Vector3 = faces[face_idx * 3 + 2]
		for i in on_face_counts[face_idx]:
			positions.append(Random.rand_in_triangle_3d(a, b, c))
	
	return positions


static func scatter_transforms_on_faces(faces: PackedVector3Array, count: int) -> Array[Transform3D]:
	var transforms: Array[Transform3D] = []
	var on_face_counts := _get_face_distribution(faces, count)
	
	for face_idx in len(on_face_counts):
		var a: Vector3 = faces[face_idx * 3 + 0]
		var b: Vector3 = faces[face_idx * 3 + 1]
		var c: Vector3 = faces[face_idx * 3 + 2]
		
		var ab: Vector3 = b - a
		var ac: Vector3 = c - a
		var normal: Vector3 = ab.cross(ac).normalized()
		var tangent: Vector3 = Vector3.RIGHT if abs(normal.y) < 0.99 else Vector3.FORWARD
		var basis: Basis = Basis(tangent, normal, normal.cross(tangent))
		
		for i in on_face_counts[face_idx]:
			var origin: Vector3 = Random.rand_in_triangle_3d(a, b, c)
			transforms.append(Transform3D(basis.rotated(Vector3.UP, randf() * TAU), origin))
	
	return transforms



static func polyline_snapped(polyline: PackedVector3Array, step: Vector3, first_point: bool = true, last_point: bool = true) -> PackedVector3Array:
	if polyline.size() <= 1: return polyline.duplicate()
	
	var result: PackedVector3Array = PackedVector3Array()
	var total_segments: int = polyline.size() - 1
	
	for i in total_segments:
		var grid_start: Vector3 = polyline[i].snapped(step)
		var grid_end: Vector3 = polyline[i + 1].snapped(step)
		
		if i == 0 and first_point: result.append(grid_start)
		elif result.size() > 0 and result[-1] != grid_start: result.append(grid_start)
		if grid_start == grid_end: continue
		
		var current_point: Vector3 = grid_start
		var delta_pos: Vector3 = grid_end - grid_start
		
		var grid_step: Vector3 = delta_pos.sign() * step
		var axis_steps: Vector3 = Operator.safe_div_3d(delta_pos, step, Vector3.ZERO).abs()
		
		var total_steps: int = int(axis_steps.x + axis_steps.y + axis_steps.z)
		
		var t_delta: Vector3 = Vector3(
			1.0 / axis_steps.x if axis_steps.x > 0.0 else INF,
			1.0 / axis_steps.y if axis_steps.y > 0.0 else INF,
			1.0 / axis_steps.z if axis_steps.z > 0.0 else INF)
		
		var t_next: Vector3 = t_delta * 0.5
		
		for step_index in total_steps:
			if t_next.x < t_next.y:
				if t_next.x < t_next.z:
					current_point.x += grid_step.x
					t_next.x += t_delta.x
				else:
					current_point.z += grid_step.z
					t_next.z += t_delta.z
			else:
				if t_next.y < t_next.z:
					current_point.y += grid_step.y
					t_next.y += t_delta.y
				else:
					current_point.z += grid_step.z
					t_next.z += t_delta.z
					
			result.append(current_point)

	if result.size() > 0:
		if not first_point:
			result.remove_at(0)
		if result.size() > 0 and not last_point:
			result.remove_at(result.size() - 1)
				
	return result



# WARNING: UNTESTED
## в отличии от polyline_snapped, step - ось (направление)
static func resample_polyline(polyline: PackedVector3Array, step: Vector3, first_point: bool = true, last_point: bool = true) -> PackedVector3Array:
	if polyline.size() <= 1: return polyline.duplicate()
	
	var dir: Vector3 = step.normalized()
	var length: float = absf(step.length())
	if is_zero_approx(length): return polyline.duplicate()
	
	var result: PackedVector3Array = []
	
	for i in range(1, polyline.size()):
		var p1: Vector3 = polyline[i-1]
		var p2: Vector3 = polyline[i]
		var v1: float = p1.dot(dir)
		var v2: float = p2.dot(dir)
		
		if is_zero_approx(v2 - v1): continue
		
		var min_v: float = minf(v1, v2)
		var max_v: float = maxf(v1, v2)
		var k: int = ceili(min_v / length)
		
		while k * length <= max_v:
			var t: float = (k * length - v1) / (v2 - v1)
			var pt: Vector3 = p1.lerp(p2, clampf(t, 0.0, 1.0))
			
			if result.size() == 0 or not pt.is_equal_approx(result[-1]):
				result.append(pt)
			k += 1
	
	if last_point and result.size() > 0:
		var last_orig: Vector3 = polyline[-1]
		if not last_orig.is_equal_approx(result[-1]):
			result.append(last_orig)
	
	return result


static func smooth_curve_3d(curve: Curve3D, tension: float) -> void:
	var count: int = curve.get_point_count()
	if count < 2: return
	
	for i: int in range(count):
		var pos: Vector3 = curve.get_point_position(i)
		var prev: Vector3 = curve.get_point_position(i - 1) if i > 0 else pos * 2.0 - curve.get_point_position(1)
		var next: Vector3 = curve.get_point_position(i + 1) if i < count - 1 else pos * 2.0 - curve.get_point_position(count - 2)
		
		var tangent: Vector3 = (next - prev).normalized()
		curve.set_point_out(i, tangent * pos.distance_to(next) * tension)
		curve.set_point_in(i, -tangent * pos.distance_to(prev) * tension)


static func get_smoothed_curve_3d(curve: Curve3D, tension: float) -> Curve3D:
	var result: Curve3D = curve.duplicate()
	smooth_curve_3d(result, tension)
	return result


#endregion Geometry ###########################################################
#region Physics #################################################################


static func get_point_velocity(body: RigidBody3D, world_point: Vector3) -> Vector3:
	return body.linear_velocity + body.angular_velocity.cross(world_point - body.global_position)


static func kelvin_to_rgb(kelvin: float) -> Color:
	var t: float = kelvin / 100.0
	var color: Color = Color.BLACK
	
	if t <= 66.0: color.r = 1.0
	else: color.r = 1.292936 * pow(t - 60.0, -0.1332047)
	
	if t <= 66.0: color.g = 0.994708 * log(t) - 1.61119
	else: color.g = 1.129890 * pow(t - 60.0, -0.107167)
	
	if t >= 66.0: color.b = 1.0
	elif t <= 19.0: color.b = 0.0
	else: color.b = 0.82106082 * log(t - 10.0) - 0.138013
	
	return color.clamp(Color.BLACK, Color.WHITE)


#endregion Physics ###############################################################
#region Audio #################################################################


static func bus_effect_find_index(bus_idx: int, effect: AudioEffect) -> int:
	return range(AudioServer.get_bus_effect_count(bus_idx)).find_custom(
		func(i: int) -> bool: return is_same(AudioServer.get_bus_effect(bus_idx, i), effect))


static func bus_effect_erase(bus_idx: int, effect: AudioEffect) -> bool:
	var effect_idx: int = bus_effect_find_index(bus_idx, effect) if bus_idx != -1 and effect else -1
	if effect_idx == -1: return false
	AudioServer.remove_bus_effect(bus_idx, effect_idx)
	return true


static func bus_effect_set_enabled(bus_idx: int, effect: AudioEffect, enabled: bool) -> bool:
	var effect_idx: int = bus_effect_find_index(bus_idx, effect) if bus_idx != -1 and effect else -1
	if effect_idx == -1: return false
	AudioServer.set_bus_effect_enabled(bus_idx, effect_idx, enabled)
	return true


#endregion Audio ##############################################################
#region Performance ###########################################################


static func get_call_time_usec(callable: Callable, repeats: int = 1) -> int:
	var start: int = Time.get_ticks_usec()
	for i: int in repeats:
		callable.call()
	return Time.get_ticks_usec() - start


static func benchmark(callable: Callable, repeats: int = 1) -> void:
	var usec: float = get_call_time_usec(callable, repeats)
	print()
	print(callable)
	prints("total:\t", format_usec(usec))
	prints("avg:\t", format_usec(usec / repeats))


#endregion Performance ########################################################
#region Data ##################################################################


# UNTESTED:
static func directory_get_typed_resources(path: String, type: String, max_file_count: int = 5, valid_extensions: PackedStringArray = []) -> Array[Resource]:
	if valid_extensions.is_empty():
		valid_extensions = ResourceLoader.get_recognized_extensions_for_type(type)
	var directory := DirAccess.open(path)
	if not directory:
		push_error("The directory does not exist: ", path)
		return []
	
	var directory_files: Array = DirAccess.get_files_at(path)
	var valid_extention_files: Array = directory_files.filter(func(a: String): return a.get_extension().to_lower() in valid_extensions)
	var picked_files: Array = Random.random_sample(valid_extention_files, mini(len(directory_files), max_file_count))
	
	var valid_resources: Array[Resource]
	valid_resources.assign(picked_files.map(
		func(file_name: String) -> AudioStream:
			var file_path: String = path.path_join(file_name)
			var loaded_resource: Resource = load(file_path) as Resource
			return loaded_resource if loaded_resource and loaded_resource.is_class(type) else null
	).filter(is_instance_valid))
	
	return valid_resources


func get_bones_at_depth(skeleton: Skeleton3D, target_depth: int) -> PackedInt32Array:
	if skeleton == null or target_depth < 0:
		return []
	
	var bone_count := skeleton.get_bone_count()
	var depths: PackedInt32Array
	depths.resize(bone_count)
	
	var result: PackedInt32Array
	
	for i in bone_count:
		var parent: int = skeleton.get_bone_parent(i)
		var current_depth: int = 0 if parent == -1 else depths[parent] + 1
		depths[i] = current_depth
		if current_depth == target_depth: result.append(i)
	
	return result


static func get_linear_curve(a: Vector2 = Vector2.ZERO, b: Vector2 = Vector2.ONE) -> Curve:
	var curve := Curve.new()
	curve.add_point(a, 1, 1, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	curve.add_point(b, 1, 1, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	return curve


#endregion Data ################################################################
