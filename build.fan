using build

class Build : BuildPod {

	new make() {
		podName = "afIoc"
		summary = "A fast, lightweight, and highly customisable Dependency Injection framework"
		version = Version("3.0.8")

		meta = [
			"pod.dis"		: "IoC",
			"repo.tags"		: "system",
			"repo.public"	: "true"
		]

		depends = [
			"sys          1.0.68 - 1.0",
			"concurrent   1.0.68 - 1.0", 	// used for Actor.locals, Actor.sleep, AtomicInt, AtomicBool
			"afBeanUtils  1.0.8  - 1.0",	// used for ReflectUtils, NotFoundErr, TypeCoercer

			// ---- Test ----
			"afConcurrent 1.0.20 - 1.0"
		]

		srcDirs = [`fan/`, `fan/internal/`, `fan/internal/def/`, `fan/internal/inspectors/`, `fan/internal/providers/`, `fan/public/`, `fan/public/advanced/`, `fan/public/facets/`, `fan/public/services/`, `test/`]
		resDirs = [`doc/`]

		meta["afBuild.testPods"]	= "afConcurrent"
		//meta["afBuild.testDirs"]	= ""
	}
}
