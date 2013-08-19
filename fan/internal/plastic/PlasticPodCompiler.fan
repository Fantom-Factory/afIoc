using concurrent::AtomicInt
using compiler

** @since 1.3
@NoDoc
const class PlasticPodCompiler {

	** static because pods are shared throughout the JVM, not just the IoC 
	private static const AtomicInt podIndex	:= AtomicInt(1)

	internal Pod track(OpTracker tracker, Str fantomPodCode) {
		podName := generatePodName
		return tracker.track("Compiling Pod '$podName'") |->Obj| {
			compile(fantomPodCode, podName)
		}
	}

	// based on http://fantom.org/sidewalk/topic/2127#c13844
	Pod compile(Str fantomPodCode, Str? podName := null) {

		podName = podName ?: generatePodName
		
		try {
			input 		    := CompilerInput()
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

		} catch (CompilerErr err) {
			srcErrLoc := SrcErrLocation(`${podName}`, fantomPodCode, err.line, err.msg)
			throw PlasticCompilationErr(srcErrLoc, 5)
		}
	}
	
	** Different pod names prevents "sys::Err: Duplicate pod name: <podName>".
	** We internalise podName so we can guarantee no dup pod names
	Str generatePodName() {
		"afPlasticPod" + "$podIndex.getAndIncrement".padl(3, '0')
	}
}

