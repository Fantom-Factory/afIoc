
internal const class InternalUtils {
	private const static Log 	log 		:= Log.get(InternalUtils#.name)
	
	// TODO: Stoopid F4 thinks the 'facet' method is a reserved word!
	static Bool hasFacet(Slot slot, Type annotation) {
		slot.facets.find |fac| { 
			fac.typeof == annotation
		} != null		
	}
	
	static Obj autobuild(ObjLocator objLocator, Type type) {
		log.info("Building $type.qname")
		ctor := findAutobuildConstructor(type)
		obj  := createViaConstructor(objLocator, ctor)
		injectIntoFields(objLocator, obj)
		callPostInjectMethods(objLocator, obj)
		return obj
	}
	
	** Injects into the fields (of all visibilities) when the @Inject facet is present.
	static Obj injectIntoFields(ObjLocator objLocator, Obj object) {
		object.typeof.fields.each |field| { 

			// Ignore all static and final fields.
	    	if (field.isStatic || field.isConst)
	    		return

	    	if (field.hasFacet(Inject#)) {
				// TODO: getObj() or find service by Id - use an annotationProvider...?
				service := objLocator.serviceByType(field.type)
                inject(object, field, service)
            }
		}
		
		return object
    }

	** Calls methods (of all visibilities) that have the @PostInjection facet
	static Obj callPostInjectMethods(ObjLocator objLocator, Obj object) {
		object.typeof.methods
			.findAll |method| {
				hasFacet(method, PostInjection#) 
			}
			.each |method| {
				callMethod(objLocator, method, object)
			}
		return object
	}
	
	// ---- Private Methods -----------------------------------------------------------------------

	** Searches a class for the "best" constructor, the public constructor with the most 
	** parameters. Returns null if there are no public constructors. If there is more than one 
	** constructor with the maximum number of parameters, it is not determined which will be 
	** returned (don't build a class like that!). In addition, if a constructor is annotated with 
	** `Inject`, it will be used (no check for multiple such constructors is made, only at most a 
	** single constructor should have the annotation).
	private static Method findAutobuildConstructor(Type type) {
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
	
	private static Obj createViaConstructor(ObjLocator objLocator, Method ctor) {
		args := ctor.params.map |param| {
			objLocator.serviceByType(param.type)
		}
		return ctor.callList(args)
	}

	private static Obj callMethod(ObjLocator objLocator, Method method, Obj obj) {
		args := method.params.map |param| {
			objLocator.serviceByType(param.type)
		}
		return method.callOn(obj, args)
	}

	private static Method[] findConstructors(Type type) { 
		type.methods.findAll |method| { method.isCtor && method.parent == type }
	}
	
	private static Void inject(Obj target, Field field, Obj value) {
		field.set(target, value)
	}
}
