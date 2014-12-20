
** Proxy strategies for Services.
** 
** @since 2.0.0
enum class ServiceProxy {
	
	** Always create a proxy for the service.
	always,
	
	** Never create a proxy for the service.
	never,
	
	** Only create a proxy when absolutely necessary:
	**  - when the service is being advised
	**  - when thread scoped and being injected into an app scoped service 
	ifRequired
}
