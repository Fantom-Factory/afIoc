
internal mixin Contribution {

	** The service this contribution, um, contributes to! May return null if the contribution is optional.
	abstract ServiceDef? serviceDef()

	abstract Void contribute(ConfigurationImpl config)
}
