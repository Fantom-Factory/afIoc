using build

class Build : BuildPod {
	
	new make() {
		podName = "afIoc"
		summary = "A powerful 'Inversion Of Control' (IOC) framework"
		version = Version("1.4.11")

		meta	= [	"org.name"		: "Alien-Factory",
					"org.uri"		: "http://www.alienfactory.co.uk/",
					"vcs.uri"		: "https://bitbucket.org/AlienFactory/afioc",
					"proj.name"		: "Ioc",
					"license.name"	: "BSD 2-Clause License",
					"repo.private"	: "true"
				]

		depends = ["sys 1.0", "concurrent 1.0", "compiler 1.0", "afPlastic 1.0.2+"]
		srcDirs = [`test/`, `test/utils/`, `fan/`, `fan/ioc/`, `fan/ioc/utils/`, `fan/ioc/services/`, `fan/internal/`, `fan/internal/utils/`, `fan/internal/services/`, `fan/internal/def/`, `fan/facets/`]
		resDirs = [`doc/`]
		
		docApi = true
		docSrc = true

		// exclude test code when building the pod
		srcDirs = srcDirs.exclude { it.toStr.startsWith("test/") }
	}
	
	@Target { help = "Compile to pod file and associated natives" }
	override Void compile() {
		super.compile
		
		destDir := Env.cur.homeDir.plus(`src/${podName}/`)
		destDir.delete
		destDir.create		
		`fan/`.toFile.copyInto(destDir)
		
		log.indent
		log.info("Copied `fan/` to ${destDir.normalize}")
		log.unindent
	}
}
