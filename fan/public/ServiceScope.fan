
** Scope definitions for Services. 
enum class ServiceScope {
	
	** A new service is created each it is injected. You probably do **not** want this! See [@Inject.autobuild]`Inject.autobuild` instead.
	perInjection,
	
	** Service is created once per thread. This is this default for non-const services.
	perThread,
	
	** Service is a singleton, only one is ever created. This is the default for const services.
	perApplication;
}
