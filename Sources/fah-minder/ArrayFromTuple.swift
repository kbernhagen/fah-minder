//
//  ArrayFromTuple.swift
//  https://gist.github.com/ctreffs/785db636d68a211b25c989644b13f301
//

/// Generates array form a tuple. Given tuple's elements must have homogenous type.
///
/// - Parameter tuple: a (homogenous) tuple
/// - Returns: array of tuple elements
func makeArray<Tuple, Value>(from tuple: Tuple) -> [Value] {
	let tupleMirror = Mirror(reflecting: tuple)
	assert(tupleMirror.displayStyle == .tuple, "Given argument is not a tuple")
	assert(tupleMirror.superclassMirror == nil,"Given tuple argument must not have a superclass (is: \(tupleMirror.superclassMirror!)")
	assert(!tupleMirror.children.isEmpty, "Given tuple argument has no value elements")
	func convert(child: Mirror.Child) -> Value? {
		let valueMirror = Mirror(reflecting: child.value)
		assert(valueMirror.subjectType == Value.self, "Given tuple argument's child type (\(valueMirror.subjectType)) does not reflect expected return value type (\(Value.self))")
		return child.value as? Value
	}
  return tupleMirror.children.compactMap(convert)
}
