///|
/// Create a fresh environment with a single empty frame.
pub fn env_new() -> Env {
  let env : Env = []
  env.push({})
  env
}

///|
/// Extend an environment by pushing a new empty frame.
pub fn env_extend(env : Env) -> Env {
  let new_env = env.copy()
  new_env.push({})
  new_env
}

///|
/// Deep-clone environment frames and bindings.
pub fn env_clone(env : Env) -> Env {
  let new_env : Env = []
  for frame in env {
    let new_frame : Map[String, Binding] = {}
    for key in frame.keys() {
      match frame.get(key) {
        Some(binding) =>
          new_frame[key] = Binding::{ id: binding.id, value: binding.value }
        None => ()
      }
    }
    new_env.push(new_frame)
  }
  new_env
}

///|
fn env_get(env : Env, name : String) -> Binding? {
  if env.is_empty() {
    return None
  }
  let result : Binding? = for i = env.length() - 1; i >= 0; i = i - 1 {
    let frame = env[i]
    match frame.get(name) {
      Some(binding) => break Some(binding)
      None => ()
    }
  } else {
    None
  }
  result
}

///|
/// Look up a macro transformer by name, if present.
pub fn env_get_macro(env : Env, name : String) -> MacroTransformer? {
  match env_get(env, name) {
    Some(binding) =>
      match binding.value {
        Value::Macro(transformer) => Some(transformer)
        _ => None
      }
    _ => None
  }
}

///|
/// Define a new binding in the current frame.
pub fn env_define(env : Env, name : String, value : Value) -> Unit {
  let idx = env.length() - 1
  env[idx][name] = Binding::{ id: next_binding_id(), value }
}

///|
/// Define an existing binding in the current frame.
pub fn env_define_binding(env : Env, name : String, binding : Binding) -> Unit {
  let idx = env.length() - 1
  env[idx][name] = binding
}

///|
/// Look up a binding by name or raise if it is unbound.
pub fn env_lookup_binding(env : Env, name : String) -> Binding raise EvalError {
  match env_get(env, name) {
    Some(binding) => binding
    None => raise @core.EvalError("unbound variable: \{name}")
  }
}

///|
/// Look up a binding by name, returning None if missing.
pub fn env_lookup_binding_optional(env : Env, name : String) -> Binding? {
  env_get(env, name)
}

///|
/// Look up a binding id by name, returning None if missing.
pub fn env_binding_id_optional(env : Env, name : String) -> Int? {
  match env_get(env, name) {
    Some(binding) => Some(binding.id)
    None => None
  }
}

///|
/// Look up a binding value or raise if it is unbound.
pub fn env_lookup(env : Env, name : String) -> Value raise EvalError {
  env_lookup_binding(env, name).value
}

///|
/// Look up a binding value, returning None if missing.
pub fn env_lookup_optional(env : Env, name : String) -> Value? {
  match env_get(env, name) {
    Some(binding) => Some(binding.value)
    None => None
  }
}

///|
/// Update an existing binding or raise if it is unbound.
pub fn env_set(env : Env, name : String, value : Value) -> Unit raise EvalError {
  if env.is_empty() {
    raise @core.EvalError("unbound variable: \{name}")
  }
  let updated = for i = env.length() - 1; i >= 0; i = i - 1 {
    let frame = env[i]
    if frame.contains(name) {
      let binding = frame[name]
      frame[name] = Binding::{ id: binding.id, value }
      break true
    }
  } else {
    false
  }
  if !updated {
    raise @core.EvalError("unbound variable: \{name}")
  }
}
