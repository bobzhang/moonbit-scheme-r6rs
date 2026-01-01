///|
/// Create a binding value with an id and value.
///
/// # Example
/// ```mbt check
/// test "Binding::new" {
///   let binding = Binding::new(1, Value::Void)
///   inspect(binding.id(), content="1")
/// }
/// ```
pub fn Binding::new(id : Int, value : Value) -> Binding {
  { id, value }
}

///|
/// Read the binding id.
pub fn Binding::id(self : Binding) -> Int {
  self.id
}

///|
/// Read the binding value.
pub fn Binding::value(self : Binding) -> Value {
  self.value
}
