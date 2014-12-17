using build

class Build : BuildPod {
	
	new make() {
		podName = "afIoc"
		summary = "A powerful Dependency Injection / Inversion Of Control framework"
		version = Version("2.0.3")

		meta = [	
			"proj.name"		: "IoC",
			"tags"			: "system",
			"repo.private"	: "true"
		]

		depends = [
			"sys 1.0", 
			"concurrent 1.0", 
			"compiler 1.0", 
			
			"afBeanUtils  1.0.2  - 1.0",
			"afConcurrent 1.0.8  - 1.0",
			"afPlastic    1.0.16 - 1.0"
		]
		
		srcDirs = [`test/`, `fan/`, `fan/public/`, `fan/public/services/`, `fan/public/facets/`, `fan/internal/`, `fan/internal/utils/`, `fan/internal/services/`, `fan/internal/providers/`, `fan/internal/def/`]
		resDirs = [`doc/about.fdoc`]
	}
}
