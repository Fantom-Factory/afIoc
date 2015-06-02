
** Returned from 'AppModule' `Configuration` methods to add ordering constraints to your contributions.
** 
** Constraints are keys of other contributions that this contribution must appear before or after. 
** 
** pre>
**   syntax: fantom
**   config["Breakfast"] = eggs
**   config["Dinner"]    = pie
**   ...
**   config.set("Lunch", ham).after("breakfast").before("dinner")
** <pre
** 
** Constraints become very powerful when used across multiple modules and pods.
abstract class Constraints {
	
	** Specify a key your contribution should appear *before*.
	** 
	** This may be called multiple times to add multiple constraints.
	abstract This before(Obj key)

	** Specify a key your contribution should appear *after*.
	** 
	** This may be called multiple times to add multiple constraints.
	abstract This after(Obj key)
}

internal class Contrib : Constraints {
	Obj key; Obj? val
	Bool unordered

	Obj[]? befores;	Obj[]? afters

	new make(Obj key, Obj? val) {
		this.key = key
		this.val = val
	}
	
	override This before(Obj key) {
		if (befores == null)
			befores = [,]
		befores.add(key)
		return this
	}

	override This after(Obj key) {
		if (afters == null)
			afters = [,]
		afters.add(key)
		return this
	}
	
	Void findImplied(Obj:Contrib contribs) {
		if (!unordered)
			return
		i := contribs.keys.index(key)
		implied := contribs.vals[0..<i].reverse.find { it.unordered }
		if (implied == null)
			return		
		if (afters == null)
			afters = [,]
		afters.add(implied.key)
	}
	
	Void finalise() {
		unordered = (befores == null && afters == null)
	}
	
	override Str toStr() {
		"[$key:$val]"
	}	
}
