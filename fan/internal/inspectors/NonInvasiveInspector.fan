
@Js
internal const class NonInvasiveInspector : ModuleInspector {

	override Void inspect(RegistryBuilder bob, Obj module) {
		methods := module.typeof.methods.rw.sort |Method a, Method b -> Int| { a.name <=> b.name }

		methods.each |method| {
			if (method.name.equalsIgnoreCase("defineModule") && method.params.isEmpty && method.returns.fits([Str:Obj]#))
				addModule(bob, module, method)
		}		
	}
	
	private Void addModule(RegistryBuilder regBob, Obj module, Method method) {
		map := (Str:Obj) method.callOn(method.isStatic ? null : module, null)
		
		services := ([Str:Obj][]) map["services"]
		services.each {
			bob := regBob.addService
			bob.withId		(it["id"])
			bob.withType	(it["type"])
			bob.withScopes	(it["scopes"])
		}
	}
	
}
