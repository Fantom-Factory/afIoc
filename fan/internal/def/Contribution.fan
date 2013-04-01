
internal mixin Contribution {

	** The service this contribution, um, contributes to!
	abstract ServiceDef serviceDef()
	
	** Performs the work needed to contribute into the ordered configuration.
	**
	** Config is the ordered configuration into which values should be loaded. 
	abstract Void contributeOrdered(InjectionCtx ctx, OrderedConfig config)

	** Performs the work needed to contribute into the mapped configuration.
	**
	** Config is the mapped configuration into which values should be loaded. 
	abstract Void contributeMapped(Obj moduleInst, MappedConfig config)
}
