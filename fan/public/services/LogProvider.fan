using concurrent::AtomicRef

** (Service) - A `DependencyProvider` that injects 'Log' instances.
** 
** For field injection 'LogProvider' reuses the '@Inject' facet:
** 
**   @Inject Log log
**  
** By default, the class's pod name is used to create the log instance. 
** 
**   |Type type->Log| { return type.pod.log }
** 
** If log instances with different names are desired, override the 'LogProvider' service:
** 
** pre>
** class AppModule {
** 
**     @Override
**     static LogProvider overrideLogProvider() {
**         LogProvider.withLogFunc |Type type->Log| { Log.get(type.name) } 
**     }
** } 
** <pre
** 
** You may also provide a log name via the '@Inject.id' parameter:
** 
**   @Inject { id="my.log.name" } Log log
**  
const mixin LogProvider : DependencyProvider {
	
	** Creates a 'LogProvider' with the given log creation func.
	static LogProvider withLogFunc(|Type->Log| func) {
		LogProviderImpl {
			it.logCreatorFunc = func
		}
	}
}

internal const class LogProviderImpl : LogProvider {
	const |Type->Log| logCreatorFunc
	
	new make(|This|? in := null) {
		logCreatorFunc = |Type type->Log| { return type.pod.log }
		in?.call(this)
	}

	override Bool canProvide(InjectionCtx ctx) {
		// IoC standards dictate that field injection should be denoted by a facet
		ctx.injectionKind.isFieldInjection
			? ctx.dependencyType.fits(Log#) && ctx.targetType != null && ctx.field.hasFacet(Inject#)
			: ctx.dependencyType.fits(Log#) && ctx.targetType != null
	}

	override Obj? provide(InjectionCtx ctx) {
		ctx.log("Injecting Log for ${ctx.targetType.qname}")
		inject	:= (Inject?) ctx.fieldFacets.findType(Inject#).first
		logId	:= inject?.id
		return logId != null ? Log.get(logId) : logCreatorFunc.call(ctx.targetType)
	}
}
