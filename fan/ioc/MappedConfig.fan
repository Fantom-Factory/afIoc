
** Obj passed into a module's contributor method to allow the method to, err, contribute!
**
** A service can**collect* contributions in three different ways:
** - As an ordered list of values (where each value has a unique id)
** - As a map of keys and values
** 
** The service defines the *type* of contribution, in terms of a base class or service interface. 
** Contributions must be compatible with the type.
class MappedConfig {
	
	internal new make(Type param) {
		
	}

	** Adds a keyed object to the service's contribution.
	Void add(Obj key, Obj value) {
		
	}

	** Overrides an existing contribution by its key.
	Void addOverride(Obj key, Obj value) {
		
	}

	** Adds a keyed object by instantiating (with dependencies) the indicated class. 
	Void addType(Obj key, Type valueType) {
		
	}

	** Instantiates an object and adds it as an override. 
	Void addTypeOverride(Obj key, Type valueType) {
	
	}	
}
