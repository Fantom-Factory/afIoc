
** As thrown by IoC
const class IocErr : Err {
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}

//const class UnknownValueErr : IocErr {
//	new make(Str msg, Str valueType, Obj[] values, Err? cause := null) : super(msg + availableValues(valueType, values), cause) {}
//
//	Str availableValues(Str valueType, Obj[] values) {
//		vals := values.map |Obj? value->Str?| { value?.toStr }.exclude |value| { value == null }.join(", ")
//		return " Available $valueType = ${valueType}: ${vals}"
//	}	
//}

**
** Throw when an impossible condition occurs. You'll know when - we've all written comments like:
** 
** '// this should never happen...' 
** 
const class WtfErr : Err {
	new make(Str msg, Err? cause := null) : super(msg, cause) {}
}
