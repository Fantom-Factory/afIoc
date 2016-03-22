
** Use to create an IoC `Registry`. 
** 
** Add module classes, scopes, services, and contributions.
@Js
class RegistryBuilder {
	private const Log		_logger			:= RegistryBuilder#.pod.log

	private OneShotLock 	_lock			:= OneShotLock(ErrMsgs.registryBuilt)
	private ScpDef[]		_scopeDefs		:= ScpDef[,]
	internal SrvDef[]		_serviceDefs	:= SrvDef[,]
	internal OvrDef[]		_overrideDefs	:= OvrDef[,]
	internal ContribDef[]	_contribDefs	:= ContribDef[,]
	private Obj[]			_modulesAdd		:= Obj[,]
	private Obj[]			_modulesAddAdd	:= Obj[,]
	private Obj[]			_modulesRemove	:= Obj[,]
	private Pod[]			_pods			:= Pod[,]
	private Type[]			_moduleStack	:= Type[,]
	
	private Obj[][]			_registryStartupHooks	:= Obj[][,]
	private Obj[][]			_registryShutdownHooks	:= Obj[][,]
	private Obj[][]			_scopeCreateHooks		:= Obj[][,]
	private Obj[][]			_scopeDestroyHooks		:= Obj[][,]
	private Obj[][]			_serviceBuildHooks		:= Obj[][,]
	private Duration		_buildStart
	
	@NoDoc
	ModuleInspector[]		inspectors

	** Use options to pass state into the IoC Registry. 
	** This map may be later retrieved from the `RegistryMeta` service. 
	Str:Obj?	options := Str:Obj?[:] { it.caseInsensitive = true } {
		private set
	}
	
	** Set to 'true' to suppress builder logging.
	@NoDoc Bool suppressLogging	:= false

	@NoDoc
	new make() {
		_buildStart = Duration.now
		inspectors	= [
			StandardInspector(),
			FacetInspector(),
			LegacyInspector(),
			NonInvasiveInspector()
		]
		addModule(IocModule())
	}

