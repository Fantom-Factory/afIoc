
**
** Allows a module to bind service interfaces to service implementation classes in support of autobuilding services. A
** ServiceBinder is passed to to a method with the following signature: 'static Void bind(ServiceBinder binder)'. This 
** is an adaptation of ideas from [Guice]`http://code.google.com/p/google-guice/`.
** 
mixin ServiceBinder {

	** Binds the service mixin to a service impl class. The default service name is the unqualified name of the service mixin. 
	abstract ServiceBindingOptions bind(Type serviceMixin, Type serviceImpl)
	
	** Defines a service in terms of an impl class, without a service mixin.
	abstract ServiceBindingOptions bindImpl(Type implementationClass)

	** Alternative implementation that supports a callback to build the service, rather than instantiating a particular type.
	abstract ServiceBindingOptions bindBuilder(Type serviceType, |->Obj| builder)

}
