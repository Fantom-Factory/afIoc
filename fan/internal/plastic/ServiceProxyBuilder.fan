
@NoDoc
const class ServiceProxyBuilder {
	
	@Inject
	private const Registry registry
	
	@Inject
	private const Plastic plastic
	
	new make(|This|di) { di(this) }
	
	Obj buildProxy(Type serviceType) {
		
		if (!serviceType.isMixin)
			throw Err("Mixin onlys")	// TODO: better err msg

		model := PlasticClassModel(serviceType.isConst, serviceType.name + "Impl")
		
		model.extendMixin(serviceType)
		model.addField(LazyService#, "lazyService")

		methods := serviceType.methods.rw
		Obj#.methods.each { methods.remove(it) }

		methods.each |method| { 
			params 	:= method.params.join(", ") |param| { param.name }
			body 	:= "(lazyService.get as ${serviceType.qname}).${method.name}(${params})"
			model.overrideMethod(method, body)
		}
		
		code 		:= model.toFantomCode
		Env.cur.err.printLine(code)
		
		pod 		:= plastic.compile(code)
		proxyType 	:= pod.type(model.className)
		lazyField 	:= proxyType.field("lazyService")
		plan 		:= Field:Obj?[lazyField : LazyService(registry, serviceType.name)]
		ctorFunc 	:= Field.makeSetFunc(plan)
		
//		proxy		:= proxyType.make([plan])
//		return proxy
		
		return 69
	}
}
