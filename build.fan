using build

class Build : BuildPod {
	
	new make() {
		podName = "afIoc"
		summary = "A powerful Dependency Injection (DI) / Inversion Of Control (IoC) framework"
		version = Version("1.7.2")

		meta = [	
			"proj.name"		: "IoC",
			"tags"			: "system",
			"repo.private"	: "false"
		]

		depends = [
			"sys 1.0", 
			"concurrent 1.0", 
			"compiler 1.0", 
			
			"afBeanUtils 1.0.2+",
			"afConcurrent 1.0.6+",
			"afPlastic 1.0.16+"
		]
		
		srcDirs = [`test/`, `fan/`, `fan/ioc/`, `fan/ioc/services/`, `fan/internal/`, `fan/internal/utils/`, `fan/internal/services/`, `fan/internal/def/`, `fan/facets/`]
		resDirs = [`doc/about.fdoc`]
	}
}
