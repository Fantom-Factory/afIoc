using build::BuildPod

class Build : BuildPod {
	
	new make() {
		podName = "afIoc"
		summary = "An IOC based on T5-IOC"
		version = Version([1,0,0])
		
		meta	= [	"org.name"		: "Alien-Factory",
					"org.uri"		: "http://www.alienfactory.co.uk/",
					"proj.name"		: "AF-IOC",
					"license.name"	: "BSD 2-Clause License",
					"repo.private"	: "true"
				]
		
		srcDirs = [`test/`, `fan/`, `fan/ioc/`, `fan/ioc/services/`, `fan/internal/`, `fan/internal/util/`, `fan/internal/services/`, `fan/internal/def/`, `fan/facets/`]
		depends = ["sys 1.0", "concurrent 1.0"]
		
		docApi = true
		docSrc = true
	}
}
