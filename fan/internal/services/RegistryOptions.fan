
** @Inject - Holds the options passed into [RegistryBuilder.build()]`RegistryBuilder.build`.
** Useful for passing external immutable data into services.   
const mixin RegistryOptions {
	
	** The options passed as into [RegistryBuilder.build()]`RegistryBuilder.build`.
	abstract [Str:Obj?] options()
	
}

internal const class RegistryOptionsImpl : RegistryOptions {
	
	override const [Str:Obj?] options

	new make([Str:Obj?] options) {
		this.options = options.toImmutable
	}
}