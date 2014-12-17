using concurrent::AtomicRef

** Lazily finds and calls a *service*
** 
** Should we add this source to the generated proxy pods, and delete it from afIoc?
** For now, no. It'll speed up the compiler, and no-one discovers @NoDoc classes anyway!
** 
** @since 1.3
@NoDoc
const mixin LazyProxy {
	** used to call methods
	abstract Obj? callMethod(Method method, Obj?[] args)
	
	** used to access fields
	abstract Obj getRealService()
}
