using compiler
using afPlastic::IocClassModel
using afPlastic::PlasticCompiler
using afConcurrent::SynchronizedMap
using afBeanUtils::BeanFactory

** (Service) - Builds and caches Proxy Types. The Types are cached because:
**  - as they're already loaded by the VM, we may as well!
**  - we have to, to prevent memory leaks!
** 
** Think of afBedSheet when a new Request / Response proxy is built on every request!
** 
** @since 1.3.0
@NoDoc
const mixin ServiceProxyBuilder {

	internal abstract Obj createProxyForService(ServiceDef serviceDef)

	** Returns a cached Type if exists, otherwise compiles a new proxy type 
	internal abstract Type compileProxyType(Type serviceType)
}



** @since 1.3.0
internal const class ServiceProxyBuilderImpl : ServiceProxyBuilder {

	@Inject private const Registry 			registry
	@Inject	private const PlasticCompiler	plasticCompiler
			private const SynchronizedMap 	typeCache
		
	new make(ActorPools actorPools, |This|in) {
		in(this) 
		typeCache = SynchronizedMap(actorPools[IocConstants.systemActorPool])
	}

	** We need the serviceDef as only *it* knows how to build the serviceImpl
	override internal Obj createProxyForService(ServiceDef serviceDef) {
		InjectionTracker.track("Creating Proxy for service '$serviceDef.serviceId'") |->Obj| {
			serviceType	:= serviceDef.serviceType			
			proxyType	:= compileProxyType(serviceType)
			builder		:= CtorPlanBuilder(proxyType)
			builder["afLazyService"] = LazyProxyImpl((ObjLocator) registry, serviceDef)
			return builder.create
		}
	}
	
	override Type compileProxyType(Type serviceType) {
		typeCache.getOrAdd(serviceType.qname) |->Type| {  
			if (!serviceType.isMixin)
				throw IocErr(IocMessages.onlyMixinsCanBeProxied(serviceType))
	
			if (!serviceType.isPublic)
				throw IocErr(IocMessages.proxiedMixinsMustBePublic(serviceType))
		
			model := IocClassModel(serviceType.name + "Proxy", serviceType.isConst)
			
			model.extendMixin(serviceType)
			model.addField(LazyProxy#, "afLazyService")
	
			serviceType.fields.rw
				.findAll { it.isAbstract || it.isVirtual }
				.each |field| {
					getBody	:= "((${serviceType.qname}) afLazyService.service).${field.name}"
					setBody	:= "((${serviceType.qname}) afLazyService.service).${field.name} = it"
					model.overrideField(field, getBody, setBody)
				}
	
			serviceType.methods.rw
				.findAll { it.isAbstract || it.isVirtual }
				.exclude { Obj#.methods.contains(it) }
				.each |method| {
					params 	:= method.params.join(", ") |param| { param.name }
					paramLt	:= params.isEmpty ? "Obj#.emptyList" : "[${params}]" 
					body 	:= "afLazyService.call(${serviceType.qname}#${method.name}, ${paramLt})"
					model.overrideMethod(method, body)
				}
	
			Pod? pod
			code 		:= model.toFantomCode
			podName		:= plasticCompiler.generatePodName
			InjectionTracker.track("Compiling Pod '$podName'") |->Obj| {
				pod 	= plasticCompiler.compileCode(code, podName)
			}			
			proxyType 	:= pod.type(model.className)
					
			return proxyType
		}
	}	
}
