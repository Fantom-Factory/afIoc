
** An optional facet to use in conjunction with [@Inject]`Inject` to specify a service to inject. 
** Use when a service mixin has multiple implementations.
** 
** pre>
** @Inject @ServiceId { serviceId = "impl2" }
** MyService myService
** <pre
** 
** May not be used with '@Autobuild' or other [Dependency Providers]`DependencyProvider`.
facet class ServiceId {
	const Str serviceId
}
