using concurrent::AtomicInt
using compiler

** @since 1.3
@NoDoc
const class PlasticPodCompiler {
	
	** static because pods are shared throughout the JVM, not just the IoC 
	private static const AtomicInt podIndex	:= AtomicInt(1)
	
	// based on http://fantom.org/sidewalk/topic/2127#c13844
	internal Pod compile(OpTracker tracker, Str fantomPodCode) {

		// different pod names prevents "sys::Err: Duplicate pod name: <podName>"
		// we internalise podName so we can guarantee no dup pod names
		podName			:= "afPlasticProxy" + "$podIndex.getAndIncrement".padl(3, '0')
		input 		    := CompilerInput()
		
		return tracker.track("Compiling Pod '$podName'") |->Obj| {
			try {
				
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
				msg := err.msg + "\n$fantomPodCode"
				throw CompilerErr(msg, err.loc, err.cause, err.level)
			}
		}
	}
}

