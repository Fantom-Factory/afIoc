
internal class CtorPlanBuilder {
	private Type 		type
	private Field:Obj? 	ctorPlan := [:]
	
	new make(Type type) {
		this.type = type
	}
	
	** Fantom Bug: http://fantom.org/sidewalk/topic/2163#c13978
	@Operator 
	private Obj? get(Obj key) { null }

	@Operator
	This set(Str fieldName, Obj? val) {
		field := type.field(fieldName)
		ctorPlan[field] = val
		return this
	}

	|Obj| toCtorFunc() {
		Field.makeSetFunc(ctorPlan)
	}

	Obj makeObj() {
		type.make([toCtorFunc])
	}
}
