using afBeanUtils

** (Service) -
** Contribute your `DependencyProvider` implementations to this. 
** Provide your own dependencies for fields annotated with the '@Inject' facet. 
** Typically you would augment '@Inject' with your own facet to provide injection meta. 
** 
** See [@LogProvider]`LogProvider` for a builtin example. 
** 
** pre>
** @Contribute { serviceType=DependencyProviders# }
** static Void contributeDependencyProviders(Configuration conf) {
**   conf["myProvider"] = MyProvider()
** }
** <pre
** 
** @since 1.1
** 
** @uses Configuration of 'DependencyProvider[]'
// this service makes for a handy backdoor for field injection for efanXtra
@NoDoc	// don't overwhelm the masses
const mixin DependencyProviders {

	@NoDoc	// used for internal testing
	abstract DependencyProvider[] dependencyProviders()

	abstract Bool canProvideDependency(InjectionCtx injectionCtx)

	abstract Obj? provideDependency(InjectionCtx injectionCtx, Bool checked := true)
}

** @since 1.1.0
internal const class DependencyProvidersImpl : DependencyProviders {
	override const DependencyProvider[] dependencyProviders

	new makeInternal(DependencyProvider[] dependencyProviders) {
		this.dependencyProviders = dependencyProviders
	}

	@Inject
	new make(DependencyProvider[] dependencyProviders, Registry registry) {
		serviceProvider := (ServiceProvider) registry.autobuild(ServiceProvider#)
		this.dependencyProviders = dependencyProviders.add(serviceProvider).toImmutable
		
		// eager load all dependency providers else recursion err (app hangs) when creating DPs 
		// with lazy services
		ctx := InjectionCtx(InjectionKind.dependencyByType) { it.dependencyType = Void# }
		dependencyProviders.each { it.canProvide(ctx) }
	}

	override Bool canProvideDependency(InjectionCtx ctx) {
		InjectionTracker.track("Looking for dependency of type $ctx.dependencyType") |->Obj?| {
			dependencyProviders.any |depPro->Bool| {
				depPro.canProvide(ctx)
			}
		}
	}
	
	override Obj? provideDependency(InjectionCtx ctx, Bool checked := true) {
		InjectionTracker.track("Looking for dependency of type $ctx.dependencyType") |->Obj?| {
			dependency := null
			
			found := dependencyProviders.any |depPro->Bool| {
				if (depPro.canProvide(ctx)) {
					dependency = depPro.provide(ctx)
					
					if (dependency == null) {
						if (!ctx.dependencyType.isNullable )
							throw IocErr(IocMessages.dependencyDoesNotFit(null, ctx.dependencyType))
					} else {
						if (!ReflectUtils.fits(dependency.typeof, ctx.dependencyType))
							throw IocErr(IocMessages.dependencyDoesNotFit(dependency.typeof, ctx.dependencyType))
					}
	
					return true
				}
				return false
			}
	
			if (found)
				return dependency
	
			return checked ? throw IocErr(IocMessages.dependencyNotFound(ctx.dependencyType)) : null
		}
	}
}
