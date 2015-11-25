
@Js
internal const class NonInvasiveInspector : ModuleInspector {

	override Void inspect(RegistryBuilder bob, Obj module) {
		methods := module.typeof.methods.rw.sort |Method a, Method b -> Int| { a.name <=> b.name }

		methods.each |method| {
			// I wanted 'defineModule()' but IoC 2 picks up defineXXXX() breaking backwards compatibility for libs like afConcurrent
			if (method.name.equalsIgnoreCase("nonInvasiveIocModule") && method.params.isEmpty && method.returns.fits([Str:Obj]#))
				addModule(bob, module, method)
		}		
	}
	
	// As used by afPlastic, afConcurrent
	private Void addModule(RegistryBuilder regBob, Obj module, Method method) {
		map := (Str:Obj) method.callOn(method.isStatic ? null : module, null)
		
		services := ([Str:Obj][]?) map["services"]
		services?.each {
			bob := (ServiceBuilderImpl) regBob.addService
			bob.withId			(it["id"])
			bob.withType		(it["type"])
			bob.withImplType	(it["implType"])
			bob.withScopes		(it["scopes"])
			bob.withBuilder		(it["builder"])
			bob.withCtorArgs	(it["ctorArgs"])
			bob.withFieldVals	(it["fieldVals"])
			bob.srvDef.aliases	=it["aliases"]
			bob.srvDef.aliasTypes=it["aliasTypes"]
		}

		// Note - all contributions and constraints are optional
		// if you need them to exist, you can bloody well reference IoC!
		contributions := ([Str:Obj][]?) map["contributions"]
		contributions?.each {
			serviceId	:= (Str)		it["serviceId"]
			key			:= (Obj?)		it["key"]
			value		:= (Obj?)		it["value"]
			valueFunc	:= (Func?)		it["valueFunc"]
			build		:= (Type?)		it["build"]
			before		:= (Obj?)		it["before"]
			after		:= (Obj?)		it["after"]
			regBob.contributeToService(serviceId, |Configuration config| {
				if (build != null)
					value = config.build(build)

				// used by afSlim
				if (valueFunc != null)
					value = config.scope.callFunc(valueFunc)

				// a cheap hack for IoCs only implementation mixin
				// used by afConcurrent for its LocalRefProvider
				if (serviceId == DependencyProviders#.qname)
					value = DependencyProviderProxy(value)
				
				constraints := (Constraints?) null
				if (key == null)
					constraints = config.add(value)
				else
					constraints = config.set(key, value)
				
				if (before != null)
					constraints.before(before, true)
				if (after != null)
					constraints.after(after, true)
				
			}, true)
		}
	}	
}

@Js
internal const class DependencyProviderProxy : DependencyProvider {

	const Obj target

	new make(Obj target) {
		this.target = target 
	}

	override Bool canProvide(Scope scope, InjectionCtx ctx) {
		target->canProvide(scope, ctx)
	}
	
	override Obj? provide(Scope scope, InjectionCtx ctx) {
		target->provide(scope, ctx)
	}
}