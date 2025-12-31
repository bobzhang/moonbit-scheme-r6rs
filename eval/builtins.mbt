///|
/// Apply a primitive to evaluated arguments.
fn apply_primitive(
  prim : Primitive,
  args : Array[Value],
) -> Value raise EvalError {
  match apply_numeric_primitive(prim, args) {
    Some(value) => value
    None =>
      match apply_pair_list_primitive(prim, args) {
        Some(value) => value
        None =>
          match apply_char_string_primitive(prim, args) {
            Some(value) => value
            None =>
              match apply_vector_primitive(prim, args) {
                Some(value) => value
                None =>
                  match apply_bytevector_primitive(prim, args) {
                    Some(value) => value
                    None => apply_primitive_core(prim, args)
                  }
              }
          }
      }
  }
}

///|
/// Apply primitives not handled by specialized dispatchers.
fn apply_primitive_core(
  prim : Primitive,
  args : Array[Value],
) -> Value raise EvalError {
  match prim {
    Primitive::Eq =>
      match args.length() {
        2 => bool_value(value_eqv(args[0], args[1]))
        n => raise arity_mismatch(2, n)
      }
    Primitive::Eqv =>
      match args.length() {
        2 => bool_value(value_eqv(args[0], args[1]))
        n => raise arity_mismatch(2, n)
      }
    Primitive::Equal =>
      match args.length() {
        2 => bool_value(value_equal(args[0], args[1]))
        n => raise arity_mismatch(2, n)
      }
    Primitive::SymbolP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Datum(Datum::Symbol(_)) => bool_value(true)
            _ => bool_value(false)
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::SymbolEq => bool_value(compare_chain_symbol(args))
    Primitive::IdentifierP =>
      match args.length() {
        1 => bool_value(is_identifier_value(args[0]))
        n => raise arity_mismatch(1, n)
      }
    Primitive::SyntaxP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::SyntaxObject(_) => bool_value(true)
            _ => bool_value(false)
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::FreeIdentifierEq =>
      match args.length() {
        2 => {
          let (a, a_scopes, a_binding) = identifier_info(args[0])
          let (b, b_scopes, b_binding) = identifier_info(args[1])
          if a != b {
            bool_value(false)
          } else if a_binding is Some(_) && b_binding is Some(_) {
            bool_value(a_binding == b_binding)
          } else {
            bool_value(scopes_equal(a_scopes, b_scopes))
          }
        }
        n => raise arity_mismatch(2, n)
      }
    Primitive::BoundIdentifierEq =>
      match args.length() {
        2 => {
          let (a, a_scopes, a_binding) = identifier_info(args[0])
          let (b, b_scopes, b_binding) = identifier_info(args[1])
          if a != b {
            bool_value(false)
          } else if a_binding is Some(_) && b_binding is Some(_) {
            bool_value(a_binding == b_binding)
          } else {
            bool_value(scopes_equal(a_scopes, b_scopes))
          }
        }
        n => raise arity_mismatch(2, n)
      }
    Primitive::SymbolToString =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Datum(Datum::Symbol(name)) =>
              Value::Datum(Datum::String(Ref::new(name)))
            _ => raise @core.EvalError("type error: symbol expected")
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::StringToSymbol =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Datum(Datum::String(name)) =>
              Value::Datum(Datum::Symbol(name.val))
            _ => raise @core.EvalError("type error: string expected")
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::StringHash =>
      match args.length() {
        1 => {
          let s = value_as_string(args[0])
          Value::Datum(Datum::Int(hash_string_value(s)))
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::StringCiHash =>
      match args.length() {
        1 => {
          let s = value_as_string(args[0])
          let folded = unicode_string(s).foldcase().into_string()
          Value::Datum(Datum::Int(hash_string_value(folded)))
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::SymbolHash =>
      match args.length() {
        1 => {
          let name = value_as_symbol(args[0])
          Value::Datum(Datum::Int(hash_string_value(name)))
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::EqualHash =>
      match args.length() {
        1 => {
          let repr = value_to_string(args[0])
          Value::Datum(Datum::Int(hash_string_value(repr)))
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::SyntaxToDatum =>
      match args.length() {
        1 =>
          match args[0] {
            Value::SyntaxObject(obj) =>
              Value::Datum(strip_syntax_datum(obj.datum))
            Value::Datum(d) => Value::Datum(strip_syntax_datum(d))
            _ => raise @core.EvalError("type error: syntax expected")
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::DatumToSyntax =>
      match args.length() {
        2 | 3 => {
          let scopes = match args[0] {
            Value::SyntaxObject(obj) => obj.scopes
            _ => []
          }
          let context_binding = match args[0] {
            Value::SyntaxObject(obj) => obj.binding_id
            _ => None
          }
          let base = match args[1] {
            Value::SyntaxObject(obj) => obj.datum
            Value::Datum(d) => d
            _ => raise @core.EvalError("type error: datum expected")
          }
          let template_name = match args[0] {
            Value::SyntaxObject(obj) =>
              match datum_unlabel(obj.datum) {
                Datum::Symbol(name) => Some(name)
                _ => None
              }
            _ => None
          }
          let base = match (template_name, datum_unlabel(base)) {
            (Some(template), Datum::Symbol(base_name)) =>
              match strip_gensym_suffix(template) {
                Some(immediate) =>
                  if strip_gensym_suffix(immediate) is Some(_) {
                    let original = strip_all_gensym_suffixes(template)
                    if original == base_name {
                      Datum::Symbol(immediate)
                    } else {
                      base
                    }
                  } else {
                    base
                  }
                None => base
              }
            _ => base
          }
          let datum = syntax_wrap_root(base, scopes)
          let binding_id = match datum_unlabel(base) {
            Datum::Symbol(_) => context_binding
            _ => None
          }
          Value::SyntaxObject(SyntaxObject::{ datum, scopes, binding_id })
        }
        n => raise @core.EvalError("arity mismatch: expected 2 or 3 got \{n}")
      }
    Primitive::BooleanP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Datum(Datum::Bool(_)) => bool_value(true)
            _ => bool_value(false)
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::BooleanEq => bool_value(compare_chain_bool(args))
    Primitive::NumberP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Datum(Datum::Int(_))
            | Value::Datum(Datum::BigInt(_))
            | Value::Datum(Datum::Rat(_, _))
            | Value::Datum(Datum::BigRat(_, _))
            | Value::Datum(Datum::Float(_))
            | Value::Datum(Datum::Complex(_, _)) => bool_value(true)
            _ => bool_value(false)
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::IntegerP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Datum(datum) => bool_value(datum_is_integer_valued(datum))
            _ => bool_value(false)
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::ExactIntegerP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Datum(datum) => bool_value(datum_is_exact_integer(datum))
            _ => bool_value(false)
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::RationalP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Datum(datum) => bool_value(datum_is_rational_valued(datum))
            _ => bool_value(false)
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::RealP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Datum(Datum::Int(_))
            | Value::Datum(Datum::BigInt(_))
            | Value::Datum(Datum::Rat(_, _))
            | Value::Datum(Datum::BigRat(_, _))
            | Value::Datum(Datum::Float(_)) => bool_value(true)
            Value::Datum(Datum::Complex(_, imag)) =>
              bool_value(datum_is_zero(imag.val))
            _ => bool_value(false)
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::ComplexP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Datum(Datum::Int(_))
            | Value::Datum(Datum::BigInt(_))
            | Value::Datum(Datum::Rat(_, _))
            | Value::Datum(Datum::BigRat(_, _))
            | Value::Datum(Datum::Float(_))
            | Value::Datum(Datum::Complex(_, _)) => bool_value(true)
            _ => bool_value(false)
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::ExactP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Datum(Datum::Int(_))
            | Value::Datum(Datum::BigInt(_))
            | Value::Datum(Datum::Rat(_, _))
            | Value::Datum(Datum::BigRat(_, _)) => bool_value(true)
            Value::Datum(Datum::Complex(real, imag)) =>
              match (real.val, imag.val) {
                (Datum::Int(_), Datum::Int(_)) => bool_value(true)
                (Datum::Int(_), Datum::BigInt(_)) => bool_value(true)
                (Datum::Int(_), Datum::Rat(_, _)) => bool_value(true)
                (Datum::Int(_), Datum::BigRat(_, _)) => bool_value(true)
                (Datum::BigInt(_), Datum::Int(_)) => bool_value(true)
                (Datum::BigInt(_), Datum::BigInt(_)) => bool_value(true)
                (Datum::BigInt(_), Datum::Rat(_, _)) => bool_value(true)
                (Datum::BigInt(_), Datum::BigRat(_, _)) => bool_value(true)
                (Datum::Rat(_, _), Datum::Int(_)) => bool_value(true)
                (Datum::Rat(_, _), Datum::BigInt(_)) => bool_value(true)
                (Datum::Rat(_, _), Datum::Rat(_, _)) => bool_value(true)
                (Datum::Rat(_, _), Datum::BigRat(_, _)) => bool_value(true)
                (Datum::BigRat(_, _), Datum::Int(_)) => bool_value(true)
                (Datum::BigRat(_, _), Datum::BigInt(_)) => bool_value(true)
                (Datum::BigRat(_, _), Datum::Rat(_, _)) => bool_value(true)
                (Datum::BigRat(_, _), Datum::BigRat(_, _)) => bool_value(true)
                _ => bool_value(false)
              }
            _ => bool_value(false)
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::InexactP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Datum(Datum::Float(_)) => bool_value(true)
            Value::Datum(Datum::Complex(real, imag)) =>
              match (real.val, imag.val) {
                (Datum::Float(_), _) => bool_value(true)
                (_, Datum::Float(_)) => bool_value(true)
                _ => bool_value(false)
              }
            _ => bool_value(false)
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::ZeroP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Datum(Datum::Int(n)) => bool_value(n == 0)
            Value::Datum(Datum::Rat(n, _)) => bool_value(n == 0)
            Value::Datum(Datum::BigInt(n)) => bool_value(n.is_zero())
            Value::Datum(Datum::BigRat(n, _)) => bool_value(n.is_zero())
            Value::Datum(Datum::Float(n)) => bool_value(n == 0.0)
            Value::Datum(Datum::Complex(real, imag)) =>
              bool_value(datum_is_zero(real.val) && datum_is_zero(imag.val))
            _ => raise @core.EvalError("type error: number expected")
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::PositiveP =>
      match args.length() {
        1 => {
          let value = datum_to_real(value_as_number(args[0]))
          match value {
            Datum::Int(n) => bool_value(n > 0)
            Datum::Rat(n, _) => bool_value(n > 0)
            Datum::BigInt(n) => bool_value(n.compare_int(0) > 0)
            Datum::BigRat(n, _) => bool_value(n.compare_int(0) > 0)
            Datum::Float(n) => bool_value(n > 0.0)
            _ => raise @core.EvalError("type error: number expected")
          }
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::NegativeP =>
      match args.length() {
        1 => {
          let value = datum_to_real(value_as_number(args[0]))
          match value {
            Datum::Int(n) => bool_value(n < 0)
            Datum::Rat(n, _) => bool_value(n < 0)
            Datum::BigInt(n) => bool_value(n.compare_int(0) < 0)
            Datum::BigRat(n, _) => bool_value(n.compare_int(0) < 0)
            Datum::Float(n) => bool_value(n < 0.0)
            _ => raise @core.EvalError("type error: number expected")
          }
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::OddP =>
      match args.length() {
        1 => {
          let value = match args[0] {
            Value::Datum(Datum::Int(n)) => Datum::Int(n)
            Value::Datum(Datum::BigInt(n)) => Datum::BigInt(n)
            Value::Datum(Datum::Complex(real, imag)) =>
              if datum_is_zero(imag.val) {
                match real.val {
                  Datum::Int(n) => Datum::Int(n)
                  Datum::BigInt(n) => Datum::BigInt(n)
                  _ =>
                    raise @core.EvalError("type error: exact integer expected")
                }
              } else {
                raise @core.EvalError("type error: exact integer expected")
              }
            _ => raise @core.EvalError("type error: exact integer expected")
          }
          match value {
            Datum::Int(n) => bool_value(n % 2 != 0)
            Datum::BigInt(n) =>
              bool_value(!bigint_is_zero(n % bigint_from_int(2)))
            _ => raise @core.EvalError("type error: exact integer expected")
          }
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::EvenP =>
      match args.length() {
        1 => {
          let value = match args[0] {
            Value::Datum(Datum::Int(n)) => Datum::Int(n)
            Value::Datum(Datum::BigInt(n)) => Datum::BigInt(n)
            Value::Datum(Datum::Complex(real, imag)) =>
              if datum_is_zero(imag.val) {
                match real.val {
                  Datum::Int(n) => Datum::Int(n)
                  Datum::BigInt(n) => Datum::BigInt(n)
                  _ =>
                    raise @core.EvalError("type error: exact integer expected")
                }
              } else {
                raise @core.EvalError("type error: exact integer expected")
              }
            _ => raise @core.EvalError("type error: exact integer expected")
          }
          match value {
            Datum::Int(n) => bool_value(n % 2 == 0)
            Datum::BigInt(n) =>
              bool_value(bigint_is_zero(n % bigint_from_int(2)))
            _ => raise @core.EvalError("type error: exact integer expected")
          }
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::FiniteP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Datum(Datum::Float(f)) => bool_value(float_is_finite(f))
            Value::Datum(Datum::Int(_))
            | Value::Datum(Datum::BigInt(_))
            | Value::Datum(Datum::Rat(_, _))
            | Value::Datum(Datum::BigRat(_, _)) => bool_value(true)
            Value::Datum(Datum::Complex(real, imag)) =>
              if datum_is_zero(imag.val) {
                match real.val {
                  Datum::Float(f) => bool_value(float_is_finite(f))
                  Datum::Int(_)
                  | Datum::BigInt(_)
                  | Datum::Rat(_, _)
                  | Datum::BigRat(_, _) => bool_value(true)
                  _ => raise @core.EvalError("type error: number expected")
                }
              } else {
                raise @core.EvalError("type error: real expected")
              }
            _ => raise @core.EvalError("type error: number expected")
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::InfiniteP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Datum(Datum::Float(f)) => bool_value(float_is_infinite(f))
            Value::Datum(Datum::Int(_))
            | Value::Datum(Datum::BigInt(_))
            | Value::Datum(Datum::Rat(_, _))
            | Value::Datum(Datum::BigRat(_, _)) => bool_value(false)
            Value::Datum(Datum::Complex(real, imag)) =>
              if datum_is_zero(imag.val) {
                match real.val {
                  Datum::Float(f) => bool_value(float_is_infinite(f))
                  Datum::Int(_)
                  | Datum::BigInt(_)
                  | Datum::Rat(_, _)
                  | Datum::BigRat(_, _) => bool_value(false)
                  _ => raise @core.EvalError("type error: number expected")
                }
              } else {
                raise @core.EvalError("type error: real expected")
              }
            _ => raise @core.EvalError("type error: number expected")
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::NanP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Datum(Datum::Float(f)) => bool_value(float_is_nan(f))
            Value::Datum(Datum::Int(_))
            | Value::Datum(Datum::BigInt(_))
            | Value::Datum(Datum::Rat(_, _))
            | Value::Datum(Datum::BigRat(_, _)) => bool_value(false)
            Value::Datum(Datum::Complex(real, imag)) =>
              if datum_is_zero(imag.val) {
                match real.val {
                  Datum::Float(f) => bool_value(float_is_nan(f))
                  Datum::Int(_)
                  | Datum::BigInt(_)
                  | Datum::Rat(_, _)
                  | Datum::BigRat(_, _) => bool_value(false)
                  _ => raise @core.EvalError("type error: number expected")
                }
              } else {
                raise @core.EvalError("type error: real expected")
              }
            _ => raise @core.EvalError("type error: number expected")
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::ProcedureP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Primitive(_)
            | Value::Closure(_)
            | Value::CaseClosure(_)
            | Value::GuardHandler(_)
            | Value::Parameter(_)
            | Value::Continuation(_)
            | Value::RecordProc(_)
            | Value::ConditionProc(_)
            | Value::EnumSetProc(_) => bool_value(true)
            _ => bool_value(false)
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::RecordP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Record(record) => bool_value(!record.record_type.is_opaque)
            _ => bool_value(false)
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::RecordRtd =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Record(record) =>
              if record.record_type.is_opaque {
                raise @core.EvalError("record type is opaque")
              } else {
                match
                  lookup_record_type_descriptor_by_id(record.record_type.id) {
                  Some(desc) => Value::RecordTypeDescriptor(desc)
                  None =>
                    raise @core.EvalError("invalid record type descriptor")
                }
              }
            _ => raise @core.EvalError("type error: record expected")
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::RecordTypeDescriptorP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::RecordTypeDescriptor(_) => bool_value(true)
            _ => bool_value(false)
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::RecordConstructorDescriptorP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::RecordConstructorDescriptor(_) => bool_value(true)
            _ => bool_value(false)
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::RecordTypeName =>
      match args.length() {
        1 => {
          let desc = value_as_record_type_descriptor(args[0])
          Value::Datum(Datum::Symbol(desc.record_type.name))
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::RecordTypeParent =>
      match args.length() {
        1 => {
          let desc = value_as_record_type_descriptor(args[0])
          match desc.record_type.parent {
            Some(parent) =>
              match lookup_record_type_descriptor(parent.name) {
                Some(parent_desc) => Value::RecordTypeDescriptor(parent_desc)
                None => Value::Datum(Datum::Bool(false))
              }
            None => Value::Datum(Datum::Bool(false))
          }
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::RecordTypeUid =>
      match args.length() {
        1 => {
          let desc = value_as_record_type_descriptor(args[0])
          match desc.record_type.uid {
            Some(uid) => Value::Datum(Datum::Symbol(uid))
            None => Value::Datum(Datum::Bool(false))
          }
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::RecordTypeGenerativeP =>
      match args.length() {
        1 => {
          let desc = value_as_record_type_descriptor(args[0])
          bool_value(desc.record_type.uid is None)
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::RecordTypeSealedP =>
      match args.length() {
        1 => {
          let desc = value_as_record_type_descriptor(args[0])
          bool_value(desc.record_type.is_sealed)
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::RecordTypeOpaqueP =>
      match args.length() {
        1 => {
          let desc = value_as_record_type_descriptor(args[0])
          bool_value(desc.record_type.is_opaque)
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::RecordTypeFieldNames =>
      match args.length() {
        1 => {
          let desc = value_as_record_type_descriptor(args[0])
          let items : Array[Datum] = []
          for field in desc.record_type.fields {
            // invariant : desc.record_type.fields.length() >= 0
            // TODO(decreases) : loop index not exposed; possible bug
            // assert : desc.record_type.fields.length() >= 0
            items.push(Datum::Symbol(field.name))
          }
          Value::Datum(list_from_array(items))
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::RecordConstructorDescriptor =>
      match args.length() {
        1 => {
          let desc = value_as_record_type_descriptor(args[0])
          Value::RecordConstructorDescriptor(desc.constructor_desc)
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::RecordConstructor =>
      raise @core.EvalError("record-constructor requires evaluation context")
    Primitive::RecordTypeFieldMutableP =>
      match args.length() {
        2 => {
          let desc = value_as_record_type_descriptor(args[0])
          let idx = value_as_int_index(args[1])
          check_index(idx, desc.record_type.fields.length())
          let field = desc.record_type.fields[idx]
          bool_value(field.mutable)
        }
        n => raise arity_mismatch(2, n)
      }
    Primitive::RecordPredicate =>
      match args.length() {
        1 => {
          let desc = value_as_record_type_descriptor(args[0])
          Value::RecordProc(
            make_record_proc(RecordProcKind::Predicate(desc.record_type)),
          )
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::RecordAccessor =>
      match args.length() {
        2 => {
          let desc = value_as_record_type_descriptor(args[0])
          let idx = value_as_int_index(args[1])
          check_index(idx, desc.record_type.fields.length())
          Value::RecordProc(
            make_record_proc(RecordProcKind::Accessor(desc.record_type, idx)),
          )
        }
        n => raise arity_mismatch(2, n)
      }
    Primitive::RecordMutator =>
      match args.length() {
        2 => {
          let desc = value_as_record_type_descriptor(args[0])
          let idx = value_as_int_index(args[1])
          check_index(idx, desc.record_type.fields.length())
          let field = desc.record_type.fields[idx]
          if !field.mutable {
            raise @core.EvalError("record field is immutable: \{field.name}")
          }
          Value::RecordProc(
            make_record_proc(RecordProcKind::Mutator(desc.record_type, idx)),
          )
        }
        n => raise arity_mismatch(2, n)
      }
    Primitive::MakeRecordTypeDescriptor =>
      match args.length() {
        6 => {
          let name = value_as_symbol(args[0])
          let parent_desc = match args[1] {
            Value::Datum(Datum::Bool(false)) => None
            Value::RecordTypeDescriptor(desc) => Some(desc)
            _ =>
              raise @core.EvalError(
                "type error: record type descriptor expected",
              )
          }
          let parent_type = match parent_desc {
            Some(desc) => Some(desc.record_type)
            None => None
          }
          match parent_type {
            Some(parent) =>
              if parent.is_sealed {
                raise @core.EvalError("record type is sealed")
              }
            None => ()
          }
          let uid = match args[2] {
            Value::Datum(Datum::Bool(false)) => None
            Value::Datum(Datum::Symbol(uid_name)) => Some(uid_name)
            _ => raise @core.EvalError("type error: symbol expected")
          }
          let is_sealed = value_as_bool(args[3])
          let is_opaque = value_as_bool(args[4])
          let new_fields = parse_field_specs(value_as_vector(args[5]))
          let fields : Array[RecordField] = []
          match parent_type {
            Some(parent) =>
              for field in parent.fields {
                // invariant : parent.fields.length() >= 0
                // TODO(decreases) : loop index not exposed; possible bug
                // assert : parent.fields.length() >= 0
                fields.push(field)
              }
            None => ()
          }
          for field in new_fields {
            // invariant : new_fields.length() >= 0
            // TODO(decreases) : loop index not exposed; possible bug
            // assert : new_fields.length() >= 0
            fields.push(field)
          }
          let effective_opaque = match parent_type {
            Some(parent) => parent.is_opaque || is_opaque
            None => is_opaque
          }
          match uid {
            Some(uid_name) =>
              match lookup_record_type_descriptor_by_uid(uid_name) {
                Some(existing_desc) => {
                  if !record_type_matches(
                      existing_desc.record_type,
                      parent_type,
                      is_sealed,
                      is_opaque,
                      fields,
                    ) {
                    raise @core.EvalError("invalid record type descriptor")
                  }
                  register_record_type_alias(name, existing_desc)
                  Value::RecordTypeDescriptor(existing_desc)
                }
                None => {
                  let record_type = make_record_type(
                    name, parent_type, is_sealed, effective_opaque, uid, fields,
                  )
                  let ctor_desc = default_constructor_descriptor(record_type)
                  let rtd = make_record_type_descriptor(record_type, ctor_desc)
                  let _ = register_record_type(name, rtd)
                  Value::RecordTypeDescriptor(rtd)
                }
              }
            None => {
              let record_type = make_record_type(
                name, parent_type, is_sealed, effective_opaque, uid, fields,
              )
              let ctor_desc = default_constructor_descriptor(record_type)
              let rtd = make_record_type_descriptor(record_type, ctor_desc)
              let _ = register_record_type(name, rtd)
              Value::RecordTypeDescriptor(rtd)
            }
          }
        }
        n => raise arity_mismatch(6, n)
      }
    Primitive::MakeRecordConstructorDescriptor =>
      match args.length() {
        3 => {
          let rtd = value_as_record_type_descriptor(args[0])
          let record_type = rtd.record_type
          let parent_desc = match args[1] {
            Value::Datum(Datum::Bool(false)) =>
              match record_type.parent {
                Some(parent) => Some(default_constructor_descriptor(parent))
                None => None
              }
            _ => Some(value_as_record_constructor_descriptor(args[1]))
          }
          match record_type.parent {
            Some(parent) =>
              match parent_desc {
                Some(desc) =>
                  if desc.record_type.id != parent.id {
                    raise @core.EvalError(
                      "invalid record constructor descriptor",
                    )
                  }
                None =>
                  raise @core.EvalError("invalid record constructor descriptor")
              }
            None =>
              match parent_desc {
                Some(_) =>
                  raise @core.EvalError("invalid record constructor descriptor")
                None => ()
              }
          }
          let protocol = match args[2] {
            Value::Datum(Datum::Bool(false)) => None
            value => {
              if !is_procedure_value(value) {
                raise @core.EvalError("type error: procedure expected")
              }
              Some(value)
            }
          }
          match (protocol, parent_desc) {
            (None, Some(desc)) =>
              match desc.protocol {
                Some(_) =>
                  raise @core.EvalError("invalid record constructor descriptor")
                None => ()
              }
            _ => ()
          }
          Value::RecordConstructorDescriptor(
            make_record_constructor_descriptor(
              record_type, parent_desc, protocol,
            ),
          )
        }
        n => raise arity_mismatch(3, n)
      }
    Primitive::Condition => {
      if args.length() == 0 {
        raise arity_mismatch(1, 0)
      }
      let base = condition_base_type()
      let components : Array[Record] = []
      for arg in args {
        // invariant : args.length() >= 0
        // TODO(decreases) : loop index not exposed; possible bug
        // assert : args.length() >= 0
        let parts = condition_components(arg, base)
        for record in parts {
          // invariant : parts.length() >= 0
          // TODO(decreases) : loop index not exposed; possible bug
          // assert : parts.length() >= 0
          components.push(record)
        }
      }
      if components.length() == 1 {
        Value::Record(components[0])
      } else {
        Value::Datum(Datum::Condition(make_condition(components)))
      }
    }
    Primitive::ConditionP =>
      match args.length() {
        1 => {
          let base = condition_base_type()
          let ok = condition_components_opt(args[0], base) is Some(_)
          bool_value(ok)
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::SimpleConditions =>
      match args.length() {
        1 => {
          let base = condition_base_type()
          let components = condition_components(args[0], base)
          let items : Array[Datum] = []
          for record in components {
            // invariant : components.length() >= 0
            // TODO(decreases) : loop index not exposed; possible bug
            // assert : components.length() >= 0
            items.push(Datum::Record(record))
          }
          Value::Datum(list_from_array(items))
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::ConditionPredicate =>
      match args.length() {
        1 => {
          let desc = value_as_condition_type_descriptor(args[0])
          Value::ConditionProc(
            make_condition_proc(ConditionProcKind::Predicate(desc.record_type)),
          )
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::ConditionAccessor =>
      match args.length() {
        2 => {
          let desc = value_as_condition_type_descriptor(args[0])
          let (accessor_type, idx) = record_accessor_info(args[1])
          if accessor_type.id != desc.record_type.id {
            raise @core.EvalError("type error: record accessor expected")
          }
          Value::ConditionProc(
            make_condition_proc(
              ConditionProcKind::Accessor(desc.record_type, idx),
            ),
          )
        }
        n => raise arity_mismatch(2, n)
      }
    Primitive::MakeEqHashtable =>
      match args.length() {
        0 => Value::Hashtable(make_hashtable(HashtableEquiv::Eq, None, true))
        1 => {
          validate_hashtable_size_arg(args[0])
          Value::Hashtable(make_hashtable(HashtableEquiv::Eq, None, true))
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::MakeEqvHashtable =>
      match args.length() {
        0 => Value::Hashtable(make_hashtable(HashtableEquiv::Eqv, None, true))
        1 => {
          validate_hashtable_size_arg(args[0])
          Value::Hashtable(make_hashtable(HashtableEquiv::Eqv, None, true))
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::MakeHashtable =>
      match args.length() {
        2 | 3 => {
          let hash = args[0]
          if !is_procedure_value(hash) {
            raise @core.EvalError("type error: procedure expected")
          }
          let equiv = hashtable_equiv_from_value(args[1])
          if args.length() == 3 {
            validate_hashtable_size_arg(args[2])
          }
          Value::Hashtable(make_hashtable(equiv, Some(hash), true))
        }
        n => raise arity_mismatch(2, n)
      }
    Primitive::HashtableP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Hashtable(_) => bool_value(true)
            _ => bool_value(false)
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::HashtableSize =>
      match args.length() {
        1 => {
          let table = value_as_hashtable(args[0])
          Value::Datum(Datum::Int(table.entries.val.length()))
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::HashtableRef =>
      raise @core.EvalError(
        "internal error: hashtable-ref should be handled in apply_proc",
      )
    Primitive::HashtableSet =>
      raise @core.EvalError(
        "internal error: hashtable-set! should be handled in apply_proc",
      )
    Primitive::HashtableDelete =>
      raise @core.EvalError(
        "internal error: hashtable-delete! should be handled in apply_proc",
      )
    Primitive::HashtableContainsP =>
      raise @core.EvalError(
        "internal error: hashtable-contains? should be handled in apply_proc",
      )
    Primitive::HashtableUpdate =>
      raise @core.EvalError(
        "internal error: hashtable-update! should be handled in apply_proc",
      )
    Primitive::HashtableCopy =>
      match args.length() {
        1 | 2 => {
          let table = value_as_hashtable(args[0])
          let mutable = if args.length() == 2 {
            value_as_bool(args[1])
          } else {
            table.mutable
          }
          let entries : Array[HashtableEntry] = []
          for entry in table.entries.val {
            // invariant : table.entries.val.length() >= 0
            // TODO(decreases) : loop index not exposed; possible bug
            // assert : table.entries.val.length() >= 0
            entries.push(HashtableEntry::{
              key: entry.key,
              value: Ref::new(entry.value.val),
            })
          }
          Value::Hashtable(Hashtable::{
            id: next_hashtable_id(),
            mutable,
            equiv: table.equiv,
            hash: table.hash,
            entries: Ref::new(entries),
          })
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::HashtableClear =>
      match args.length() {
        1 | 2 => {
          let table = value_as_hashtable(args[0])
          if !table.mutable {
            raise @core.EvalError("hashtable is immutable")
          }
          if args.length() == 2 {
            validate_hashtable_size_arg(args[1])
          }
          table.entries.val = []
          Value::Void
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::HashtableKeys =>
      match args.length() {
        1 => {
          let table = value_as_hashtable(args[0])
          let items : Array[Datum] = []
          for entry in table.entries.val {
            // invariant : table.entries.val.length() >= 0
            // TODO(decreases) : loop index not exposed; possible bug
            // assert : table.entries.val.length() >= 0
            items.push(value_to_datum_element(entry.key))
          }
          Value::Datum(Datum::Vector(items))
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::HashtableEntries =>
      match args.length() {
        1 => {
          let table = value_as_hashtable(args[0])
          let key_items : Array[Datum] = []
          let value_items : Array[Datum] = []
          for entry in table.entries.val {
            // invariant : table.entries.val.length() >= 0
            // TODO(decreases) : loop index not exposed; possible bug
            // assert : table.entries.val.length() >= 0
            key_items.push(value_to_datum_element(entry.key))
            value_items.push(value_to_datum_element(entry.value.val))
          }
          Value::Values([
            Value::Datum(Datum::Vector(key_items)),
            Value::Datum(Datum::Vector(value_items)),
          ])
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::HashtableEquivalenceFunction =>
      match args.length() {
        1 => {
          let table = value_as_hashtable(args[0])
          hashtable_equiv_to_value(table.equiv)
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::HashtableHashFunction =>
      match args.length() {
        1 => {
          let table = value_as_hashtable(args[0])
          match table.hash {
            Some(hash) => hash
            None => Value::Datum(Datum::Bool(false))
          }
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::HashtableMutableP =>
      match args.length() {
        1 => {
          let table = value_as_hashtable(args[0])
          bool_value(table.mutable)
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::MakeEnumeration =>
      match args.length() {
        1 => {
          let names = enum_set_symbol_list(args[0])
          ensure_unique_symbols(names)
          let members = enum_set_members_all_true(names)
          Value::EnumSet(make_enum_set(names, members))
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::EnumSetUniverse =>
      match args.length() {
        1 => {
          let set = value_as_enum_set(args[0])
          let members = enum_set_members_all_true(set.universe)
          Value::EnumSet(make_enum_set(set.universe, members))
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::EnumSetIndexer =>
      match args.length() {
        1 => {
          let set = value_as_enum_set(args[0])
          Value::EnumSetProc(make_enum_set_proc(EnumSetProcKind::Indexer(set)))
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::EnumSetConstructor =>
      match args.length() {
        1 => {
          let set = value_as_enum_set(args[0])
          Value::EnumSetProc(
            make_enum_set_proc(EnumSetProcKind::Constructor(set)),
          )
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::EnumSetP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::EnumSet(_) => bool_value(true)
            _ => bool_value(false)
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::EnumSetMemberP =>
      match args.length() {
        2 => {
          let name = parse_symbol(value_as_datum(args[0]))
          let set = value_as_enum_set(args[1])
          bool_value(enum_set_member_by_name(set, name))
        }
        n => raise arity_mismatch(2, n)
      }
    Primitive::EnumSetSubsetP =>
      match args.length() {
        2 => {
          let left = value_as_enum_set(args[0])
          let right = value_as_enum_set(args[1])
          enum_set_require_same_universe(left, right)
          let ok = for i = 0; i < left.members.length(); {
            // invariant : i >= 0 && i <= left.members.length()
            // decreases : left.members.length() - i
            // assert : i <= left.members.length()
            if left.members[i] && !right.members[i] {
              break false
            }
            continue i + 1
          } else {
            true
          }
          bool_value(ok)
        }
        n => raise arity_mismatch(2, n)
      }
    Primitive::EnumSetEq =>
      match args.length() {
        2 => {
          let left = value_as_enum_set(args[0])
          let right = value_as_enum_set(args[1])
          enum_set_require_same_universe(left, right)
          let ok = for i = 0; i < left.members.length(); {
            // invariant : i >= 0 && i <= left.members.length()
            // decreases : left.members.length() - i
            // assert : i <= left.members.length()
            if left.members[i] != right.members[i] {
              break false
            }
            continue i + 1
          } else {
            true
          }
          bool_value(ok)
        }
        n => raise arity_mismatch(2, n)
      }
    Primitive::EnumSetUnion =>
      match args.length() {
        2 => {
          let left = value_as_enum_set(args[0])
          let right = value_as_enum_set(args[1])
          enum_set_require_same_universe(left, right)
          let members = enum_set_members_all_false(left.universe)
          for i = 0; i < members.length(); {
            // invariant : i >= 0 && i <= members.length()
            // decreases : members.length() - i
            // assert : i <= members.length()
            members[i] = left.members[i] || right.members[i]
            continue i + 1
          }
          Value::EnumSet(make_enum_set(left.universe, members))
        }
        n => raise arity_mismatch(2, n)
      }
    Primitive::EnumSetIntersection =>
      match args.length() {
        2 => {
          let left = value_as_enum_set(args[0])
          let right = value_as_enum_set(args[1])
          enum_set_require_same_universe(left, right)
          let members = enum_set_members_all_false(left.universe)
          for i = 0; i < members.length(); {
            // invariant : i >= 0 && i <= members.length()
            // decreases : members.length() - i
            // assert : i <= members.length()
            members[i] = left.members[i] && right.members[i]
            continue i + 1
          }
          Value::EnumSet(make_enum_set(left.universe, members))
        }
        n => raise arity_mismatch(2, n)
      }
    Primitive::EnumSetDifference =>
      match args.length() {
        2 => {
          let left = value_as_enum_set(args[0])
          let right = value_as_enum_set(args[1])
          enum_set_require_same_universe(left, right)
          let members = enum_set_members_all_false(left.universe)
          for i = 0; i < members.length(); {
            // invariant : i >= 0 && i <= members.length()
            // decreases : members.length() - i
            // assert : i <= members.length()
            members[i] = left.members[i] && !right.members[i]
            continue i + 1
          }
          Value::EnumSet(make_enum_set(left.universe, members))
        }
        n => raise arity_mismatch(2, n)
      }
    Primitive::EnumSetComplement =>
      match args.length() {
        1 => {
          let set = value_as_enum_set(args[0])
          let members = enum_set_members_all_false(set.universe)
          for i = 0; i < members.length(); {
            // invariant : i >= 0 && i <= members.length()
            // decreases : members.length() - i
            // assert : i <= members.length()
            members[i] = !set.members[i]
            continue i + 1
          }
          Value::EnumSet(make_enum_set(set.universe, members))
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::EnumSetProjection =>
      match args.length() {
        2 => {
          let source = value_as_enum_set(args[0])
          let target = value_as_enum_set(args[1])
          let members = enum_set_members_all_false(target.universe)
          for i = 0; i < target.universe.length(); {
            // invariant : i >= 0 && i <= target.universe.length()
            // decreases : target.universe.length() - i
            // assert : i <= target.universe.length()
            let name = target.universe[i]
            members[i] = enum_set_member_by_name(source, name)
            continue i + 1
          }
          Value::EnumSet(make_enum_set(target.universe, members))
        }
        n => raise arity_mismatch(2, n)
      }
    Primitive::EnumSetToList =>
      match args.length() {
        1 => {
          let set = value_as_enum_set(args[0])
          let items : Array[Datum] = []
          for i = 0; i < set.universe.length(); {
            // invariant : i >= 0 && i <= set.universe.length()
            // decreases : set.universe.length() - i
            // assert : i <= set.universe.length()
            if set.members[i] {
              items.push(Datum::Symbol(set.universe[i]))
            }
            continue i + 1
          }
          Value::Datum(list_from_array(items))
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::Display =>
      match args.length() {
        1 => {
          let port = get_current_output_port()
          port_write(port, display_string(args[0]))
          Value::Void
        }
        2 => {
          let port = value_as_port(args[1])
          port_write(port, display_string(args[0]))
          Value::Void
        }
        n => raise @core.EvalError("arity mismatch: expected 1 or 2 got \{n}")
      }
    Primitive::Write =>
      match args.length() {
        1 => {
          let port = get_current_output_port()
          port_write(port, value_to_string(args[0]))
          Value::Void
        }
        2 => {
          let port = value_as_port(args[1])
          port_write(port, value_to_string(args[0]))
          Value::Void
        }
        n => raise @core.EvalError("arity mismatch: expected 1 or 2 got \{n}")
      }
    Primitive::Newline =>
      match args.length() {
        0 => {
          let port = get_current_output_port()
          port_write(port, "\n")
          Value::Void
        }
        1 => {
          let port = value_as_port(args[0])
          port_write(port, "\n")
          Value::Void
        }
        n => raise @core.EvalError("arity mismatch: expected 0 or 1 got \{n}")
      }
    Primitive::OpenOutputString =>
      match args.length() {
        0 => Value::Port(new_output_string_port())
        n => raise arity_mismatch(0, n)
      }
    Primitive::GetOutputString =>
      match args.length() {
        1 => {
          let port = value_as_port(args[0])
          Value::Datum(Datum::String(Ref::new(port_get_output_string(port))))
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::CurrentOutputPort =>
      match args.length() {
        0 => Value::Port(get_current_output_port())
        n => raise arity_mismatch(0, n)
      }
    Primitive::WithExceptionHandler =>
      raise @core.EvalError(
        "internal error: with-exception-handler should be handled in apply_proc",
      )
    Primitive::Raise =>
      raise @core.EvalError(
        "internal error: raise should be handled in apply_proc",
      )
    Primitive::RaiseContinuable =>
      raise @core.EvalError(
        "internal error: raise-continuable should be handled in apply_proc",
      )
    Primitive::Error =>
      raise @core.EvalError(
        "internal error: error should be handled in apply_proc",
      )
    Primitive::AssertionViolation =>
      raise @core.EvalError(
        "internal error: assertion-violation should be handled in apply_proc",
      )
    Primitive::ImplementationRestrictionViolation =>
      raise @core.EvalError(
        "internal error: implementation-restriction-violation should be handled in apply_proc",
      )
    Primitive::UndefinedViolation =>
      raise @core.EvalError(
        "internal error: undefined-violation should be handled in apply_proc",
      )
    Primitive::SyntaxViolation =>
      raise @core.EvalError(
        "internal error: syntax-violation should be handled in apply_proc",
      )
    Primitive::Not =>
      match args.length() {
        1 => bool_value(is_false(args[0]))
        n => raise arity_mismatch(1, n)
      }
    Primitive::Apply =>
      // handled by apply_proc to allow proper argument flattening
      raise @core.EvalError(
        "internal error: apply should be handled in apply_proc",
      )
    Primitive::CallCC =>
      raise @core.EvalError(
        "internal error: call/cc should be handled in apply_proc",
      )
    Primitive::Map =>
      raise @core.EvalError(
        "internal error: map should be handled in apply_proc",
      )
    Primitive::ForEach =>
      raise @core.EvalError(
        "internal error: for-each should be handled in apply_proc",
      )
    Primitive::VectorMap =>
      raise @core.EvalError(
        "internal error: vector-map should be handled in apply_proc",
      )
    Primitive::VectorForEach =>
      raise @core.EvalError(
        "internal error: vector-for-each should be handled in apply_proc",
      )
    Primitive::StringMap =>
      raise @core.EvalError(
        "internal error: string-map should be handled in apply_proc",
      )
    Primitive::StringForEach =>
      raise @core.EvalError(
        "internal error: string-for-each should be handled in apply_proc",
      )
    Primitive::Values => Value::Values(args)
    Primitive::MakeVariableTransformer =>
      match args.length() {
        1 => {
          if !is_procedure_value(args[0]) {
            raise @core.EvalError("type error: procedure expected")
          }
          args[0]
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::GenerateTemporaries =>
      match args.length() {
        1 => {
          let datum = value_as_datum(args[0])
          let items = datum_list_to_array(datum)
          let results : Array[Datum] = []
          for item in items {
            // invariant : items.length() >= 0
            // TODO(decreases) : loop index not exposed; possible bug
            // assert : items.length() >= 0
            let (name, scopes, binding_id) = match datum_unlabel(item) {
              Datum::Symbol(name) => (name, [], None)
              Datum::Value(Value::SyntaxObject(obj)) =>
                match datum_unlabel(obj.datum) {
                  Datum::Symbol(name) => {
                    let copied : Array[Int] = []
                    for scope in obj.scopes {
                      // invariant : obj.scopes.length() >= 0
                      // TODO(decreases) : loop index not exposed; possible bug
                      // assert : obj.scopes.length() >= 0
                      copied.push(scope)
                    }
                    (name, copied, obj.binding_id)
                  }
                  _ => raise @core.EvalError("type error: identifier expected")
                }
              _ => raise @core.EvalError("type error: identifier expected")
            }
            let datum = Datum::Symbol(gensym(name))
            let temp = Value::SyntaxObject(SyntaxObject::{
              datum,
              scopes,
              binding_id,
            })
            results.push(value_to_datum_element(temp))
          }
          Value::Datum(list_from_array(results))
        }
        n => raise arity_mismatch(1, n)
      }
    Primitive::CallWithValues =>
      raise @core.EvalError(
        "internal error: call-with-values should be handled in apply_proc",
      )
    Primitive::MakeParameter =>
      raise @core.EvalError(
        "internal error: make-parameter should be handled in apply_proc",
      )
    Primitive::DynamicWind =>
      raise @core.EvalError(
        "internal error: dynamic-wind should be handled in apply_proc",
      )
    Primitive::Eval =>
      raise @core.EvalError(
        "internal error: eval should be handled in apply_proc",
      )
    Primitive::Environment =>
      raise @core.EvalError(
        "internal error: environment should be handled in apply_proc",
      )
    Primitive::PromiseP =>
      match args.length() {
        1 =>
          match args[0] {
            Value::Promise(_) => bool_value(true)
            _ => bool_value(false)
          }
        n => raise arity_mismatch(1, n)
      }
    Primitive::MakePromise =>
      raise @core.EvalError(
        "internal error: make-promise should be handled in apply_proc",
      )
    Primitive::Force =>
      raise @core.EvalError(
        "internal error: force should be handled in apply_proc",
      )
    _ =>
      raise @core.EvalError(
        "internal error: primitive should be handled by specialized dispatcher",
      )
  }
}
