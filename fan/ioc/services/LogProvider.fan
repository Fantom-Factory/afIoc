using concurrent::AtomicRef

** (Service) - A `DependencyProvider` that injects 'Log' instances. 
** By default, a pod name is used to create the log instance. 
** 
**   |Type type->Log| { return type.pod.log }
** 
** If log instances with different names are desired, change the `#logCreatorFunc`. 
** Do this at registry startup:
** 
** pre>
** class AppModule {
** 
**   @Contribute { serviceType=RegistryStartup# }
**   static Void changeLoggers(Configuration conf, LogProvider logProvider) {
**     conf.add |->| {
**       logProvider.logCreatorFunc = |Type type->Log| { return Log.get(type.name) } 
**     }
**   }
** } 
** <pre
const mixin LogProvider : DependencyProvider {
	
	** The func that creates log instances from a given type. Change it at will!
	** 
	** Defaults to '|Type type->Log| { return type.pod.log }'
	abstract |Type->Log| logCreatorFunc
}

internal const class LogProviderImpl : LogProvider {

	private const AtomicRef logCreatorFuncRef	:= AtomicRef()
	
	override |Type->Log| logCreatorFunc {
		get { logCreatorFuncRef.val }
		set { logCreatorFuncRef.val = it }
	}	

	internal new make(|This|? in := null) { 
		logCreatorFunc = |Type type->Log| { return type.pod.log }
		in?.call(this)
	}

	override Bool canProvide(InjectionCtx ctx) {
		ctx.dependencyType.fits(Log#) && (ctx.injectingIntoType != null)
	}

	override Obj? provide(InjectionCtx ctx) {
		ctx.log("Injecting Log for ${ctx.injectingIntoType.qname}")
		return logCreatorFunc.call(ctx.injectingIntoType)
	}
}
