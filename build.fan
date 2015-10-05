using build

class Build : BuildPod {
	
	new make() {
		podName = "afIoc"
		summary = "A fast, lightweight, and highly customisable Dependency Injection framework"
		version = Version("3.0.0")

		meta = [	
			"proj.name"		: "IoC 3",
			"repo.tags"		: "system",
			"repo.public"	: "false"
		]

		depends = [
			"sys          1.0.67 - 1.0",	// FIXME: actually 1.0.68 for Js 
			"concurrent   1.0.67 - 1.0", 	// used for Actor.locals, Actor.sleep, AtomicInt, AtomicBool
			"afBeanUtils  1.0.6  - 1.0",	// used for ReflectUtils, NotFoundErr, TypeCoercer
			
			// ---- Test ----
			"afConcurrent 1.0.10 - 1.0"
		]

		srcDirs = [`test/`, `fan/`, `fan/public/`, `fan/public/services/`, `fan/public/facets/`, `fan/public/advanced/`, `fan/internal/`, `fan/internal/providers/`, `fan/internal/inspectors/`, `fan/internal/def/`]
		resDirs = [`doc/`]
	}
	
	@Target
	override Void compile() {
		// remove test pods from final build
		testPods := "afConcurrent".split
		depends = depends.exclude { testPods.contains(it.split.first) }
		super.compile
	}
}
