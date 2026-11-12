@abstract extends Object
class_name Bound


## (f, 1).call(2) => f.bind(1, 2)
static func lbind(callable: Callable, ...args: Array) -> Callable: return lbindv(callable, args)
static func lbindv(callable: Callable, args: Array) -> Callable:   return func(...right_args: Array) -> void: return callable.callv(args + right_args)
static func lrbind(callable: Callable, left: Array = [], right: Array = []) -> Callable: return lbindv(callable, left).bind(right)


## (f(...) -> bool) => { return not f(...) }
static func negate(predicate: Callable) -> Callable: return func(...args: Array) -> bool: return not predicate.callv(args)


## Erase button from buttons if exiting child is Button:
## >> child_exiting_tree.connect(call_if(buttons.erase, is_instance_of.bind(Button)))
static func call_if(callable: Callable, predicate: Callable) -> Callable:  return func(...args: Array) -> Variant: return callable.callv(args) if predicate.callv(args) else null

static func bound_call(method: StringName, ...args: Array) -> Callable:    return bound_callv(method, args)
static func bound_callv(method: StringName, args: Array = []) -> Callable: return func(object: Object) -> Variant: return object.callv(method, args)
static func safe_call(method: StringName, ...args: Array) -> Callable:     return safe_callv(method, args)
static func safe_callv(method: StringName, args: Array = []) -> Callable:  return lbind(Operator.safe_callv, method, args)# func(object: Object) -> Variant: return Operator.safe_callerv(object, method, args)


static func getter(owner: Variant, key: Variant) -> Callable: return Operator.static_get.bind(owner, key)
static func setter(owner: Variant, key: Variant) -> Callable: return func(value: Variant) -> void: owner.set(key, value)

static func bound_get(key: Variant) -> Callable:                  return Operator.static_get.bind(key)
static func bound_set(key: Variant, value: Variant) -> Callable:  return Operator.static_set.bind(key, value)

static func at(key: Variant, callable: Callable) -> Callable:     return Operator.at.bind(key, callable)


static func is_equal(other: Variant) -> Callable:                 return Operator.is_equal.bind(other)

## [1,2].all(is_greater(0)) => true
static func is_greater(other: Variant) -> Callable:               return Operator.is_greater.bind(other)
static func is_not_greater(other: Variant) -> Callable:           return Operator.is_not_greater.bind(other)
static func is_less(other: Variant) -> Callable:                  return Operator.is_less.bind(other)
static func is_not_less(other: Variant) -> Callable:              return Operator.is_not_less.bind(other)

## [1,2].all(inside([1,2,3])) => true
static func inside(container: Variant) -> Callable:               return Operator.inside.bind(container)
static func not_inside(container: Variant) -> Callable:           return Operator.not_inside.bind(container)

static func has(what: Variant) -> Callable:                       return Operator.has.bind(what)
static func has_property(property: StringName) -> Callable:       return Operator.has_property.bind(property)
static func not_has(what: Variant) -> Callable:                   return Operator.not_has.bind(what)


## (f1, f2, f3) => { f1(); f2(); f3() }
static func chain(...callables: Array) -> Callable:               return chainv(Array(callables, TYPE_CALLABLE, "", null))
static func chainv(callables: Array[Callable]) -> Callable:       return Callable() if callables.is_empty() else Operator.chainv.bind(callables)


## (f1, f2, f3) => { f1(f2(f3)) }
static func compose(...callables: Array) -> Callable: return composev(Array(callables, TYPE_CALLABLE, "", null))
static func composev(callables: Array[Callable]) -> Callable:
	return Callable() if callables.is_empty() else func(...args: Array) -> Variant:
		var result: Variant = callables[-1].callv(args)
		for i: int in range(len(callables)-2, -1, -1): result = callables[i].call(result)
		return result


## (f1, f2, f3) => { f3(f2(f1)) }
static func pipe(...callables: Array) -> Callable: return pipev(Array(callables, TYPE_CALLABLE, "", null))
static func pipev(callables: Array[Callable]) -> Callable:
	return Callable() if callables.is_empty() else func(...args: Array) -> Variant:
		var result: Variant = callables[0].callv(args)
		for i: int in range(1, len(callables)): result = callables[i].call(result)
		return result


## nodes.filter(Bound.all(is_instance_of.bind(Node), Bound.has_property("my_property")))
static func all(...predicates: Array) -> Callable:         return Operator.allv_custom.bind(Array(predicates, TYPE_CALLABLE, "", null))
static func allv(predicates: Array[Callable]) -> Callable: return Operator.allv_custom.bind(predicates)

static func any(...predicates: Array) -> Callable:         return Operator.anyv_custom.bind(Array(predicates, TYPE_CALLABLE, "", null))
static func anyv(predicates: Array[Callable]) -> Callable: return Operator.anyv_custom.bind(predicates)
