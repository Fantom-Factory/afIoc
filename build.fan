using build

class Build : BuildPod {
	
	new make() {
		podName = "afIoc"
		summary = "A powerful Dependency Injection / Inversion Of Control (IOC) framework"
		version = Version("1.6.0")

		meta = [	
			"org.name"		: "Alien-Factory",
			"org.uri"		: "http://www.alienfactory.co.uk/",
			"proj.name"		: "IoC",
			"proj.uri"		: "http://www.fantomfactory.org/pods/afIoc",
			"vcs.uri"		: "https://bitbucket.org/AlienFactory/afioc",
			"license.name"	: "The MIT Licence",
			"repo.private"	: "false"
		]

		depends = [
			"sys 1.0", 
			"concurrent 1.0", 
			"compiler 1.0", 
			
			"afConcurrent 1.0.0+",
			"afPlastic 1.0.2+"
		]
		
		
		srcDirs = [`test/`, `test/utils/`, `fan/`, `fan/ioc/`, `fan/ioc/utils/`, `fan/ioc/services/`, `fan/internal/`, `fan/internal/utils/`, `fan/internal/services/`, `fan/internal/def/`, `fan/facets/`]
		resDirs = [`licence.txt`, `doc/`]
		
		docApi = true
		docSrc = true
	}
	
	@Target { help = "Compile to pod file and associated natives" }
	override Void compile() {
		// see "stripTest" in `/etc/build/config.props` to exclude test src & res dirs
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
