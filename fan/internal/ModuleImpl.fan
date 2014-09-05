using concurrent::AtomicInt
using concurrent::AtomicRef
using afConcurrent::LocalMap

internal const class ModuleImpl : Module {

	override const Str					moduleId	
	override const ServiceDef[]			serviceDefs
	private  const OneShotLock 			regShutdown		:= OneShotLock("Registry has shutdown")
	private  const Contribution[]		contributions
	private  const AdviceDef[]			adviceDefs
	private  const ObjLocator			objLocator

	new make(ObjLocator objLocator, ThreadLocalManager localManager, ModuleDef moduleDef, [Type:Obj]? readyMade) {
		localMap 	:= localManager.createMap(moduleName(moduleDef.moduleId))
		serviceDefs	:= ServiceDef[,]
		moduleDef.serviceDefs.each |def| {
			impl := readyMade?.get(def.type)
			sDef := def.toServiceDef(objLocator, localManager, impl)
			serviceDefs.add(sDef)
		}
		
		this.moduleId		= moduleDef.moduleId
		this.objLocator 	= objLocator
		this.adviceDefs		= moduleDef.adviceDefs
		this.contributions	= moduleDef.contribDefs.map |contrib| { 
			ContributionImpl {
				it.serviceId 	= contrib.serviceId
				it.serviceType 	= contrib.serviceType
				it.method		= contrib.method
				it.objLocator 	= objLocator
			}
		}
		
		this.serviceDefs = serviceDefs
	}

	// ---- Module Methods ----------------------------------------------------

	override Contribution[] contributionsByServiceDef(ServiceDef serviceDef) {
		regShutdown.check
		return contributions.findAll {
			// service def maybe null if contribution is optional
			it.serviceDef?.serviceId == serviceDef.serviceId
		}
	}
	
	override AdviceDef[] adviceByServiceDef(ServiceDef serviceDef) {
		regShutdown.check
		return adviceDefs.findAll {
			it.matchesService(serviceDef)
		}
	}
	
	override Void shutdown() {
		regShutdown.lock
		serviceDefs.each { it.shutdown }
	}
		
	// ---- Private Methods ----------------------------------------------------
	
	private Str moduleName(Str modId) {
		modId.contains("::") ? modId[(modId.index("::")+2)..-1] : modId 
	}	
}

