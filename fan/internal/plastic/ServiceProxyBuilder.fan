
@NoDoc
const class ServiceProxyBuilder {
	
	@Inject 
	private const Registry registry
	
	@Inject
	private const PlasticPodCompiler plasticPodCompiler
	
	new make(|This|di) { di(this) }

	** We need the serviceDef as only *it* knows how to build the serviceImpl
	internal Obj buildProxy(ServiceDef serviceDef) {
		serviceId	:= serviceDef.serviceId
		serviceType	:= serviceDef.serviceType
		
		if (!serviceType.isMixin)
			throw IocErr(IocMessages.onlyMixinsCanBeProxied(serviceType))

		if (!serviceType.isPublic)
			throw IocErr(IocMessages.proxiedMixinsMustBePublic(serviceType))
		
		model := PlasticClassModel(serviceType.name + "Impl", serviceType.isConst)
		
		model.extendMixin(serviceType)
		model.addField(LazyService#, "lazyService")

		methods := serviceType.methods.rw.findAll { it.isAbstract || it.isVirtual }
		Obj#.methods.each { methods.remove(it) }

		methods.each |method| {
			params 	:= method.params.join(", ") |param| { param.name }
			body 	:= "(lazyService.get as ${serviceType.qname}).${method.name}(${params})"
			model.overrideMethod(method, body)
		}
		
		code 		:= model.toFantomCode		
		pod 		:= plasticPodCompiler.compile(code)
		proxyType 	:= pod.type(model.className)
		lazyField 	:= proxyType.field("lazyService")
		plan 		:= Field:Obj?[lazyField : LazyService(serviceDef, (ObjLocator) registry)]
		ctorFunc 	:= Field.makeSetFunc(plan)
		proxy		:= proxyType.make([ctorFunc])
		
		return proxy
	}
}
