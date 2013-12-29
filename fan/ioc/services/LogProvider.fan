using concurrent::AtomicRef

** (Service) - A provider that injects 'Log' instances. 
** By default the Log name is the types's pod name. 
** If different logger instances are desired, change the `#logCreatorFunc`.
const class LogProvider : DependencyProvider {

	private const AtomicRef logCreatorFuncRef	:= AtomicRef()
	
	** The func that creates log instances from a given type. Change it at will!
	** 
	** Defaults to '|Type type->Log| { return type.pod.log }'
	|Type->Log| logCreatorFunc {
		get { logCreatorFuncRef.val }
		set { logCreatorFuncRef.val = it }
	}	

	internal new make(|This|? in := null) { 
		logCreatorFunc = |Type type->Log| { return type.pod.log }
		in?.call(this)
	}

	override Bool canProvide(ProviderCtx ctx) {
		ctx.dependencyType.fits(Log#) && (ctx.injectingInto != null)
	}

	override Obj? provide(ProviderCtx ctx) {
		ctx.log("Injecting Log for ${ctx.injectingIntoType.qname}")
		return logCreatorFunc.call(ctx.injectingIntoType)
	}
}
