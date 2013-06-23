
** @since 1.1.0
internal const class DependencyProviderSourceImpl : DependencyProviderSource {
	private const DependencyProvider[] dependencyProviders

	new make(DependencyProvider[] dependencyProviders) {
		this.dependencyProviders = dependencyProviders.toImmutable
	}

	override Bool canProvideDependency(ProviderCtx proCtx, Type dependencyType) {
		dependencyProviders.any { it.canProvide(proCtx, dependencyType) }		
	}
	
	override Obj? provideDependency(ProviderCtx proCtx, Type dependencyType) {
		dps := dependencyProviders.findAll { it.canProvide(proCtx, dependencyType) }

		if (dps.isEmpty)
			return null
		
		if (dps.size > 1)
			throw IocErr(IocMessages.onlyOneDependencyProviderAllowed(dependencyType, dps.map { it.typeof }))
		
		dependency := dps[0].provide(proCtx, dependencyType)
		
		if (dependency == null) {
			if (!dependencyType.isNullable )
				throw IocErr(IocMessages.dependencyDoesNotFit(dependency.typeof, dependencyType))
		} else {
			if (!dependency.typeof.fits(dependencyType))
				throw IocErr(IocMessages.dependencyDoesNotFit(dependency.typeof, dependencyType))
		}

		return dependency
	}
}
