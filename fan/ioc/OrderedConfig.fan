
** Obj passed into a module's contributor method to allow the method to, err, contribute!
**
** A service can**collect* contributions in three different ways:
** - As an ordered list of values (where each value has a unique id)
** - As a map of keys and values
** 
** The service defines the *type* of contribution, in terms of a base class or service interface. 
** Contributions must be compatible with the type.
class OrderedConfig {
	
	** Adds an ordered object to a service's contribution. Each object has an id (which must be unique).
	**
	** If no constraints are supplied, then an implicit constraint is supplied: after the previously
	** contributed id**within the same contribution method*.
	Void add(Str id, Obj object, Str[] constraints := [,]) {
		
	}

	** Overrides a normally contributed object. The original override must exist.
	Void addOverride(Str id, Obj object, Str[] constraints := [,]) {
		
	}

	** Adds an ordered object by instantiating (with dependencies) the indicated class. 
	Void addType(Str id, Type type, Str[] constraints := [,]) {
		
	}

	** Instantiates an object and adds it as an override. 
	Void addTypeOverride(Str id, Type type, Str[] constraints := [,]) {
	
	}
}
