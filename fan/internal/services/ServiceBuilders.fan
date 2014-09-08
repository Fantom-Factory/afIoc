
internal const class ServiceBuilders {

	private const InjectionUtils injectionUtils
	
	new make(InjectionUtils injectionUtils) {
		this.injectionUtils = injectionUtils 
	}

	|->Obj| fromBuildMethod(Str serviceId, Method method, Obj? instance := null, Obj[]? args := null) {
		|->Obj| {
			InjectionTracker.track("Creating Service '$serviceId' via builder method '$method.qname'") |->Obj| {
				injectionUtils.callMethod(method, instance, args)
			}
		}
	}
	
	|->Obj| fromCtorAutobuild(Str serviceId, Method ctor, Obj?[]? ctorArgs, [Field:Obj?]? fieldVals) {
		|->Obj| {
			InjectionTracker.track("Creating Serivce '$serviceId' via ctor autobuild") |->Obj| {				
				obj := injectionUtils.createViaConstructor(ctor, ctorArgs, fieldVals)
				return injectionUtils.injectIntoFields(obj)
			}
		}
	}
}

