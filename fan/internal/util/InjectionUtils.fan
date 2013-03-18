
internal const class InjectionUtils {
	private const static Log 	log 		:= Utils.getLog(InjectionUtils#)
	
	static Obj autobuild(OpTracker tracker, ObjLocator objLocator, Type type) {
		tracker.track("Autobuilding $type.qname") |->Obj| {
			ctor := findAutobuildConstructor(tracker, type)
			obj  := createViaConstructor(tracker, objLocator, ctor)
			injectIntoFields(tracker, objLocator, obj)
			return obj
		}
	}
	
	** Injects into the fields (of all visibilities) where the @Inject facet is present.
	static Obj injectIntoFields(OpTracker tracker, ObjLocator objLocator, Obj object) {
		tracker.track("Injecting dependencies into fields of $object.typeof.qname") |->| {
			if (!findFieldsWithFacet(tracker, object.typeof, Inject#)
				.reduce(false) |bool, field| {
					dependency := findDependencyByType(tracker, objLocator, field.type)
	                inject(tracker, object, field, dependency)
	                return true
	            })
				tracker.log("No injection fields found")
		}
		tracker.track("Autobuilding dependencies of fields into $object.typeof.qname") |->| {
			if (!findFieldsWithFacet(tracker, object.typeof, Autobuild#)
				.reduce(false) |bool, field| {
					dependency := autobuild(tracker, objLocator, field.type)
	                inject(tracker, object, field, dependency)
	                return true
	            })
				tracker.log("No autobuild fields found")
		}
		callPostInjectMethods(tracker, objLocator, object)
		return object
    }

	** Calls methods (of all visibilities) that have the @PostInjection facet
	static Obj callPostInjectMethods(OpTracker tracker, ObjLocator objLocator, Obj object) {
		tracker.track("Calling post injection methods of $object.typeof.qname") |->Obj| {
			if (!object.typeof.methods
				.findAll |method| {
					Utils.hasFacet(method, PostInjection#) 
				}
				.reduce(false) |bool, method| {
					tracker.log("Found method $method.signature")
					callMethod(tracker, objLocator, method, object)
					return true
				})
				tracker.log("No post injection methods found")
			return object
		}
	}
	
	// ---- Private Methods -----------------------------------------------------------------------

	private static Method findAutobuildConstructor(OpTracker tracker, Type type) {
		tracker.track("Looking for suitable ctor to autobiuld $type.qname") |->Method| {
			ctor := |->Method| {
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
			}()
			
			tracker.log("Found $ctor.signature")
			return ctor
		}
	}
	
	private static Obj createViaConstructor(OpTracker tracker, ObjLocator objLocator, Method ctor) {
		args := determineInjectionParams(tracker, objLocator, ctor)
		return tracker.track("Instantiating $ctor.parent via ${ctor.signature}...") |->Obj| {
			return ctor.callList(args)
		}
	}

	private static Void callMethod(OpTracker tracker, ObjLocator objLocator, Method method, Obj obj) {
		args := determineInjectionParams(tracker, objLocator, method)
		tracker.track("Invoking $method.signature on ${obj.typeof}...") |->| {
			method.callOn(obj, args)
		}
	}
	
	private static Obj[] determineInjectionParams(OpTracker tracker, ObjLocator objLocator, Method method) {
		return tracker.track("Determining injection parameters for $method.signature") |->Obj[]| {
			params := method.params.map |param| {
				tracker.log("Found parameter $param.type")
				return findDependencyByType(tracker, objLocator, param.type)
			}		
			if (params.isEmpty)
				tracker.log("No injection parameters found")
			return params
		}
	}

	private static Obj findDependencyByType(OpTracker tracker, ObjLocator objLocator, Type dependencyType) {
		// FUTURE: this could take an facetProvider to give more hints on dependency finding
		// e.g. @Autobuild
		return tracker.track("Looking for dependency of type $dependencyType") |->Obj| {
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
	
	private static Field[] findFieldsWithFacet(OpTracker tracker, Type type, Type facetType) {
		type.fields.findAll |field| {
			// Ignore all static and final fields.
	    	if (field.isStatic || field.isConst)
	    		return false

	    	if (!field.hasFacet(facetType)) 
	    		return false
			
    		tracker.log("Found field $field.signature")
			return true
		}
	}
}
