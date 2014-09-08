
** Scope definitions for Services. 
enum class ServiceScope {
	
	** Service is created once per thread. This is this default for non-const services.
	perThread,
	
	** Service is a singleton, only one is ever created. This is the default for const services.
	perApplication;
}
