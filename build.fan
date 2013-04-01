using build::BuildPod

class Build : BuildPod {
	
	new make() {
		podName = "afIoc"
		summary = "A Dependency Injection (DI) framework"
		version = Version([1,0,0])

		meta	= [	"org.name"		: "Alien-Factory",
					"org.uri"		: "http://www.alienfactory.co.uk/",
					"proj.name"		: "AF-IOC",
					"license.name"	: "BSD 2-Clause License",
					"repo.private"	: "true"
				]

		depends = ["sys 1.0", "concurrent 1.0"]
		srcDirs = [`test/`, `test/utils/`, `fan/`, `fan/ioc/`, `fan/ioc/utils/`, `fan/ioc/services/`, `fan/internal/`, `fan/internal/utils/`, `fan/internal/services/`, `fan/internal/def/`, `fan/facets/`]
		resDirs = [`doc/`]
		
		docApi = true
		docSrc = true
	}
}
