using build

class Build : BuildPod {
	
	new make() {
		podName = "afIoc"
		summary = "A powerful Dependency Injection / Inversion Of Control (IoC) framework"
		version = Version("1.6.1")

		meta = [	
			"proj.name"		: "IoC",
			"tags"			: "system",
			"repo.private"	: "true"
		]

		depends = [
			"sys 1.0", 
			"concurrent 1.0", 
			"compiler 1.0", 
			
			"afConcurrent 1.0.2+",
			"afPlastic 1.0.2+"
		]
		
		
		srcDirs = [`test/`, `test/utils/`, `fan/`, `fan/ioc/`, `fan/ioc/utils/`, `fan/ioc/services/`, `fan/internal/`, `fan/internal/utils/`, `fan/internal/services/`, `fan/internal/def/`, `fan/facets/`]
		resDirs = [`doc/about.fdoc`]
		
		docApi = true
		docSrc = true
	}
}
