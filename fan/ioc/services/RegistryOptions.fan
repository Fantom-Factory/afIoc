
** (Service) - Holds the options passed into [RegistryBuilder.build()]`RegistryBuilder.build`.
** Useful for passing external immutable data into services.   
const mixin RegistryOptions {
	
	** The options passed as into [RegistryBuilder.build()]`RegistryBuilder.build`.
	abstract [Str:Obj?] options()

	** Return the value for the specified key. 
	@Operator
	abstract Obj? get(Str key)

	** Returns 'true' if the specified key is mapped. 
	abstract Bool containsKey(Str key)
}

internal const class RegistryOptionsImpl : RegistryOptions {
	
	override const [Str:Obj?] options

	new make([Str:Obj?] options) {
		this.options = options.toImmutable
	}
	
	@Operator
	override Obj? get(Str key) {
		options[key]
	}

	override Bool containsKey(Str key) {
		options.containsKey(key)
	}
}