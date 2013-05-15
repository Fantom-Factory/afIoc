using concurrent::AtomicInt
using compiler

// TODO: rename to PlasticPodCompiler?? move the podName out to Plastic...?
@NoDoc
const class PlasticPodCompiler {
	
	** static because pods are shared throughout the JVM, not just the IoC 
	private static const AtomicInt podIndex	:= AtomicInt(1)
	
	// based on http://fantom.org/sidewalk/topic/2127#c13844
	Pod compile(Str fantomPodCode) {		
		// different pod names prevents "sys::Err: Duplicate pod name: <podName>"
		// we internalise podName so we can guarantee no dup pod names
		podName			:= "afPlasticProxy" + "$podIndex.getAndIncrement".padl(3, '0')
		input 		    := CompilerInput()
		
		// TODO: log or track the compilation
		
		input.podName 	= podName
 		input.summary 	= "Alien-Factory Transient Pod"
		input.version 	= Version.defVal
		input.log.level = LogLevel.warn
		input.isScript 	= true
		input.output 	= CompilerOutputMode.transientPod
		input.mode 		= CompilerInputMode.str
		input.srcStrLoc	= Loc(podName)
		input.srcStr 	= fantomPodCode

		compiler 		:= Compiler(input)
		pod 			:= compiler.compile.transientPod
		return pod
	}
}

