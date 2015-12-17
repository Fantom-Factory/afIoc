
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
		map		 := (Str:Obj) method.callOn(method.isStatic ? null : module, null)
		moduleId := module.typeof.qname
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
			key			:= (Obj?)		toImmutableObj(moduleId, it["key"])
			value		:= (Obj?)		toImmutableObj("${moduleId}.${key}", it["value"])
			valueFunc	:= (Func?)		toImmutableObj("${moduleId}.${key}", it["valueFunc"])
			build		:= (Type?)		it["build"]
			before		:= (Obj?)		toImmutableObj("${moduleId}.${key}", it["before"])
			after		:= (Obj?)		toImmutableObj("${moduleId}.${key}", it["after"])
			
			configFunc	:= |Configuration config| {
				value2	:= value
				if (build != null)
					value2 = config.build(build)

				// used by afSlim and afWebSockets
				if (valueFunc != null)
					value2 = config.scope.callFunc(valueFunc)

				// a cheap hack for IoCs only implementation mixin
				// used by afConcurrent for its LocalRefProvider
				if (serviceId == DependencyProviders#.qname)
					value2 = DependencyProviderProxy(value2)
				
				constraints := (Constraints?) null
				if (key == null)
					constraints = config.add(value2)
				else
					constraints = config.set(key, value2)
				
				if (before != null)
					constraints.before(before, true)
				if (after != null)
					constraints.after(after, true)
			}

			switch (serviceId) {
				case "registryStartup":
					regBob.onRegistryStartup(configFunc)
			
				case "registryShutdown":
					regBob.onRegistryShutdown(configFunc)
			
				default:
					regBob.contributeToService(serviceId, configFunc, true)
			}
		}
	}
	
	private static Obj? toImmutableObj(Str moduleId, Obj? obj) {
		try
			return obj?.toImmutable
		catch 
			throw NotImmutableErr("${obj?.typeof?.qname} from module ${moduleId} is not immutable")
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