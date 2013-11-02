
** @Inject - Can't be internal since it's used by auto-generated lazy services.
** 
** @since 1.3.0
@NoDoc
const mixin AspectInvokerSource {
	
	abstract internal ServiceMethodInvokerThread createServiceMethodInvoker(InjectionCtx ctx, ServiceDef serviceDef)
	
}
