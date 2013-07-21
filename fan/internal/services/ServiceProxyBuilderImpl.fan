using compiler

** @since 1.3.0
internal const class ServiceProxyBuilderImpl : ServiceProxyBuilder {
	
	private const ConcurrentState 	conState	:= ConcurrentState(ServiceProxyBuilderState#)
	
	@Inject 
	private const Registry registry
	
	@Inject
	private const PlasticPodCompiler plasticPodCompiler
	
	new make(|This|di) { di(this) }

	** We need the serviceDef as only *it* knows how to build the serviceImpl
	override internal Obj buildProxy(InjectionCtx ctx, ServiceDef serviceDef) {
		ctx.track("Creating Proxy for service '$serviceDef.serviceId'") |->Obj| {
			serviceType	:= serviceDef.serviceType			
			proxyType	:= buildProxyType(ctx, serviceType)
			lazyField 	:= proxyType.field("afLazyService")
			plan 		:= Field:Obj?[lazyField : LazyService(ctx, serviceDef, (ObjLocator) registry)]
			ctorFunc 	:= Field.makeSetFunc(plan)
			proxy		:= proxyType.make([ctorFunc])
			
			return proxy
		}
	}
	
	override Type buildProxyType(InjectionCtx ctx, Type serviceType) {
		// TODO: investigate why getState() throws NPE when type not cached
		if (getState { it.proxyTypeCache.containsKey(serviceType) })
			return getState { it.proxyTypeCache[serviceType] }

		if (!serviceType.isMixin)
			throw IocErr(IocMessages.onlyMixinsCanBeProxied(serviceType))

		if (!serviceType.isPublic)
			throw IocErr(IocMessages.proxiedMixinsMustBePublic(serviceType))
		
		model := PlasticClassModel(serviceType.name + "Impl", serviceType.isConst)
		
		model.extendMixin(serviceType)
		model.addField(LazyService#, "afLazyService")

		serviceType.fields.rw
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
		podName		:= plasticPodCompiler.generatePodName
		ctx.track("Compiling Pod '$podName'") |->Obj| {
			pod 	= plasticPodCompiler.compile(code, podName)
		}			
		proxyType 	:= pod.type(model.className)
				
		// TODO: investigate why this throw NotImmutableErr when inlined
		return cacheProxyType(serviceType, proxyType)
	}
	
	Type cacheProxyType(Type serviceType, Type proxyType) {
		withState { it.proxyTypeCache[serviceType] = proxyType } 
		return proxyType 
	}
	
	private Obj? getState(|ServiceProxyBuilderState -> Obj| state) {
		conState.getState(state)
	}	
	private Void withState(|ServiceProxyBuilderState -> Obj| state) {
		conState.withState(state)
	}	
}

internal class ServiceProxyBuilderState {
	Type:Type	proxyTypeCache	:= [:]
}

class TestImmutableTypes {
	
	static Void main(Str[] args) {
		
		proxyPod 	:= compile("class Dude { }", "afPod")
		proxyType	:= proxyPod.type("Dude")	//.toImmutable
		
		|ServiceProxyBuilderState| f := |ServiceProxyBuilderState state| {
//			state.proxyTypeCache[s] = proxyType
			s := proxyType.toStr
			Env.cur.err.printLine(s)
		}.toImmutable
		
		f.call(ServiceProxyBuilderState())
	}
	
	static Pod compile(Str fantomPodCode, Str podName) {
		try {
			input 		    := CompilerInput()
			input.podName 	= podName
	 		input.summary 	= "Alien-Factory Transient Pod"
			input.version 	= Version.defVal
			input.log.level = LogLevel.warn
			input.isScript 	= true
			input.output 	= CompilerOutputMode.transientPod
			input.mode 		= CompilerInputMode.str
			input.srcStrLoc	= Loc(podName)
			input.srcStr 	= fantomPodCode
	
			compiler 		:= Compiler(input)
			pod 			:= compiler.compile.transientPod
			return pod

		} catch (CompilerErr err) {
			msg := err.msg + "\n$fantomPodCode"
			throw CompilerErr(msg, err.loc, err.cause, err.level)
		}
	}	
}
