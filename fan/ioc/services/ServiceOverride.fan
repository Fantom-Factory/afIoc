
** Override a defined service with your own implementation. 
** 
** pre>
**   static Void bind(ServiceBinder binder) {
**     binder.bindImpl(PieAndChips#).withId("dinner")
**   }
** 
**   @Contribute
**   static Void contributeServiceOverride(MappedConfig config) {
**     config.addMapped("dinner", config.autobuild(PieAndMash#))
**   }
** <pre
**
** Note at present you can not override `perThread` scoped services and non-const (not immutable) 
** services. 
**  
** @since 1.2
** @uses MappedConfig of Str:Obj (serviceId:overrideImpl)
// Override perThread services should be automatic when proxies are added.
// TODO: Registry.autobuild should create proxies
const mixin ServiceOverride {
	
	abstract Obj? getOverride(Str serviceId)

}

