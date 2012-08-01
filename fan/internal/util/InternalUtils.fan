
internal const class InternalUtils {
	
	// TODO: Stoopid F4 thinks the facets method is a reserved word!
	static Facet findFacet(Obj slot, Type annotation) {
		(slot->facets as Facet[]).find |fac| { 
			fac.typeof == annotation 
		} ?: throw ArgErr("Slot '$slot->qname' does not contain facet '$annotation.qname")
	}
	
	** Searches a class for the "best" constructor, the public constructor with the most parameters. Returns null if
	** there are no public constructors. If there is more than one constructor with the maximum number of parameters, it
	** is not determined which will be returned (don't build a class like that!). In addition, if a constructor is
	** annotated with `Inject`, it will be used (no check for multiple such constructors is made, only at most a 
	** single constructor should have the annotation).
	static Method? findAutobuildConstructor(Type type) {
		constructors := findConstructors(type)
		
		if (constructors.isEmpty)
			return null
		
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
	
	static Method[] findConstructors(Type type) { 
		type.methods.findAll |method| { method.isCtor && method.parent == type }
	}
	
	** Extracts the message from an exception. If the exception's message is null, returns the exceptions class name.
	@Deprecated
	static Str toMessage(Err exception) {
		exception.msg
	}	
}
