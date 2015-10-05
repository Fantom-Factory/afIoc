
** Use to inject freshly created object instances. 
** Instances are created via [Scope.build()]`Scope.build`.
@Js
facet class Autobuild {
	
	** The implementation type to create, if different to the Field.
	const Type? implType
	
	** Arguments to pass to the implementation ctor.
	const Obj?[]? ctorArgs
	
	** Optional fields to set via an it-block ctor argument.
	const [Field:Obj?]? fieldVals
}
