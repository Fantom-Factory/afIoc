
@Js
internal const class IocModule {
	
	Void defineModule(RegistryBuilder bob) {
		
		bob.addScope("builtIn", false)
		bob.addScope("root", false)
		
		// need to define services upfront so we (and others) can contribute to it
		bob.addService { it.withType(DependencyProviders#)	.withScopes(["builtIn"]) }
		bob.addService { it.withType(AutoBuilder#)			.withScopes(["builtIn"]).addAlias("afIoc::AutoBuilderHooks.onBuild") }
		bob.addService { it.withType(Registry#)				.withScopes(["builtIn"]) }
		bob.addService { it.withType(RegistryMeta#)			.withScopes(["builtIn"]) }

		bob.contributeToService(DependencyProviders#.qname) |Configuration config| {
			config.inOrder {
				config["afIoc.autobuild"]	= AutobuildProvider()
				config["afIoc.func"]		= FuncProvider()
				config["afIoc.log"]			= LogProvider()
				config["afIoc.scope"]		= ScopeProvider()

				config["afIoc.config"]		= ConfigProvider()
				config["afIoc.funcArg"]		= FuncArgProvider()
				config["afIoc.service"]		= ServiceProvider()
				config["afIoc.ctorItBlock"]	= CtorItBlockProvider()
			}
		}
		
		bob.onRegistryStartup |config| {
			log :=IocModule#.pod.log

			config.inOrder {				
				config["afIoc.logServices"] = |Scope scope| {
					if (log.isInfo)
						log.info(scope.registry.printServices)
				}
				config["afIoc.logBanner"] = |Scope scope| {
					if (log.isInfo)
						log.info(scope.registry.printBanner)
				}
				config["afIoc.logStartupTimes"] = |Scope scope| { /* placeholder */ }
			}
		}

		bob.onRegistryShutdown |config| {
			config["afIoc.sayGoodbye"] = |Scope scope| { /* placeholder */ }
		}
	}
}
