
internal const class InternalUtils {
	private const static Log 	log 		:= Utils.getLog(InternalUtils#)
	
	// TODO: Stoopid F4 thinks the 'facet' method is a reserved word!
	static Bool hasFacet(Slot slot, Type annotation) {
		slot.facets.find |fac| { 
			fac.typeof == annotation
		} != null		
	}
	
	static Obj autobuild(OpTracker tracker, ObjLocator objLocator, Type type) {
		tracker.track("Autobuilding $type.qname") |->Obj| {
			log.info("Autobuilding $type.qname")
			ctor := findAutobuildConstructor(tracker, type)
			obj  := createViaConstructor(tracker, objLocator, ctor)
			injectIntoFields(tracker, objLocator, obj)
			return obj
		}
	}
	
	** Injects into the fields (of all visibilities) when the @Inject facet is present.
	static Obj injectIntoFields(OpTracker tracker, ObjLocator objLocator, Obj object) {
		tracker.track("Injecting dependencies into fields of $object.typeof.qname") |->Obj| {
			object.typeof.fields.each |field| { 
				// Ignore all static and final fields.
		    	if (field.isStatic || field.isConst)
		    		return
	
		    	if (field.hasFacet(Inject#)) {
					dependency := findDependencyByType(tracker, objLocator, field.type)
	                inject(tracker, object, field, dependency)
	            }
			}
			
			callPostInjectMethods(tracker, objLocator, object)
			return object
		}
    }

	** Calls methods (of all visibilities) that have the @PostInjection facet
	static Obj callPostInjectMethods(OpTracker tracker, ObjLocator objLocator, Obj object) {
		tracker.track("Calling post injection methods of $object.typeof.qname") |->Obj| {
			object.typeof.methods
				.findAll |method| {
					hasFacet(method, PostInjection#) 
				}
				.each |method| {
					callMethod(tracker, objLocator, method, object)
				}
			return object
		}
	}
	
	// ---- Private Methods -----------------------------------------------------------------------

	private static Method findAutobuildConstructor(OpTracker tracker, Type type) {
		tracker.track("Locating suitable ctor for autobiuld $type.qname") |->Method| {
			constructors := findConstructors(type)
			
			if (constructors.isEmpty)
				throw IocErr(IocMessages.noConstructor(type))
			
			if (constructors.size == 1)
				return constructors[0]
	
			Method? annotated := constructors.find |c| {
				c.hasFacet(Inject#)
			}		
			if (annotated != null)
				return annotated
			
			// Choose a constructor with the most parameters.
			return constructors.sort |c1, c2| {
				c1.params.size <=> c2.params.size
			} [0]
		}
	}
	
	private static Obj createViaConstructor(OpTracker tracker, ObjLocator objLocator, Method ctor) {
		tracker.track("Instantiating $ctor.parent via $ctor.signature") |->Obj| {
			args := determineInjectionParams(tracker, objLocator, ctor)
			return ctor.callList(args)
		}
	}

	private static Obj callMethod(OpTracker tracker, ObjLocator objLocator, Method method, Obj obj) {
		tracker.track("Invoking $method.signature on $obj.typeof") |->Obj| {
			args := determineInjectionParams(tracker, objLocator, method)
			return method.callOn(obj, args)
		}
	}
	
	private static Obj[] determineInjectionParams(OpTracker tracker, ObjLocator objLocator, Method method) {
		tracker.track("Determining injection parameters for $method.signature") |->Obj[]| {
			return method.params.map |param| {
				findDependencyByType(tracker, objLocator, param.type)
			}			
		}
	}

	private static Obj findDependencyByType(OpTracker tracker, ObjLocator objLocator, Type dependencyType) {
		// FUTURE: this could take an facetProvider to give more hints on dependency finding
		tracker.track("Locating dependency for type $dependencyType") |->Obj| {
			return objLocator.trackDependencyByType(tracker, dependencyType)			
		}
	}
	
	private static Void inject(OpTracker tracker, Obj target, Field field, Obj value) {
		tracker.track("Injecting $value.typeof.qname into field $field.signature") |->| {
			field.set(target, value)
		}
	}

	private static Method[] findConstructors(Type type) { 
		type.methods.findAll |method| { method.isCtor && method.parent == type }
	}
	
}