	** Adds a module to the registry. The given 'module' may be:
	**  - a module instance, 
	**  - a module 'Type'
	**  - a qualified module name ( 'Str' )
	**  - a pod name ( 'Str' )
	** 
	** If a pod name then dependencies are also added.
	** 
	** Any modules defined with the '@SubModule' facet are also added.
	** 
	** Don't forget you can always call 'removeModule(...)' too!
	This addModule(Obj module) {
		_lock.check
		
		// check _modulesRemove in case module is added during inspection
		moduleType := ((Type) (module is Type ? module : module.typeof)).toNonNullable
		if (_modulesRemove.contains(moduleType)) {
			_logger.debug(ErrMsgs.regBuilder_ignoringModule(moduleType))
			return this
		}

		if (!moduleType.isConst)
			throw ArgErr(ErrMsgs.regBuilder_modulesShouldBeConst(moduleType))
		
		// Disallow adding the same module type twice - even if different instances 'cos it's too much hassle
		if (_modulesAdd.any { it.typeof == moduleType } || _modulesAddAdd.any { it.typeof == moduleType }) {
			// Debug because sometimes you can't help adding the same module twice (via dependencies)
			// afBedSheet is a prime example
			_logger.debug(ErrMsgs.regBuilder_moduleAlreadyAdded(moduleType))
			return this
		}
		
		if (!suppressLogging && moduleType != IocModule#)
			_logger.info("Adding module ${moduleType.qname}")

		// be nice and check for Strs
		if (module is Str) {
			if (Pod.find(module, false) != null)
				return addModulesFromPod(module, true)
			module = Type.find(module, true)
		}
		
		if (module is Type) 
			module = ((Type) module).make

		_modulesAdd.add(module)
		
		// need to double add 'cos we clear _modulesAdd during inspection 
		_modulesAddAdd.add(module)
		
		return this
	}

	** Adds many modules to the registry. 
	This addModules(Obj[] modules) {
		modules.each { addModule(it) }
		return this
	}

	** Removes modules of the given type. If a module of the given type is subsequently added, it is silently ignored.
	This removeModule(Type moduleType) {
		_lock.check
		if (moduleType.fits(IocModule#))
			throw ArgErr(ErrMsgs.regBuilder_cannotRemoveModule(IocModule#))

		if (!suppressLogging)
			_logger.info("Removing module ${moduleType.qname}")

		// remove all now
		_modulesAdd = _modulesAdd.exclude { it.typeof == moduleType }

		// prevent it from being added later
		_modulesRemove.add(moduleType.toNonNullable)
		return this
	}

	** Inspects the [pod's meta-data]`docLang::Pods#meta` for the key 'afIoc.module'. This is then 
	** treated as a CSV list of (qualified) module type names to load.
	** 
	** If 'addDependencies' is 'true' then the pod's dependencies are also inspected for IoC 
	** modules. 
	This addModulesFromPod(Str podName, Bool addDependencies := true) {
		_lock.check
		pod := Pod.find(podName)
		if (!suppressLogging)
			_logger.info("Adding module definitions from pod '$pod.name'")
		_addModulesFromPod(pod, addDependencies)
		return this
	}

	** Defines a new scope to be used with the registry.
	** 
	** pre>
	** syntax: fantom
	** regBuilder.addScope("thread")
	** <pre
	ScopeBuilder addScope(Str scopeId, Bool threaded := true) {
		_lock.check
		scopeDef := ScpDef {
			it.moduleId	= _currentModule
			it.id 		= scopeId
			it.threaded = threaded
		}
		_scopeDefs.add(scopeDef)
		return ScopeBuilderImpl { it.scopeDef = scopeDef }
	}
	
	@NoDoc @Deprecated { msg="Use 'addService()' instead" }
	ServiceBuilder add(Type? serviceType := null, Type? serviceImplType := null) {
		addService(serviceType, serviceImplType)
	}

	** Defines a new service to be added to the registry.
	** 
	** pre>
	** syntax: fantom
	** regBuilder.addService(Penguin#).withId("penguins").withScope("root")
	** <pre
	** 
	** Note if 'serviceType' is a mixin then, if none given, the builder looks for an 
	** implementation class named the same as the mixin but with an 'Impl' suffix.
	** 
	** Hence:
	** pre>
	** syntax: fantom
	** regBuilder.addService(Penguins#, PenguinsImpl#)
	** <pre
	** 
	** is the same as:
	**  
	** pre>
	** syntax: fantom
	** regBuilder.addService(Penguins#)
	** <pre
	** 
	ServiceBuilder addService(Type? serviceType := null, Type? serviceImplType := null) {
		_lock.check
		bob := ServiceBuilderImpl(_currentModule)
		_serviceDefs.add(bob.srvDef)
		if (serviceType != null)
			bob.withType(serviceType)
		if (serviceImplType != null)
			bob.withImplType(serviceImplType)
		return bob
	}

	** Override values in an existing service definition.
	** 
	** The given id may be a service id to override a service, or an override id to override an override.
	**   
	** pre>
	** syntax: fantom
	** regBuilder.addService(Penguins#).withCtorArgs(["fishLegs"])
	** regBuilder.overrideService(Penguins#.qname).withCtorArgs(["fishHands"])
	** <pre
	** 
	ServiceOverrideBuilder overrideService(Str serviceId) {
		_lock.check
		serviceBuilder := ServiceOverrideBuilderImpl(_currentModule)
		serviceBuilder.ovrDef.serviceId	= serviceId
		serviceBuilder.ovrDef.overrideId	= "${serviceId}.override"
		_overrideDefs.add(serviceBuilder.ovrDef)
		return serviceBuilder
	}

	** Override values in an existing service definition.
	** 
	** pre>
	** syntax: fantom
	** regBuilder.addService(Penguins#).withCtorArgs(["fishLegs"])
	** regBuilder.overrideServiceType(Penguins#).withCtorArgs(["fishHands"])
	** <pre
	** 
	ServiceOverrideBuilder overrideServiceType(Type serviceType) {
		_lock.check
		serviceBuilder := ServiceOverrideBuilderImpl(_currentModule)
		serviceBuilder.ovrDef.serviceType	= serviceType
		serviceBuilder.ovrDef.overrideId	= "${serviceType}.override"
		_overrideDefs.add(serviceBuilder.ovrDef)
		return serviceBuilder
	}

	** Lets you contribute to a service configuration via its ID.
	** 
	** pre>
	** syntax: fantom
	** regBuilder.contributeToService("acme::Penguins") |Configuration config| {
	**     config["food"] = Fish()
	** }
	** <pre
	** 
	** The service ID you're contributing to has to exist. If the service may, or may not exist, 
	** (for example, if you're contributing to an optional 3rd party library) then you may mark 
	** the contribution as *optional*. That way, no Err is thrown should the service not exist.
	** 
	** pre>
	** syntax: fantom
	** regBuilder.contributeToService("acme::Penguins", |Configuration config| {
	**     config["food"] = Fish()
	** }, true)
	** <pre
	** 
	This contributeToService(Str serviceId, |Configuration| configFunc, Bool optional := false) {
		_contribDefs.add(ContribDef {
			it.moduleId			= _currentModule
			it.serviceId		= serviceId
			it.optional			= optional
			it.configFuncRef	= _toImmutableObj(Unsafe(configFunc))
		})
		return this
	}

	** Lets you contribute to a service configuration by its Type.
	** 
	** pre>
	** syntax: fantom
	** regBuilder.contributeToServiceType(Penguins#) |Configuration config| {
	**     config["food"] = Fish()
	** }
	** <pre
	** 
	This contributeToServiceType(Type serviceType, |Configuration| configFunc, Bool optional := false) {
		_contribDefs.add(ContribDef {
			it.moduleId			= _currentModule
			it.serviceType		= serviceType
			it.optional			= optional
			it.configFuncRef	= _toImmutableObj(Unsafe(configFunc))
		})
		return this
	}
	
	** Hook for executing funcs when the Registry starts up.
	** 
	** pre>
	** syntax: fantom
	** regBuilder.onRegistryStartup |Configuration config| {
	**     config["log.hello1"] = |Scope rootScope| {
	**         penguin := rootScope.serviceById("acme::Penguin")
	**         Log.get("afIoc").info("Hello ${penguin.name}!")
	**     }
	** }
	** <pre
	** 
	** Note that the *root scope* is always passed into startup funcs.
	** 
	** An alternative to this method is to use an 'AppModule' method named 'onRegistryStartup()', 
	** the advantage of which is that the arguments are dependency resolved.
	** 
	** pre>
	** syntax: fantom
	** Void onRegistryStartup(Configuration config, Penguin penguin) {
	**     config.set("log.hello2", |Scope rootScope| {
	**         Log.get("afIoc").info("Hello ${penguin.name}!")
	**     }).after("log.hello1")
	** }
	** <pre
	** 
	** Or, if you don't care about ordering, you may omit the call to 'Configuration':
	** 
	** pre>
	** syntax: fantom
	** Void onRegistryStartup(Penguin penguin) {
	**     Log.get("afIoc").info("Hello ${penguin.name}!")
	** }
	** <pre
	This onRegistryStartup(|Configuration| startupHook) {
		_registryStartupHooks.add([_currentModule, startupHook])
		return this
	}

	** Hook for executing funcs when the Registry shuts down.
	** 
	** pre>
	** syntax: fantom
	** regBuilder.onRegistryShutdown |Configuration config| {
	**     config["log.bye1"] = |Scope rootScope| {
	**         penguin := rootScope.serviceById("acme::Penguin")
	**         Log.get("afIoc").info("Goodbye ${penguin.name}!")
	**     }
	** }
	** <pre
	** 
	** Note that the *root scope* is always passed into shutdown funcs.
	** 
	** An alternative to this method is to use an 'AppModule' method named 'onRegistryShutdown()', 
	** the advantage of which is that the arguments are dependency resolved.
	** 
	** pre>
	** syntax: fantom
	** Void onRegistryShutdown(Configuration config, Penguin penguin) {
	**     config.set("log.bye2", |Scope rootScope| {
	**         Log.get("afIoc").info("Goodbye ${penguin.name}!")
	**     }).after("log.bye1")
	** }
	** <pre
	** 
	** Or, if you don't care about ordering, you may omit the call to 'Configuration':
	** 
	** pre>
	** syntax: fantom
	** Void onRegistryShutdown(Penguin penguin) {
	**     Log.get("afIoc").info("Goodbye ${penguin.name}!")
	** }
	** <pre
	This onRegistryShutdown(|Configuration| shutdownHook) {
		_registryShutdownHooks.add([_currentModule, _toImmutableObj(shutdownHook)])
		return this
	}

	** Hook for executing funcs when a scope is created.
	** 
	** pre>
	** syntax: fantom
	** regBuilder.onScopeCreate("ro*") |Configuration config| {
	**     config["log.hello"] = |Scope scope| {
	**         Log.get("afIoc").info("BEGIN ${scope.id}")
	**     }
	** }
	** <pre
	** 
	** Where 'scopeGlob' is a not a scope ID, but a regex glob that is used to match 
	** against scope IDs and their aliases.
	This onScopeCreate(Str scopeGlob, |Configuration| createHook) {
		_scopeCreateHooks.add([_currentModule, Regex.glob(scopeGlob), _toImmutableObj(createHook)])
		return this
	}

	** Hook for executing funcs when a scope is created.
	** 
	** pre>
	** syntax: fantom
	** regBuilder.onScopeDestroy("ro*") |Configuration config| {
	**     config["log.bye"] = |Scope scope| {
	**         Log.get("afIoc").info("END ${scope.id}")
	**     }
	** }
	** <pre
	** 
	** Where 'scopeGlob' is a not a scope ID, but a regex glob that is used to match 
	** against scope IDs and their aliases.
	This onScopeDestroy(Str scopeGlob, |Configuration| destroyHook) {
		_scopeDestroyHooks.add([_currentModule, Regex.glob(scopeGlob), _toImmutableObj(destroyHook)])
		return this
	}

	** Hook for executing funcs when a service is created.
	** 
	** pre>
	** syntax: fantom
	** regBuilder.onServiceBuild("*penguin*") |Configuration config| {
	**     config["log.hello"] = |Scope scope, ServiceDef def, Obj? instance| {
	**         Log.get("afIoc").info("HELLO WORLD from ${def.id}")
	**     }
	** }
	** <pre
	** 
	** Where 'scopeGlob' is a not a service ID, but a regex glob that is used to match 
	** against service IDs and their aliases.
	** 
	** Note there is also a hook available for when class is autobuilt - 
	** see the src for 'AutoBuilder' for details.
	This onServiceBuild(Str serviceGlob, |Configuration| buildHook) {
		_serviceBuildHooks.add([_currentModule, Regex.glob(serviceGlob), _toImmutableObj(buildHook)])
		return this
	}
	
	** Sets a value in the 'options' map. 
	** Returns 'this' so it may be used as a builder method. 		
	This setOption(Str name, Obj? value) {
		options.set(name, value)
		return this
	}

	** Builds and returns the registry; this may only be done once.  
    Registry build() {

		defaults := Str:Obj?[:] { it.caseInsensitive = true }.addAll([
			"afIoc.bannerText" : "Alien-Factory IoC v$typeof.pod.version",
		])

		defaults.each |val, key| {
			optType := options[key]?.typeof
			if (optType != null && optType != val.typeof)
				throw IocErr(ErrMsgs.regBuilder_invalidRegistryValue(key, optType, val.typeof))
		}

		// set defaults but allow modules to alter / add to options
		options = defaults.setAll(options)
		registry := _buildHard
		
		_lock.lock
		return registry
    }
	
	// ---- Private Methods -----------------------------------------------------------------------

	private Void _addModulesFromPod(Pod pod, Bool addDependencies := true) {
		if (_pods.contains(pod)) {
			_logger.debug(ErrMsgs.regBuilder_podAlreadyAdded(pod))
			return
		}
		
		moduleTypeNames := (Str?) null
		try		moduleTypeNames = pod.meta.get("afIoc.module")
		catch	_logger.warn("WARNING: Pod ${pod.name} does not define any meta - ensure it's not built with F4 - see https://github.com/xored/f4/issues/49")
		
		if (moduleTypeNames != null)
			_addModulesFromTypeNames(moduleTypeNames)

		if (addDependencies) {
			pod.depends.each |depend| {
				dependency := Pod.find(depend.name)
				_addModulesFromPod(dependency, addDependencies)
			}
		}
	}
	
	private Void _addModulesFromTypeNames(Str? moduleTypeNames) {
		if (moduleTypeNames == null)
			return
		
		moduleTypeNames.split(',', true).each |moduleTypeName| {
			moduleType := Type.find(moduleTypeName)
			addModule(moduleType)
		}		
	}
	
	private Registry _buildHard() {

		// inspect modules, and keep inspecting until no more are added
		moduleTypes := Type[,]
		while (_modulesAdd.size > 0) {
			modules := _modulesAdd.dup
			
			// clear _modulesAdd so module inspectors can add to it
			_modulesAdd.clear
			
			modules.each |module| {
				moduleTypes.add(module.typeof)
				_moduleStack.push(module.typeof)
				try inspectors.each { it.inspect(this, module) }
				finally _moduleStack.pop
			}
		}
		
		// despite best efforts, an inspected module may remove / ignore a module that's already been inspected
		_scopeDefs				= _scopeDefs			.exclude { _modulesRemove.contains(it.moduleId) }
		_serviceDefs			= _serviceDefs			.exclude { _modulesRemove.contains(it.moduleId) }
		_overrideDefs			= _overrideDefs			.exclude { _modulesRemove.contains(it.moduleId) }
		_contribDefs			= _contribDefs			.exclude { _modulesRemove.contains(it.moduleId) }
		_registryStartupHooks	= _registryStartupHooks	.exclude { _modulesRemove.contains(it[0]) }
		_registryShutdownHooks	= _registryShutdownHooks.exclude { _modulesRemove.contains(it[0]) }
		_scopeCreateHooks		= _scopeCreateHooks		.exclude { _modulesRemove.contains(it[0]) }
		_scopeDestroyHooks		= _scopeDestroyHooks	.exclude { _modulesRemove.contains(it[0]) }
		_serviceBuildHooks		= _serviceBuildHooks	.exclude { _modulesRemove.contains(it[0]) }

		// we could use Map.addList(), but do it the long way round so we get a nice error on dups
		services := Str:SrvDef[:] { caseInsensitive = true }
		_serviceDefs.each {
			if (services.containsKey(it.id))
				throw IocErr(ErrMsgs.regBuilder_serviceAlreadyDefined(it.id, it.moduleId, services[it.id].moduleId))
			services[it.id] = it
		}

		// we could use Map.addList(), but do it the long way round so we get a nice error on dups
		overrides	:= Str:OvrDef[:] { caseInsensitive = true}
		_overrideDefs.each |ovr| {
			if (ovr.serviceId == null) 
				ovr.serviceId = services.find { it.matchesType(ovr.serviceType) }?.id ?: ErrMsgs.scope_couldNotFindServiceByType(ovr.serviceType, null)
			if (overrides.containsKey(ovr.serviceId))
				throw IocErr(ErrMsgs.regBuilder_onlyOneOverrideAllowed(ovr.serviceId, ovr.moduleId, overrides[ovr.serviceId].moduleId))
			overrides[ovr.serviceId] = ovr
		}

		keys := Str:Str[:] { it.caseInsensitive = true }
		services.keys.each { keys[it] = it }

		// normalise keys -> map all keys to orig key and apply overrides
		// code nabbed from Configuration
		found := true
		while (overrides.size > 0 && found) {
			found = false
			overrides = overrides.exclude |over, existingId| {
				overrideId := over.overrideId
				if (keys.containsKey(existingId)) {
					if (keys.containsKey(overrideId))
						throw IocErr(ErrMsgs.regBuilder_overrideAlreadyDefined(over.overrideId, over.moduleId, services[keys[existingId]].moduleId))

					keys[overrideId] = keys[existingId]
					found = true
					
					srvDef := services[keys[existingId]]						
					srvDef.applyOverride(over)

					return true
				} else {
					return false
				}
			}
		}

		overrides = overrides.exclude { it.optional }

		if (!overrides.isEmpty) {
			keysNotFound := overrides.keys.join(", ")
			throw ServiceNotFoundErr(ErrMsgs.regBuilder_serviceIdNotFound(keysNotFound), services.keys)
		}

		_contribDefs.each |contribDef| {
			// should only really ever be the one match!
			matches := _serviceDefs.findAll |srvDef| { 
				contribDef.matches(srvDef)
			}
			matches.each {
				it.addContribDef(contribDef)
			}

			if (!contribDef.optional && matches.isEmpty)
				throw ServiceNotFoundErr(ErrMsgs.contributionServiceNotFound(contribDef.srvId, contribDef.method2), _serviceDefs)
		}

		// we could use Map.addList(), but do it the long way round so we get a nice error on dups
		scopeDefs := Str:ScpDef[:] { caseInsensitive = true }
		_scopeDefs.each |def| {
			if (scopeDefs.containsKey(def.id))
				throw IocErr(ErrMsgs.regBuilder_scopeAlreadyDefined(def.id, def.moduleId, scopeDefs[def.id].moduleId))
			scopeDefs[def.id] = def
		}		
		
		scopeDefs.each |ScpDef scpDef| {
			scpDef.createContribs  = _scopeCreateHooks .findAll { scpDef.matchesGlob(it[1]) }.map { it[2] }
			scpDef.destroyContribs = _scopeDestroyHooks.findAll { scpDef.matchesGlob(it[1]) }.map { it[2] }
		}

		services.each |srvDef| {
			srvDef.buildContribs  = _serviceBuildHooks .findAll { srvDef.matchesGlob(it[1]) }.map { it[2] }
		}
		
		return RegistryImpl(_buildStart, scopeDefs, services, moduleTypes, options, _registryStartupHooks.map { it[1] }, _registryShutdownHooks.map { it[1] })
	}
	
	private Obj? _toImmutableObj(Obj? obj) {
		if (obj is Func)
			return Env.cur.runtime == "js" ? obj : obj.toImmutable
		return obj?.toImmutable
	}
	
	private Type _currentModule() {
		_moduleStack.peek ?: RegistryBuilder#
	}
}
