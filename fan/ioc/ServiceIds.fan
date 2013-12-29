
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
	
	** @see `ThreadStashManager`
	** 
	** @since 1.3
	static const Str threadStashManager			:= "ThreadStashManager"
	
	** @since 1.3
	internal
	static const Str serviceProxyBuilder		:= "ServiceProxyBuilder"

	** @since 1.3
	internal
	static const Str plasticCompiler			:= "PlasticCompiler"

	** @since 1.3
	internal
	static const Str aspectInvokerSource		:= "AspectInvokerSource"

	** @see `RegistryOptions`
	** 
	** @since 1.4.8
	static const Str registryOptions			:= "RegistryOptions"

	** @see `LogProvider`
	** 
	** @since 1.5.0
	static const Str logProvider				:= "LogProvider"

}
