using concurrent::AtomicRef

** (Service) - A `DependencyProvider` that injects 'Log' instances.
** 
** For field injection 'LogProvider' reuses the '@Inject' facet:
** 
**   syntax: fantom
**   @Inject Log log
**  
** By default, the class's pod name is used to create the log instance. In essence this is: 
** 
**   syntax: fantom
**   target.typeof.pod.log
** 
** Custom log names may be provided via the '@Inject.id' parameter:
** 
**   syntax: fantom
**   @Inject { id="my.log.name" } Log log
** 
** You may also create a 'LogProvider' with a custom log function. Example, to override the default
** 'LogProvider' with one that generates log names based on the target type (and not pod): 
** 
** pre>
** syntax: fantom
** class AppModule {
** 
**     @Override
**     static LogProvider overrideLogProvider() {
**         LogProvider.withLogFunc |Type type->Log| { Log.get(type.name) } 
**     }
** } 
** <pre
**  
const mixin LogProvider : DependencyProvider {
	
	** Creates a 'LogProvider' with the given log creation func.
	static new withLogFunc(|Type->Log| func) {
		LogProviderImpl(func)
	}
}

internal const class LogProviderImpl : LogProvider {
	const |Type->Log| logCreatorFunc
	
	new make(|Type type->Log| logCreatorFunc, |This|? in := null) {
		this.logCreatorFunc = logCreatorFunc
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
