
@Js
internal const class StandardInspector : ModuleInspector {
	
	override Void inspect(RegistryBuilder bob, Obj module) {
		moduleType := module.typeof

		methods := moduleType.methods.rw.sort |Method a, Method b -> Int| { 
			a.name <=> b.name 
		}

		methods.each |method| {
			if (method.params.size == 1 && method.name.startsWith("define") && method.params.first.type.toNonNullable == RegistryBuilder#)
				method.callOn(method.isStatic ? null : module, [bob])
			
			if (method.name == "onRegistryStartup" && method.params.first?.type?.toNonNullable == Configuration#)
				bob.onRegistryStartup |Configuration config| {
					config.scope.callMethod(method, module, [config])
				}

			if (method.name == "onRegistryShutdown" && method.params.first?.type?.toNonNullable == Configuration#)
				bob.onRegistryShutdown |Configuration config| {
					config.scope.callMethod(method, module, [config])
				}
		}
	}
}
