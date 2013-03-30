
**
** Allows a module to bind service facets to service implementation classes. A 'ServiceBinder' is 
** passed to to module methods with the following signature: 
** 
**   static Void bind(ServiceBinder binder) { ... } 
** 
** This is an adaptation of ideas from [Guice]`http://code.google.com/p/google-guice/`.
** 
mixin ServiceBinder {

	** Binds the service mixin to a service impl class. The default service id is the unqualified name of the service mixin. 
	abstract ServiceBindingOptions bind(Type serviceMixin, Type serviceImpl)

	** Defines a concrete implementation of a service. If 'implClass' is a mixin in terms of an impl class, without a service mixin.
	abstract ServiceBindingOptions bindImpl(Type implClass)

}
