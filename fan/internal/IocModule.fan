using concurrent
using afPlastic

internal const class IocModule {

	static Void bind(ServiceBinder binder) {
		binder.bind(Registry#) 
		binder.bind(RegistryMeta#) 
		binder.bind(RegistryStartup#).withScope(ServiceScope.perThread)	// for non-const listeners 
		binder.bind(RegistryShutdown#)
		
		binder.bind(ActorPools#)
		binder.bind(AspectInvokerSource#)
		binder.bind(DependencyProviders#)
		binder.bind(InjectionUtils#)
		binder.bind(LogProvider#)
		binder.bind(PlasticCompiler#)
		binder.bind(ServiceProxyBuilder#)
		binder.bind(ThreadLocalManager#) 
	}
	
	@Contribute { serviceType=DependencyProviders# }
	static Void contributeDependencyProviders(Configuration config, LogProvider logProvider) {
		config["afIoc.autobuildProvider"]	= config.autobuild(AutobuildProvider#)
		config["afIoc.localProvider"]		= config.autobuild(LocalProvider#)
		config["afIoc.logProvider"]			= logProvider
		config["afIoc.configProvider"]		= config.autobuild(ConfigProvider#)
		config["afIoc.ctorItBlockProvider"]	= config.autobuild(CtorItBlockProvider#)
		config["afIoc.serviceProvider"]		= config.autobuild(ServiceProvider#)
	}	

	@Contribute { serviceType=ActorPools# }
	static Void contributeActorPools(Configuration config) {
		config[IocConstants.systemActorPool] = ActorPool() { it.name = IocConstants.systemActorPool } 
	}

	@Contribute { serviceType=RegistryStartup# }
	static Void contributeRegistryStartup(Configuration config) {
		reg := (RegistryImpl) config.registry

		config["afIoc.logServices"] = |->| {
			reg.logServices.val = true
		}
		config["afIoc.logBanner"] = |->| {
			reg.logBanner.val = true
		}
	}

	@Contribute { serviceType=RegistryShutdown# }
	static Void contributeIocShutdownPlaceholder(Configuration config) {
		reg := (RegistryImpl) config.registry

		config.addPlaceholder("afIoc.shutdown")
		config["afIoc.sayGoodbye"] = |->| {
			reg.sayGoodbye.val = true
		}
	}
}
