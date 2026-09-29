@abstract class_name Operator extends Object



# --- CALLABLES ---

static func safe_call(object: Object, method: StringName, ...args: Array) -> Variant: return safe_callv(object, method, args)
static func safe_callv(object: Object, method: StringName, args: Array) -> Variant: return object.callv(method, args) if object and object.has_method(method) else null
#static func call_for_key(object: Object, key: Variant, method: Callable) -> Variant: return method.call(object.get(key))


## (f1, f2, f3) => f1(); f2(); f3()
static func chain(...callables: Array) -> Variant: return chainv(callables)
static func chainv(callables: Array[Callable]) -> Variant:
	for callable in callables.slice(0, len(callables)-1):
		callable.call()
	return callables[-1].call()


## (f1, f2, f3) => f1(f2(f3))
static func compose(callables: Array[Callable], ...args: Array) -> Variant: return composev(callables, args)
static func composev(callables: Array[Callable], args: Array = []) -> Variant:
	var result: Variant = callables[-1].callv(args)
	for i: int in range(len(callables)-2, -1, -1): result = callables[i].call(result)
	return result


## (f1, f2, f3) => f3(f2(f1))
static func pipe(callables: Array[Callable], ...args: Array) -> Variant: return pipev(callables, args)
static func pipev(callables: Array[Callable], args: Array = []) -> Variant:
	var result: Variant = callables[0].callv(args)
	for i: int in range(1, len(callables)): result = callables[i].call(result)
	return result


# --- COLLECTIONS ---

static func inside(what: Variant, where: Variant) -> bool: return what in where
static func not_inside(what: Variant, where: Variant) -> bool: return what not in where
static func has(where: Variant, what: Variant) -> bool: return what in where
static func not_has(where: Variant, what: Variant) -> bool: return what not in where


static func is_inside_object(property: StringName, object: Object) -> bool: return property in object if object else null
static func is_object_has(object: Object, property: StringName) -> bool: return property in object if object else null


static func safe_get(object: Object, property: StringName, default: Variant = null) -> Variant: return object.get(property) if object and property in object else default
#static func safe_getter(owner: Variant, key: Variant) -> Variant: return owner.get(key) if owner else null
#static func safe_setter(owner: Variant, value: Variant, key: Variant) -> void: if owner: owner.set(key, value)

static func is_setted(object: Object, property: StringName, value: Variant) -> bool:
	if object and property in object and is_instance_of(object.get(property), typeof(value)):
		object.set(property, value)
		return true
	return false


# --- LOGIC  ---

static func is_true(value: Variant) -> bool: return value
static func is_false(value: Variant) -> bool: return not value
 

static func is_equal(a: Variant, b: Variant) -> bool: return a == b
static func is_equali(a: int, b: int) -> bool: return a == b
static func is_equalf(a: float, b: float) -> bool: return a == b

static func is_not_equal(a: Variant, b: Variant) -> bool: return a != b

static func is_key_equal(where: Variant, key: Variant, what: Variant) -> bool: return where.get(key) == what


static func is_greater(a: Variant, b: Variant) -> bool: return a > b
static func is_greateri(a: int, b: int) -> bool: return a > b
static func is_greaterf(a: float, b: float) -> bool: return a > b

static func is_not_greater(a: Variant, b: Variant) -> bool: return a <= b


static func is_less(a: Variant, b: Variant) -> bool: return a < b
static func is_lessi(a: int, b: int) -> bool: return a < b
static func is_lessf(a: float, b: float) -> bool: return a < b

static func is_not_less(a: Variant, b: Variant) -> bool: return a >= b


static func all(...array: Array) -> bool: return array.all(is_true)
static func allv(array: Array) -> bool: return array.all(is_true)

static func any(...array: Array) -> bool: return array.any(is_true)
static func anyv(array: Array) -> bool: return array.any(is_true)


# --- MATH ---

static func add(a: Variant, b: Variant) -> Variant: return a + b
static func addi(a: int, b: int) -> int: return a + b
static func addf(a: float, b: float) -> float: return a + b
static func add_2d(a: Vector2, b: Vector2) -> Vector2: return a + b
static func add_3d(a: Vector3, b: Vector3) -> Vector3: return a + b

static func sub(a: Variant, b: Variant) -> Variant: return a - b
static func subi(a: int, b: int) -> int: return a - b
static func subf(a: float, b: float) -> float: return a - b
static func sub_2d(a: Vector2, b: Vector2) -> Vector2: return a - b
static func sub_3d(a: Vector3, b: Vector3) -> Vector3: return a - b

static func mul(a: Variant, b: Variant) -> Variant: return a * b
static func muli(a: int, b: int) -> int: return a * b
static func mulf(a: float, b: float) -> float: return a * b
static func mul_2d(a: Vector2, b: Vector2) -> Vector2: return a * b
static func mul_3d(a: Vector3, b: Vector3) -> Vector3: return a * b

static func div(a: Variant, b: Variant) -> Variant: return a / b
static func divi(a: int, b: int) -> int: return a / b
static func divf(a: float, b: float) -> float: return a / b
static func div_2d(a: Vector2, b: Vector2) -> Vector2: return a / b
static func div_3d(a: Vector3, b: Vector3) -> Vector3: return a / b

static func safe_divi(a: int, b: int, default: int = 0) -> int: return default if b == 0.0 else (a / b)
static func safe_divf(a: float, b: float, default: float = 0.0) -> float: return default if is_zero_approx(b) else (a / b)

static func safe_div_2d(a: Vector2, b: Vector2, default := Vector2.ZERO) -> Vector2: return Vector2(
	default.x if is_zero_approx(b.x) else a.x / b.x,
	default.y if is_zero_approx(b.y) else a.y / b.y)

static func safe_div_3d(a: Vector3, b: Vector3, default := Vector3.ZERO) -> Vector3: return Vector3(
	default.x if is_zero_approx(b.x) else a.x / b.x,
	default.y if is_zero_approx(b.y) else a.y / b.y,
	default.z if is_zero_approx(b.z) else a.z / b.z)
