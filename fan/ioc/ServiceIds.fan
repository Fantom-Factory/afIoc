
** A list of public service IDs as defined by IoC
** 
** @since 1.2
const mixin ServiceIds {

	internal
	static const Str builtInModuleId			:= "BuiltInModule"

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
	
	internal
	static const Str ctorFieldInjector			:= "CtorFieldInjector"
	
	** @since 1.3
	internal
	static const Str serviceProxyBuilder		:= "ServiceProxyBuilder"

	** @since 1.3
	internal
	static const Str plasticPodCompiler			:= "PlasticPodCompiler"

	** @since 1.3
	internal
	static const Str adviceSource				:= "AdviceSource"

}
