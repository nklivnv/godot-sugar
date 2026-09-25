@abstract class_name Random extends Object


class NumberGenerator extends RandomNumberGenerator:
	
	func random_quaternion() -> Quaternion:
		var u1 := self.randf() * TAU
		var u2 := self.randf() * 2.0 - 1.0
		var r := sqrt(1.0 - u2 * u2)
		var q_swing := Quaternion(Vector3.FORWARD, Vector3(r * cos(u1), r * sin(u1), u2))
		var q_twist := Quaternion(Vector3.FORWARD, self.randf() * TAU)
		return q_swing * q_twist


# --- 1D ---

static func pick_unique(from: int, to: int, count: int) -> PackedInt32Array:
	var total: int = to - from + 1
	var n: int = min(count, total) # если диапазон меньше, берем сколько есть
	
	var res := PackedInt32Array()
	res.resize(n)
	
	var map := {}
	for i in range(n):
		var r := randi_range(i, total - 1)
		res[i] = map.get(r, r + from)
		map[r] = map.get(i, i + from)
		
	return res




static func randi_range_avoid(a: int, b: int, avoid: int, default: int = a) -> int:
	var left := mini(a, b)
	var right := maxi(a, b)
	if avoid < left or avoid > right: return randi_range(left, right)
	if left == right: return default
	var r := randi_range(left, right - 1)
	return r if r < avoid else r + 1


static func randi_range_avoids(a: int, b: int, avoid: PackedInt32Array, default: int = a) -> int:
	var r := range(min(a, b), max(a, b) + 1).filter(Operator.not_inside.bind(avoid))
	return r.pick_random() if r else default


#static func randf_snapped(min_value: float, max_value: float, step: float) -> float:
	#return snappedf(randf_range(min_value, max_value), step)

#static func randf_stepped(min_value: float, max_value: float, steps: int) -> float:
	#if steps < 1: return min_value
	#var step_size: float = (max_value - min_value) / steps
	#var random_step: int = randi() % (steps + 1)
	#return min_value + step_size * random_step


#static func item_random_quality(quality: float) -> float:
	#quality = clampf(quality, 0.0, 1.0)
	#return pow(randf(), (1.0 - quality) / quality) if quality > 0.0 else 0.0


# --- 2D ---


static func rand_on_circle() -> Vector2:
	var angle: float = randf_range(0.0, TAU)
	return Vector2(cos(angle), sin(angle))


static func rand_in_circle(min_radius: float = 0.0, max_radius: float = 0.5) -> Vector2:
	var radius: float = randf_range(min_radius, max_radius)
	var angle: float = randf_range(0.0, TAU)
	return radius * Vector2(cos(angle), sin(angle))


