
** Hook to extend the capabilities of IoC and provide custom dependency resolution. 
** 
** Contribute 'DependencyProvider' instances to the 'DependencyProviders' service.
** 
** pre>
** syntax: fantom
** @Contribute { serviceType=DependencyProviders# }
** Void contributeDependencyProviders(Configuration config) {
**     config["myProvider"] = MyProvider()
** }
** <pre
** 
@Js
const mixin DependencyProvider {

	** Return 'true' if the provider can provide. (!)
	** All details of the injection to be performed is in 'InjectionCtx'.
	** 
	** This method exists to allow 'provide()' to return 'null'.
	abstract Bool canProvide(Scope currentScope, InjectionCtx injectionCtx)

	** Return the dependency to be injected. 
	** All details of the injection to be performed is in 'InjectionCtx'.
	** 
	** Only called if 'canProvide()' returns 'true'.
	abstract Obj? provide(Scope currentScope, InjectionCtx injectionCtx)
	
}
