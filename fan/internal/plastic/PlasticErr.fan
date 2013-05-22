
internal const class PlasticErr : Err {
	new make(Str msg, Err? cause := null) : super(msg, cause) {}
}
