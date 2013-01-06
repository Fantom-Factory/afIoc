
const class IocErr : Err {
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}

const class UnknownValueErr : IocErr {
	new make(Str msg, Str valueType, Obj[] values, Err? cause := null) : super(msg + availableValues(valueType, values), cause) {}

	Str availableValues(Str valueType, Obj[] values) {
		vals := values.map |Obj? value->Str?| { value?.toStr }.exclude |value| { value == null }.join(", ")
		return "AvailableValues[${valueType}: ${vals}]"
	}	
}
