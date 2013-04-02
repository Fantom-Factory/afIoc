
internal mixin Contribution {

	** The service this contribution, um, contributes to! May return null if the contribution is optional.
	abstract ServiceDef? serviceDef()
	
	** Performs the work needed to contribute into the ordered configuration.
	**
	** Config is the ordered configuration into which values should be loaded. 
	abstract Void contributeOrdered(InjectionCtx ctx, OrderedConfig config)

	** Performs the work needed to contribute into the mapped configuration.
	**
	** Config is the mapped configuration into which values should be loaded. 
	abstract Void contributeMapped(InjectionCtx ctx, MappedConfig config)
}
