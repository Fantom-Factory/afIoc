
internal const class InjectionUtils {
	private const static Log 	log 		:= Utils.getLog(InjectionUtils#)
	
	static Obj autobuild(InjectionCtx ctx, Type type) {
		ctx.track("Autobuilding $type.qname") |->Obj| {
			ctor := findAutobuildConstructor(ctx, type)
			obj  := createViaConstructor(ctx, ctor)
			injectIntoFields(ctx, obj, false)
			return obj
		}
	}

	** Injects into the fields (of all visibilities) where the @Inject facet is present.
	static Obj injectIntoFields(InjectionCtx ctx, Obj object, Bool insideCtor) {
		
		ctx.track("Injecting dependencies into fields of $object.typeof.qname") |->| {
			if (!findFieldsWithFacet(ctx, object.typeof, Inject#, true)
				.reduce(false) |bool, field| {
					
					// TODO: Cannot reflectively set const fields, even in the ctor
					// see http://fantom.org/sidewalk/topic/2119
//					if (!insideCtor) {
						if (field.isConst)
							throw IocErr(IocMessages.cannotSetConstFields(field))
//					}
					
					dependency := findDependencyByType(ctx, field.type)
	                inject(ctx, object, field, dependency)
	                return true
	            })
				ctx.log("No injection fields found")
		}
		
//		tracker.track("Autobuilding dependencies of fields into $object.typeof.qname") |->| {
//			if (!findFieldsWithFacet(tracker, object.typeof, Autobuild#, injectConstFields)
//				.reduce(false) |bool, field| {
//					dependency := autobuild(tracker, objLocator, field.type)
//	                inject(tracker, object, field, dependency)
//	                return true
//	            })
//				tracker.log("No autobuild fields found")
//		}
		
		callPostInjectMethods(ctx, object)
		return object
    }
	
	static Obj callMethod(InjectionCtx ctx, Method method, Obj? obj) {
		args := determineInjectionParams(ctx, method)
		return ctx.track("Invoking $method.signature on ${method.parent}...") |->Obj?| {
			return (obj == null) ? method.callList(args) : method.callOn(obj, args)
		}
	}

	static Method findAutobuildConstructor(InjectionCtx ctx, Type type) {
		ctx.track("Looking for suitable ctor to autobiuld $type.qname") |->Method| {
			ctor := |->Method| {
				constructors := findConstructors(type)

				if (constructors.isEmpty)
					throw IocErr(IocMessages.noConstructor(type))

				if (constructors.size == 1)
					return constructors[0]

				annotated := constructors.findAll |c| {
					c.hasFacet(Inject#)
				}
				if (annotated.size == 1)
					return annotated[0]
				if (annotated.size > 1)
					throw IocErr(IocMessages.onlyOneCtorWithInjectFacetAllowed(type, annotated.size))				
				
				// Choose a constructor with the most parameters.
				params := constructors.sortr |c1, c2| {
					c1.params.size <=> c2.params.size
				}
				if (params[0].params.size == params[1].params.size)
					throw IocErr(IocMessages.ctorsWithSameNoOfParams(type, params[1].params.size))				
				
				return params[0]
			}()
			
			ctx.log("Found $ctor.signature")
			return ctor
		}
	}

	static Obj createViaConstructor(InjectionCtx ctx, Method ctor) {
		args := determineInjectionParams(ctx, ctor)
		return ctx.track("Instantiating $ctor.parent via ${ctor.signature}...") |->Obj| {
			return ctor.callList(args)
		}
	}
	
	// ---- Private Methods -----------------------------------------------------------------------

	** Calls methods (of all visibilities) that have the @PostInjection facet
	private static Obj callPostInjectMethods(InjectionCtx ctx, Obj object) {
		ctx.track("Calling post injection methods of $object.typeof.qname") |->Obj| {
			if (!object.typeof.methods
				.findAll |method| {
					method.hasFacet(PostInjection#)
				}
				.reduce(false) |bool, method| {
					ctx.log("Found method $method.signature")
					callMethod(ctx, method, object)
					return true
				})
				ctx.log("No post injection methods found")
			return object
		}
	}	

	private static Obj[] determineInjectionParams(InjectionCtx ctx, Method method) {
		return ctx.track("Determining injection parameters for $method.signature") |->Obj[]| {
			params := method.params.map |param| {
				ctx.log("Found parameter $param.type")
				return findDependencyByType(ctx, param.type)
			}		
			if (params.isEmpty)
				ctx.log("No injection parameters found")
			return params
		}
	}

	private static Obj findDependencyByType(InjectionCtx ctx, Type dependencyType) {
		// FUTURE: this could take an FacetProvider to give more hints on dependency finding
		// e.g. @Autobuild, @ServiceId
		ctx.track("Looking for dependency of type $dependencyType") |->Obj| {
			ctx.objLocator.trackDependencyByType(ctx, dependencyType)			
		}
	}
	
	private static Void inject(InjectionCtx ctx, Obj target, Field field, Obj value) {
		ctx.track("Injecting $value.typeof.qname into field $field.signature") |->| {
			if (field.get(target) != null) {
				ctx.log("Field has non null value. Aborting injection.")
				return
			}
			field.set(target, value)
		}
	}

	private static Method[] findConstructors(Type type) { 
		type.methods.findAll |method| { method.isCtor && method.parent == type }
	}

	private static Field[] findFieldsWithFacet(InjectionCtx ctx, Type type, Type facetType, Bool includeConst) {
		type.fields.findAll |field| {
			// Ignore all static and final fields.
	    	if (field.isStatic)
	    		return false
			
			if (field.isConst && !includeConst)
				return false

	    	if (!field.hasFacet(facetType)) 
	    		return false
			
    		ctx.log("Found field $field.signature")
			return true
		}
	}
}
