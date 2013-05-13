using compiler

@NoDoc
const class Plastic {
	
	// Different podName prevents "sys::Err: Duplicate pod name: <podName>"
	Pod compile(Str fantomCode) {
		// based on http://fantom.org/sidewalk/topic/2127#c13844
		input 		    := CompilerInput()
		input.podName 	= "af"		// TODO
 		input.summary 	= "test"	// TODO
		input.version 	= Version.defVal
		input.log.level = LogLevel.debug
		input.isScript 	= true
		input.output 	= CompilerOutputMode.transientPod
		input.mode 		= CompilerInputMode.str
		input.srcStrLoc	= Loc("Script")	// TODO: qname of service
		input.srcStr 	= fantomCode

		compiler := Compiler.make(input)
		pod := compiler.compile.transientPod
		return pod
	}
}
