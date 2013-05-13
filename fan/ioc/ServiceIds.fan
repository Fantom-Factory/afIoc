
** A list of public service IDs as defined by IoC
** 
** @since 1.2
mixin ServiceIds {

	** @see `Registry`
	static const Str registry					:= "Registry"
	
	** @see `RegistryStartup`
	static const Str registryStartup			:= "RegistryStartup"
	
	** @see `RegistryShutdownHub`
	static const Str registryShutdownHub		:= "RegistryShutdownHub"

	** @see `DependencyProviderSource`
	static const Str dependencyProviderSource	:= "DependencyProviderSource"
	
	** @see `ServiceOverride`
	static const Str serviceOverride			:= "ServiceOverride"

	** @see `ServiceStats`
	static const Str serviceStats				:= "ServiceStats"
	
	** @since 1.3
	static const Str serviceProxyBuilder		:= "ServiceProxyBuilder"

	** @since 1.3
	static const Str plastic					:= "Plastic"
	
	internal
	static const Str ctorFieldInjector			:= "CtorFieldInjector"
	
}
