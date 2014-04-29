using afPlastic::PlasticCompiler

** A list of public service IDs as defined by IoC
** 
** @since 1.2
@NoDoc // Don't overload the masses
@Deprecated { msg="This will be deleted in a future release with no replacement" }
const mixin ServiceIds {

	internal
	static const Str builtInModuleId			:= "BuiltInModule"

	** @see `Registry`
	static const Str registry					:= Registry#.qname

	** @see `RegistryStartup`
	static const Str registryStartup			:= RegistryStartup#.qname

	** @see `RegistryShutdownHub`
	static const Str registryShutdownHub		:= RegistryShutdownHub#.qname

	** @see `DependencyProviderSource`
	static const Str dependencyProviderSource	:= DependencyProviderSource#.qname

	** @see `ServiceOverride`
	static const Str serviceOverride			:= ServiceOverride#.qname

	** @see `ServiceStats`
	static const Str serviceStats				:= ServiceStats#.qname
	
	internal
	static const Str ctorItBlockBuilder			:= "afIoc::CtorItBlockBuilder"
	
	** @see `afConcurrent::ThreadLocals`
	** 
	** @since 1.3
	static const Str threadLocalManager			:= ThreadLocalManager#.qname
	@NoDoc @Deprecated { msg="Use 'threadLocalManager' instead" }
	static const Str threadStashManager			:= ThreadStashManager#.qname
	
	** @since 1.3
	internal
	static const Str serviceProxyBuilder		:= ServiceProxyBuilder#.qname

	** @since 1.3
	internal
	static const Str plasticCompiler			:= PlasticCompiler#.qname

	** @since 1.3
	internal
	static const Str aspectInvokerSource		:= AspectInvokerSource#.qname

	** @see `RegistryMeta`
	** 
	** @since 1.6.0
	static const Str registryMeta				:= RegistryMeta#.qname
	@NoDoc @Deprecated { msg="Use 'registryMeta' instead" }
	static const Str registryOptions			:= registryMeta

	** @see `LogProvider`
	** 
	** @since 1.5.0
	static const Str logProvider				:= LogProvider#.qname

	** @see `ActorPools`
	** 
	** @since 1.6.0
	static const Str actorPools					:= ActorPools#.qname

}
