using afBeanUtils::ReflectUtils

@Js @NoDoc	// don't overwhelm the masses
const class DependencyProviders {
	const DependencyProvider[] dependencyProviders

	new makeInternal(Str:DependencyProvider dependencyProviders) {
		// ensure system providers are at the end to cater for catch all scenarios 
		order	:= "afIoc.config afIoc.methodArg afIoc.service afIoc.ctorItBlock".split
		keys	:= dependencyProviders.keys.sort |k1, k2| {
			(order.index(k1) ?: -1) <=> (order.index(k2) ?: -1)
		}
		
		pros := keys.map |id -> DependencyProvider| { dependencyProviders[id] }
		this.dependencyProviders = pros 
	}

	Bool canProvide(Scope currentScope, InjectionCtx ctx) {
		dependencyProviders.any |depPro->Bool| {
			depPro.canProvide(currentScope, ctx)
		}
	}
	
	Obj? provide(Scope currentScope, InjectionCtx ctx, Bool checked := true) {

		depPro := dependencyProviders.find {
			it.canProvide(currentScope, ctx)
		}

		if (depPro == null)
			return checked ? throw IocErr(ErrMsgs.dependencyProviders_dependencyNotFound(ctx, currentScope.inheritance)) : null
		
		dependency := depPro.provide(currentScope, ctx)
		
		type := ctx.field?.type ?: ctx.funcParam?.type
		if (dependency == null && type.isNullable.not)
			throw IocErr(ErrMsgs.dependencyProviders_dependencyDoesNotFit(null, type))
		else if (dependency != null && ReflectUtils.fits(dependency.typeof, type).not)
			throw IocErr(ErrMsgs.dependencyProviders_dependencyDoesNotFit(dependency.typeof, type))
		
		return dependency
	}

	Field:Obj? provideFieldValue(Scope currentScope, InjectionCtx ctx, Field:Obj? plan) {

		depPro := dependencyProviders.find {
			it.canProvide(currentScope, ctx)
		}

		if (depPro == null)
			return plan
		
		dependency := depPro.provide(currentScope, ctx)		

		// If dependency is null, then don't set the field.
		// This lets optional fields define default values - handy for IocConfig values.
		// True, this then means default values cannot be overridden with null, but that's
		// a lesser use case.
		if (dependency == null)
			return plan

		type := ctx.field?.type ?: ctx.funcParam?.type
		if (dependency != null && ReflectUtils.fits(dependency.typeof, type).not)
			throw IocErr(ErrMsgs.dependencyProviders_dependencyDoesNotFit(dependency.typeof, type))
		
		plan[ctx.field] = ctx.field.isConst ? toImmutableObj(ctx.field, dependency) : dependency
		
		return plan
	}

	Obj[]? provideFuncParams(Scope currentScope, InjectionCtx injectionCtx) {
		ctx := (InjectionCtxImpl) injectionCtx
		
		// method funcs define the first arg as the obj instance (if applicable) so remove it from the param list  
		params := ctx.func.params
		if (ctx.isMethodInjection && !ctx.method.isCtor && !ctx.method.isStatic) {
			params = params.rw
			params.removeAt(0)
		}
		
		args := Obj?[,]
		params.find |param, idx| {
			ctx.funcParam 		= param
			ctx.funcParamIndex	= idx
			
			depPro := dependencyProviders.find {
				it.canProvide(currentScope, ctx)
			}
			
			if (depPro == null) {
				// default vals trump optional / nullable values
				if (ctx.funcParam.hasDefault)
					return true

				// treat nullable param types as optional
				if (ctx.funcParam.type.isNullable) {
					args.add(null)
					return false
				}

				throw IocErr(ErrMsgs.dependencyProviders_dependencyNotFound(ctx, currentScope.inheritance))
			}
			
			dependency := depPro.provide(currentScope, ctx)
			
			type := ctx.field?.type ?: ctx.funcParam?.type
			if (dependency == null && type.isNullable.not)
				throw IocErr(ErrMsgs.dependencyProviders_dependencyDoesNotFit(null, type))
			else if (dependency != null && ReflectUtils.fits(dependency.typeof, type).not)
				throw IocErr(ErrMsgs.dependencyProviders_dependencyDoesNotFit(dependency.typeof, type))
			
			args.add(dependency)
			return false
		}
		
		return args
	}
	
	private static Obj? toImmutableObj(Field key, Obj? obj) {
		if (obj is Func && Env.cur.runtime == "js")
			throw Err("Immutable funcs are not available in Javascript: ${key.qname}\nSee http://fantom.org/forum/topic/114 for details.")
		return obj?.toImmutable
	}
}