
internal class Utils {
	
	static Log getLog(Type type) {
//		Log.get(type.pod.name + "." + type.name)
		type.pod.log
	}

	** Stoopid F4 thinks the 'facet' method is a reserved word!
	static Bool hasFacet(Slot slot, Type annotation) {
		slot.facets.find |fac| { 
			fac.typeof == annotation
		} != null		
	}
	
}
