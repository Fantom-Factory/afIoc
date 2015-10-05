
@Js
internal const class StandardInspector : ModuleInspector {
	
	override Void inspect(RegistryBuilder bob, Obj module) {
		moduleType := module.typeof

		methods := moduleType.methods.rw.sort |Method a, Method b -> Int| { 
			a.name <=> b.name 
		}

		methods.each |method| {
			if (method.params.size == 1 && RegistryBuilder# == method.params.first.type)
				method.callOn(method.isStatic ? null : module, [bob])
		}
	}
}
