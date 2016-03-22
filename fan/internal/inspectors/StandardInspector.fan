
@Js
internal const class StandardInspector : ModuleInspector {
	private static const Log log := StandardInspector#.pod.log
	
	override Void inspect(RegistryBuilder bob, Obj module) {
		moduleType := module.typeof

		methods := moduleType.methods.rw.sort |Method a, Method b -> Int| { 
			a.name <=> b.name 
		}

		methods.each |method| {
			if (method.params.size == 1 && method.name.startsWith("define") && method.params.first.type.toNonNullable == RegistryBuilder#)
				method.callOn(method.isStatic ? null : module, [bob])
			
			if (method.name == "onRegistryStartup")
				if (method.params.first?.type?.toNonNullable == Configuration#)
					bob.onRegistryStartup |Configuration config| {
						config.scope.callMethod(method, module, [config])
					}
				else
					bob.onRegistryStartup |Configuration config| {
						// if onRegistryStartup() doesn't take a config, then it doesn't care when it gets called!
						config.add |->| {
							config.scope.callMethod(method, module)
						}
					}

			if (method.name == "onRegistryShutdown")
				if (method.params.first?.type?.toNonNullable == Configuration#)
					bob.onRegistryShutdown |Configuration config| {
						config.scope.callMethod(method, module, [config])
					}
				else
					bob.onRegistryShutdown |Configuration config| {
						// if onRegistryShutdown() doesn't take a config, then it doesn't care when it gets called!
						config.add |->| {
							config.scope.callMethod(method, module)
						}
					}
		}
	}
}
