
** Use to add ordering constraints to service configurations.
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
@Js
mixin Constraints {
	
	** Specify a key your contribution should appear *before*.
	** 
	** This may be called multiple times to add multiple constraints.
	abstract This before(Obj key, Bool optional := false)

	** Specify a key your contribution should appear *after*.
	** 
	** This may be called multiple times to add multiple constraints.
	abstract This after(Obj key, Bool optional := false)
}

@Js
internal class Contrib : Constraints {
	Obj key; Obj? val
	Bool unordered

	ContribCont[]? befores;	ContribCont[]? afters

	new make(Obj key, Obj? val) {
		this.key = key
		this.val = val
	}
	
	override This before(Obj key, Bool optional := false) {
		if (befores == null)
			befores = ContribCont[,]
		befores.add(ContribCont(key, optional))
		return this
	}

	override This after(Obj key, Bool optional := false) {
		if (afters == null)
			afters = ContribCont[,]
		afters.add(ContribCont(key, optional))
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
			afters = ContribCont[,]
		afters.add(ContribCont(implied.key, false))
	}
	
	Void finalise() {
		unordered = (befores == null && afters == null)
	}
	
	override Str toStr() {
		"[$key:$val].before($befores).after($afters)"
	}	
}

@Js
internal class GroupConstraints : Constraints {
	Contrib[] contribs

	new make(Contrib[] contribs) {
		this.contribs = contribs
	}
	
	override This before(Obj key, Bool optional := false) {
		contribs.each { it.before(key, optional) }
		return this
	}

	override This after(Obj key, Bool optional := false) {
		contribs.each { it.after(key, optional) }
		return this
	}	
}

@Js
internal class ContribCont {
	Obj	 key
	Bool optional
	
	new make(Obj key, Bool optional) {
		this.key = key
		this.optional = optional
	}

	override Str toStr() { key.toStr }
}