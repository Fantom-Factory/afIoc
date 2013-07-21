
** Builds and caches Proxy Types. The Types are cached because:
**  - as they're already loaded by the VM, we may as well!
**  - we have to, to prevent memory leaks!
** 
** Think of afBedSheet when a new Request / Response proxy is built on every request!
** 
** @since 1.3.0
@NoDoc
const mixin ServiceProxyBuilder {

	internal abstract Obj buildProxy(InjectionCtx ctx, ServiceDef serviceDef)

	** Returns a cached Type if exists, otherwise compiles a new proxy type 
	internal abstract Type buildProxyType(InjectionCtx ctx, Type serviceType)

}
