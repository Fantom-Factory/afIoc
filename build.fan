using build

class Build : BuildPod {
	
	new make() {
		podName = "afIoc"
		summary = "A powerful Dependency Injection (DI) / Inversion Of Control (IoC) framework"
		version = Version("1.6.3")

		meta = [	
			"proj.name"		: "IoC",
			"tags"			: "system",
			"repo.private"	: "true"
		]

		depends = [
			"sys 1.0", 
			"concurrent 1.0", 
			"compiler 1.0", 
			
			"afBeanUtils 0.0.4+",
			"afConcurrent 1.0.6+",
			"afPlastic 1.0.12+"
		]
		
		
		srcDirs = [`test/`, `fan/`, `fan/ioc/`, `fan/ioc/utils/`, `fan/ioc/services/`, `fan/internal/`, `fan/internal/utils/`, `fan/internal/services/`, `fan/internal/def/`, `fan/facets/`]
		resDirs = [`doc/about.fdoc`]
		
		docApi = true
		docSrc = true
	}
}
