
** @since 1.3.10 
const class PipelineBuilderImpl : PipelineBuilder {
	
	private const TypeCache typeCache	:= TypeCache()

	@Inject	
	private const PlasticPodCompiler plasticPodCompiler

	private const Method[]	objMethods	:= Obj#.methods
	
	new make(|This|in) { in(this) }
	
	override Obj build(Type pipelineType, Type filterType, Obj[] filters, Obj terminator) {

		if (!terminator.typeof.fits(pipelineType))
			throw IocErr(IocMessages.pipelineTerminatorMustExtendPipeline(pipelineType, terminator.typeof))
		filters.each |filter| { 
			if (!filter.typeof.fits(filterType))
				throw IocErr(IocMessages.pipelineFilterMustExtendFilter(filterType, filter.typeof))
		}		
		
		bridgeType	:= buildBridgeType(pipelineType, filterType)
		
		nextField 	:= bridgeType.field("next")
		handField 	:= bridgeType.field("handler")

		pipeline := filters.reverse.reduce(terminator) |toWrap, filter| {
			makePlan	:= Field:Obj?[nextField:filter, handField:toWrap]
			ctorFunc	:= Field.makeSetFunc(makePlan)
			bridge		:= bridgeType.make([ctorFunc])
			return bridge
		}

		return pipeline
	}
	
	private Type buildBridgeType(Type pipelineType, Type filterType) {
		if (typeCache.containsKey(key(pipelineType, filterType)))
			return typeCache[key(pipelineType, filterType)]
		
		pipelineMethods := pipelineType.methods.rw
			.removeAll(objMethods)
			.findAll { it.isAbstract || it.isVirtual }
		
		// have the public checks last so we can test all other scenarios with internal test types
		if (!pipelineType.isMixin)
			throw IocErr(IocMessages.pipelineTypeMustBeMixin("Pipeline", pipelineType))
		if (!filterType.isMixin)
			throw IocErr(IocMessages.pipelineTypeMustBeMixin("Pipeline Filter", filterType))
		if (!pipelineType.fields.isEmpty)
			throw IocErr(IocMessages.pipelineTypeMustNotDeclareFields(pipelineType))
		pipelineMethods.each |method| {
			fMeth := ReflectUtils.findMethod(filterType, method.name, method.params.map { it.type }.add(pipelineType), false, method.returns)
			if (fMeth == null) {
				sig := method.signature[0..-2] + ", ${pipelineType.qname} handler)"
				throw IocErr(IocMessages.pipelineFilterMustDeclareMethod(filterType, sig))
			}
		}
		if (!pipelineType.isPublic)
			throw IocErr(IocMessages.pipelineTypeMustBePublic("Pipeline", pipelineType))
		if (!filterType.isPublic)
			throw IocErr(IocMessages.pipelineTypeMustBePublic("Pipeline Filter", filterType))
		
		model := PlasticClassModel("${pipelineType.name}Bridge", pipelineType.isConst)
		model.extendMixin(pipelineType)
		model.addField(filterType, "next")
		model.addField(pipelineType, "handler")

		pipelineMethods.each |method| {
			args := method.params.map { it.name }.add("handler").join(", ")
			body := "next.${method.name}(${args})"
			model.overrideMethod(method, body)
		}

		code 		:= model.toFantomCode
		podName		:= plasticPodCompiler.generatePodName
		pod 		:= plasticPodCompiler.compile(code, podName)
		bridgeType 	:= pod.type(model.className)
		
		typeCache[key(pipelineType, filterType)] = bridgeType
		
		return bridgeType
	}
	
	private Str key(Type pipelineType, Type filterType) {
		"${pipelineType.qname}-${filterType.qname}"
	}
}

// Example generated Bridge class
//const class HttpHandlerBridge : HttpHandler {
//	private const HttpFilter next
//	private const HttpHandler handler
//	
//	new make(HttpFilter next, HttpHandler handler) {
//		this.next = next
//		this.handler = handler
//	}
//	
//	override Bool service(HttpRequest? request, HttpResponse? response) {
//		return next.service(request, response, handler)
//	}
//}
