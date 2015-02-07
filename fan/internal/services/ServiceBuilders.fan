
internal const class ServiceBuilders {

	private const InjectionUtils injectionUtils
	
	new make(InjectionUtils injectionUtils) {
		this.injectionUtils = injectionUtils 
	}

	|->Obj| fromBuildMethod(Str serviceId, Method method, Obj? instance := null, Obj[]? args := null) {
		|->Obj| {
			InjectionTracker.track("Creating '$serviceId' via builder method '$method.qname'") |->Obj| {
				injectionUtils.callMethod(method, instance, args)
			}
		}
	}
	
	|->Obj| fromCtorAutobuild(Str serviceId, Method ctor, Obj?[]? ctorArgs, [Field:Obj?]? fieldVals) {
		|->Obj| {
			InjectionTracker.track("Creating '$serviceId' via ctor autobuild") |->Obj| {
				InjectionTracker.resetTakenFields
				try {
					target := 
					injectionUtils.createViaConstructor(ctor, ctorArgs, fieldVals)
					injectionUtils.injectIntoFields(target)
					injectionUtils.callPostInjectMethods(target)
					return target
				} finally {
					InjectionTracker.removeTakenFields					
				}
			}
		}
	}
}

