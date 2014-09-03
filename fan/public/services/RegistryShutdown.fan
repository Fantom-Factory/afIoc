using concurrent::Future
using afConcurrent::SynchronizedState

** (Service) - Contribute functions to be executed on `Registry` shutdown. 
** All functions need to be immutable, which essentially means they can only reference 'const' classes.
** Example usage:
** 
** pre>
** class AppModule {
**     @Contribute { serviceType=RegistryShutdown# }
**     static Void contributeRegistryShutdown(Configuration conf, MyService myService) {
**         conf["myShutdownFunc"] = |->| { myService.shutdown() }
**     }
** }
** <pre
** 
** If the shutdown method of your service depends on other services being available, add a constraint on 'afIoc.shutdown': 
** 
**   conf.set("myShutdownFunc", |->| { myService.shutdown() }).before("afIoc.shutdown")
** 
** Note that Errs thrown by shutdown functions will be logged and then swallowed.
** 
** @uses Configuration of '|->| []'
const mixin RegistryShutdown {
	internal abstract Void shutdown()
}

internal const class RegistryShutdownImpl : RegistryShutdown {
	private const static Log 		log 		:= Utils.getLog(RegistryShutdown#)
	private const OneShotLock 		lock		:= OneShotLock(IocMessages.registryShutdown)
	private const Str:|->|	 		shutdownFuncs
 
	// Map needs to be keyed on Str so IoC can auto-generate keys in add()
	new make(Str:|->| shutdownFuncs) {
		shutdownFuncs.each |val, key| { 
			try val.toImmutable
			catch throw NotImmutableErr(IocMessages.shutdownFuncNotImmutable(key))
		}
		this.shutdownFuncs = shutdownFuncs
	}
	
	override Void shutdown() {
		lock.check
		lock.lock

		shutdownFuncs.each | |->| listener, Str id| {
			try {
				listener.call
			} catch (Err e) {
				log.err(IocMessages.shutdownListenerError(id, e))
			}
		}
	}
}

