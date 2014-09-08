
internal const mixin ServiceBuilders {
	
	static |->Obj| fromBuildMethod(Str serviceId, Method method, Obj? instance := null, Obj[]? args := null) {
		|->Obj| {
			InjectionTracker.track("Creating Service '$serviceId' via builder method '$method.qname'") |->Obj| {
				InjectionUtils.callMethod(method, instance, args)
			}
		}
	}
	
	static |->Obj| fromCtorAutobuild(Str serviceId, Method ctor, Obj?[]? ctorArgs, [Field:Obj?]? fieldVals) {
		|->Obj| {
			InjectionTracker.track("Creating Serivce '$serviceId' via ctor autobuild") |->Obj| {				
				obj := InjectionUtils.createViaConstructor(ctor, ctorArgs, fieldVals)
				return InjectionUtils.injectIntoFields(obj)
			}
		}
	}
}

