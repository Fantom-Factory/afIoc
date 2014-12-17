using afConcurrent

internal const class LocalProvider : DependencyProvider {

			private const ThreadLocalManager	localManager
	static	private const Type[]				localTypes		:= [LocalRef#, LocalList#, LocalMap#]	

	new make(ThreadLocalManager	localManager) {
		this.localManager = localManager 
	}

	override Bool canProvide(InjectionCtx ctx) {
		// IoC standards dictate that field injection should be denoted by a facet
		ctx.injectionKind.isFieldInjection
			? localTypes.contains(ctx.dependencyType.toNonNullable) && ctx.injectingIntoType != null && ctx.field.hasFacet(Inject#)
			: localTypes.contains(ctx.dependencyType.toNonNullable) && ctx.injectingIntoType != null
	}
	
	override Obj? provide(InjectionCtx ctx) {
		ctx.log("Creating ${ctx.dependencyType.name} dependency for ${ctx.injectingIntoType.qname}")
		type := ctx.dependencyType.toNonNullable
		name := ctx.injectingIntoType.qname.replace("::", ".")
		if (ctx.field != null)
			name += "." + ctx.field.name
		if (ctx.methodParam != null)
			name += "." + ctx.methodParam.name
		
		// let @Inject.id override the default name
		inject	:= (Inject?) ctx.fieldFacets.findType(Inject#).first
		if (inject?.id != null)
			name = inject.id 
		
		if (type == LocalRef#)
			return localManager.createRef(name)

		if (type == LocalList#) {
			listType := inject?.type
			if (listType == null)
				return localManager.createList(name)

			if (listType.params["L"] == null)
				throw IocErr(IocMessages.localProvider_typeNotList(ctx.field, listType))
			return LocalList(localManager.createName(name)) {
				it.valType = listType.params["V"]
			} 
		}

		if (type == LocalMap#) {
			mapType := inject?.type
			if (mapType == null)
				return localManager.createMap(name)

			if (mapType.params["M"] == null)
				throw IocErr(IocMessages.localProvider_typeNotMap(ctx.field, mapType))

			return LocalMap(localManager.createName(name)) {
				it.keyType = mapType.params["K"]
				it.valType = mapType.params["V"]
				if (it.keyType == Str#)
					it.caseInsensitive = true
				else
					it.ordered = true
			} 
		}

		throw WtfErr("What's a {$type.qname}???")
	}
}
