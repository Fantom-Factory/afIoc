
** An optional facet to use in conjunction with [@Inject]`Inject` to specify a service to inject. 
** Use when a service mixin has multiple implementations.
** 
** pre>
** @Inject @ServiceId { serviceId = "impl2" }
** MyService myService
** <pre
facet class ServiceId {
	const Str serviceId
}
