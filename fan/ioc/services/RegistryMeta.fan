
@NoDoc
@Deprecated { msg="Use RegistryMeta instead" }
const mixin RegistryOptions : RegistryMeta { }

** (Service) - Holds meta information as to how the IoC registry was built.
const mixin RegistryMeta {
	
	** The options as passed as into [RegistryBuilder.build()]`RegistryBuilder.build`. 
	** This map is case-insensitive.
	** Useful for passing external immutable data into services.   
	abstract [Str:Obj?] options()

	** Return the value for the specified key. 
	@Operator
	abstract Obj? get(Str key)

	** Returns 'true' if the specified key is mapped. 
	abstract Bool containsKey(Str key)
	
	** Returns a list of modules loaded by this IoC
	abstract Type[] moduleTypes()
	
	** Returns a unique list of pods that contain modules loaded by this IoC.
	**  
	** Useful for gaining a list of pods used in an application, should you wish to *scan* for
	** classes. 
	abstract Pod[] modulePods()
}

internal const class RegistryMetaImpl : RegistryMeta {
	
	override const [Str:Obj?]	options
	override const Type[] 		moduleTypes

	new make([Str:Obj?] options, Type[] moduleTypes) {
		this.options 		= options
		this.moduleTypes	= moduleTypes
	}
	
	@Operator
	override Obj? get(Str key) {
		options[key]
	}

	override Bool containsKey(Str key) {
		options.containsKey(key)
	}
	
	override Pod[] modulePods() {
		moduleTypes.map { it.pod }.unique
	}
	
}