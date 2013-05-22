using build::BuildPod

class Build : BuildPod {
	
	new make() {
		podName = "afIoc"
		summary = "A powerful 'Inversion Of Control' (IOC) framework"
		version = Version([1,2,3])

		meta	= [	"org.name"		: "Alien-Factory",
					"org.uri"		: "http://www.alienfactory.co.uk/",
					"vcs.uri"		: "https://bitbucket.org/SlimerDude/afioc",
					"proj.name"		: "AF-IOC",
					"license.name"	: "BSD 2-Clause License",
					"repo.private"	: "true"
				]

		depends = ["sys 1.0", "concurrent 1.0", "compiler 1.0"]
		srcDirs = [`test/`, `test/utils/`, `test/plastic/`, `fan/`, `fan/ioc/`, `fan/ioc/utils/`, `fan/ioc/services/`, `fan/internal/`, `fan/internal/utils/`, `fan/internal/services/`, `fan/internal/plastic/`, `fan/internal/def/`, `fan/facets/`]
		resDirs = [`doc/`]
		
		docApi = true
		docSrc = true
	}
}
