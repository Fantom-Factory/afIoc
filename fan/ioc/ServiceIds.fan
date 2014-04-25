
** A list of public service IDs as defined by IoC
** 
** @since 1.2
const mixin ServiceIds {

	internal
	static const Str builtInModuleId			:= "BuiltInModule"

	** @see `Registry`
	static const Str registry					:= "afIoc::Registry"

	** @see `RegistryStartup`
	static const Str registryStartup			:= "afIoc::RegistryStartup"

	** @see `RegistryShutdownHub`
	static const Str registryShutdownHub		:= "afIoc::RegistryShutdownHub"

	** @see `DependencyProviderSource`
	static const Str dependencyProviderSource	:= "afIoc::DependencyProviderSource"

	** @see `ServiceOverride`
	static const Str serviceOverride			:= "afIoc::ServiceOverride"

	** @see `ServiceStats`
	static const Str serviceStats				:= "afIoc::ServiceStats"
	
	internal
	static const Str ctorItBlockBuilder			:= "afIoc::CtorItBlockBuilder"
	
	** @see `ThreadStashManager`
	** 
	** @since 1.3
	static const Str threadStashManager			:= "afIoc::ThreadStashManager"
	
	** @since 1.3
	internal
	static const Str serviceProxyBuilder		:= "afIoc::ServiceProxyBuilder"

	** @since 1.3
	internal
	static const Str plasticCompiler			:= "afIoc::PlasticCompiler"

	** @since 1.3
	internal
	static const Str aspectInvokerSource		:= "afIoc::AspectInvokerSource"

	** @see `RegistryMeta`
	** 
	** @since 1.5.6
	static const Str registryMeta				:= "afIoc::RegistryMeta"
	@NoDoc @Deprecated { msg="Use 'registryMeta' instead" }
	static const Str registryOptions			:= registryMeta

	** @see `LogProvider`
	** 
	** @since 1.5.0
	static const Str logProvider				:= "afIoc::LogProvider"

	** @see `ActorPools`
	** 
	** @since 1.5.6
	static const Str actorPools					:= "afIoc::ActorPools"

}
