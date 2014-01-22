
** Use in your 'AppModule.bind(ServiceBinder binder) { ... }' method. It's how you tell IoC about your services. If your
** service implementation is fronted by a mixin, then pass them both in: 
** 
** pre>
** class AppModule {
**   static Void bind(ServiceBinder binder) {
**     binder.bind(MyServiceImpl#)
**   } 
** }
** <pre
**
** If your service is just an impl class then you can use the shorter form:
** 
** pre>
** class AppModule {
**   static Void bind(ServiceBinder binder) {
**     binder.bind(MyServiceImpl#)
**   } 
** }
** <pre
** 
** You can also use the shorter form, passing in the mixin, if your Impl class has the same name as your mixin + "Impl".
** 
** The default service id is the unqualified name of the service mixin (or impl if no mixin was provided).
** 
** This is an adaptation of ideas from [Guice]`http://code.google.com/p/google-guice/`.
** 
mixin ServiceBinder {

	** Binds the service mixin to a service impl class. The default service id is the unqualified name of the service mixin. 
	abstract ServiceBindingOptions bind(Type serviceMixin, Type? serviceImpl := null)

	** Defines a concrete implementation of a service. If 'implClass' is a mixin in terms of an impl class, without a service mixin.
	@Deprecated { msg="Use bind() instead" }
	@NoDoc
	abstract ServiceBindingOptions bindImpl(Type implClass)

}
