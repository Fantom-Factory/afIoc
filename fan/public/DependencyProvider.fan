
** A hook to provide custom dependency resolution and extend the capabilities of IoC.  
** 
** Create an instance of your 'DependencyProvider' and contribute it to the 'DependencyProviders' (*) service.
** 
** pre>
** syntax: fantom
** @Contribute { serviceType=DependencyProviders# }
** Void contributeDependencyProviders(Configuration config) {
**     config["myProvider"] = MyProvider()
** }
** <pre
** 
** Note that 'canProvide()' is called for *all* fields, not just those annotated with '@Inject'.
** 
** If your dependency provider re-uses the '@Inject' facet, then it should be ordered *before* the
** standard IoC service provider so it is queried first. The IoC service provider has an ID of 
** 'afIoc.service':
** 
** pre>
** syntax: fantom
** @Contribute { serviceType=DependencyProviders# }
** Void contributeDependencyProviders(Configuration config) {
**     config.set("myProvider", MyProvider()).before("afIoc.service")
** }
** <pre
** 
** (*) The 'DependencyProviders' service is annotated with '@NoDoc' and is not listed in the API. 
** This is because it's only used as a configuration point, so it's not very interesting!
@Js
const mixin DependencyProvider {

	** Return 'true' if the provider can provide. (!)
	** All details of the injection to be performed are in 'InjectionCtx'.
	** 
	** This method exists to allow 'provide()' to return 'null'.
	abstract Bool canProvide(Scope currentScope, InjectionCtx injectionCtx)

	** Return the dependency to be injected. 
	** All details of the injection to be performed are in 'InjectionCtx'.
	** 
	** Only called if 'canProvide()' returns 'true'.
	abstract Obj? provide(Scope currentScope, InjectionCtx injectionCtx)
	
}
