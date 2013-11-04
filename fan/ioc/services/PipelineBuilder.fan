
** (Service) -
** In this pattern, also know as a *filter chain*, a service endpoint (known as the terminator) is
** at the end of a pipeline of filters. 
** 
** Each method invocation on the returned service is routed through the filters before the 
** terminator is called. Each filter has an opportunity to modify method arguments and the return 
** value or shortcut the call completely.
** 
** @since 1.3.10 
const mixin PipelineBuilder {
	
	abstract Obj build(Type pipelineType, Type filterType, Obj[] filters, Obj terminator)
}




