
** @since 1.3.0
@NoDoc	// TODO: revise name
const mixin AdviceSource {
	
	abstract internal MethodAdvisor[] getMethodAdvisors(InjectionCtx ctx, ServiceDef serviceDef)
	
}