static func rand_in_triangle_2d(o: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var u := randf()
	var v := randf()
	if u + v > 1.0:
		u = 1.0 - u
		v = 1.0 - v
	return Utils.sample_triangle_2d(o, a, b, u, v)


# --- 3D ---

static func randv3() -> Vector3: return Vector3(randf(), randf(), randf())


static func randv3_centered(size := Vector3.ONE) -> Vector3:
	return size * (Vector3(randf(), randf(), randf()) - Vector3.ONE * 0.5)


static func randv3_range(a := -Vector3.ONE, b := Vector3.ONE) -> Vector3:
	return Vector3(randf_range(a.x, b.x), randf_range(a.y, b.y), randf_range(a.z, b.z))


static func randv3i_range(min: Vector3i, max: Vector3i) -> Vector3i:
	return Vector3i(randi_range(min.x, max.x), randi_range(min.y, max.y), randi_range(min.z, max.z))


#static func rand_in_ellipsoid(radiuses := Vector3.ONE) -> Vector3:
	#while true:
		#var vector := Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		#if vector.length_squared() < 1.0: return vector * radiuses
	#return Vector3.ZERO


static func rand_on_sphere() -> Vector3:
	return Vector3(randfn(0.0, 1.0), randfn(0.0, 1.0), randfn(0.0, 1.0)).normalized()


#func rand_on_sphere() -> Vector3:
	#var z = randf_range(-1.0, 1.0)
	#var t = randf_range(0.0, TAU)
	#var r = sqrt(1.0 - z*z)
	#return Vector3(r * cos(t), r * sin(t), z)

#static func rand_on_sphere() -> Vector3:
	#var phi: float = acos(randf_range(-1, 1))
	#var theta: float = randf_range(0, TAU)
	#return Vector3(
		#sin(phi) * cos(theta),
		#sin(phi) * sin(theta),
		#cos(phi))



static func rand_in_sphere_uniform(min_radius: float = 0.0, max_radius: float = 1.0) -> Vector3:
	return rand_on_sphere() * pow(randf_range(min_radius**3, max_radius**3), 1.0 / 3.0)
	#return rand_on_sphere() * pow(randf(), 1.0 / 3.0)


#static func rand_in_sphere_power(peak_density_radius: float = 0.0, zero_density_radius: float = 1.0, power: float = 4.0) -> Vector3:
	#return rand_on_sphere() * lerp(peak_density_radius, zero_density_radius, pow(randf(), power))


#static func rand_in_sphere_exp(min_radius: float = 0.0, max_radius: float = 1.0) -> Vector3:
	#return rand_on_sphere() * log(randf_range(exp(min_radius), exp(max_radius)))

static func rand_in_sphere_exp2(min_radius: float = 0.0, max_radius: float = 1.0, min_density: float = 1.0, max_density: float = 0.0) -> Vector3:
	var a := remap(min_radius, max_density, min_density, 0.0, 3.0)
	var b := remap(max_radius, max_density, min_density, 0.0, 3.0)
	var t := -log(randf_range(exp(-a), exp(-b)))
	return rand_on_sphere() * remap(t, 0.0, 3.0, max_density, min_density)



static func rand_in_sphere_linear(peak_density_radius: float = 0.0, zero_density_radius: float = 1.0) -> Vector3:
	return rand_on_sphere() * lerp(peak_density_radius, zero_density_radius, sqrt(randf()))

static func rand_in_sphere_linear2(min_radius: float = 0.0, max_radius: float = 1.0, min_density: float = 1.0, max_density: float = 0.0) -> Vector3:
	var a := remap(min_radius, max_density, min_density, 1.0, 0.0)
	var b := remap(max_radius, max_density, min_density, 1.0, 0.0)
	var t := 1.0 - sqrt(a*a - randf() * (a*a - b*b))
	return rand_on_sphere() * remap(t, 0.0, 1.0, max_density, min_density)



static func rand_in_box(size := Vector3.ONE) -> Vector3: return randv3_centered(size)


static func rand_on_box(size: Vector3 = Vector3.ONE) -> Vector3:
	var half: Vector3 = size * 0.5
	var side: float = 1.0 if randf() < 0.5 else -1.0
	match randi() % 3:
		0: return Vector3(side * half.x, randf_range(-half.y, half.y), randf_range(-half.z, half.z))
		1: return Vector3(randf_range(-half.x, half.x), side * half.y, randf_range(-half.z, half.z))
	return Vector3(randf_range(-half.x, half.x), randf_range(-half.y, half.y), side * half.z)


static func rand_in_box_border(min_size: Vector3 = -Vector3.ONE, max_size: Vector3 = Vector3.ONE) -> Vector3:
	var size: Vector3 = randv3_range(min_size, max_size)
	var half: Vector3 = size / 2.0
	var side: float = [-1.0, 1.0].pick_random()
	match randi() % 3:
		0:  return Vector3(side * half.x, randf_range(-half.y, half.y), randf_range(-half.z, half.z))
		1:  return Vector3(randf_range(-half.x, half.x), side * half.y, randf_range(-half.z, half.z))
	return Vector3(randf_range(-half.x, half.x), randf_range(-half.y, half.y), side * half.z)


static func rand_in_triangle_3d(o: Vector3, a: Vector3, b: Vector3) -> Vector3:
	var u := randf()
	var v := randf()
	if u + v > 1.0:
		u = 1.0 - u
		v = 1.0 - v
	return Utils.sample_triangle_3d(o, a, b, u, v)


## Равномерное распределение > 99% 
static func random_quaternion() -> Quaternion:
	var u1 := randf() * TAU
	var u2 := randf() * 2.0 - 1.0
	var r := sqrt(1.0 - u2 * u2)
	var q_swing := Quaternion(Vector3.FORWARD, Vector3(r * cos(u1), r * sin(u1), u2))
	var q_twist := Quaternion(Vector3.FORWARD, randf() * TAU)
	return q_swing * q_twist


#region ARRAYS #################################################################


## DEPRECATED: Use RandomNumberGenerator.rand_weighted
#func pick_weighted(weights: PackedFloat32Array) -> int:
	#
	#if not weights:
		#return -1
	#
	#var total_weight: float = sumf(weights)
	#if total_weight <= 0.0:
		#return -1
	#
	#var r: float = randf_range(0, total_weight)
	#var acc := 0.0
	#for i in len(weights):
		#acc += weights[i]
		#if r <= acc:
			#return i
	#
	#return len(weights) - 1


## length случайных без повторений из array
static func random_sample(array: Array, length: int) -> Array:
	var indices: Array = range(length)
	indices.shuffle()
	return indices.map(array.get)


## length случайных из array
static func random_choices(array: Array, length: int) -> Array:
	return range(length).map(array.pick_random.unbind(1))


static func randsf(count: int) -> PackedFloat32Array:
	var result: PackedFloat32Array
	result.resize(count)
	for i in count:
		result[i] = randf()
	return result


static func randsf_range(count: int, from: float, to: float) -> PackedFloat32Array:
	var arr: PackedFloat32Array
	arr.resize(count)
	for i in count:
		arr[i] = randf_range(from, to)
	return arr


static func pick_random_chunk(array: Array, chunk_size: int) -> Array:
	@warning_ignore("integer_division")
	var start: int = randi_range.call(0, (len(array) - 1) / chunk_size)
	return array.slice(start * chunk_size, start * chunk_size + chunk_size)


static func shuffled(array: Array) -> Array:
	var result: Array = array.duplicate()
	result.shuffle()
	return result


static func shuffled_chunks(array: Array, chunk_size: int) -> Array:
	var result: Array = []
	for i: int in shuffled(range(len(array) / 3)):
		result.append_array(array.slice(i * chunk_size, i * chunk_size + chunk_size))
	return result


#endregion ARRAYS ##############################################################
