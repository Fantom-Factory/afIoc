
** Use in your 'AppModule.defineServices(ServiceDefinitions defs) {...}' method. It's how you tell IoC about your services. If 
** your service implementation is fronted by a mixin, then pass them both in: 
** 
** pre>
** class AppModule {
**     static Void defineServices(ServiceDefinitions defs) {
**         defs.add(MyService#, MyServiceImpl#)
**     } 
** }
** <pre
**
** If your service is just an impl class then you can use the shorter form:
** 
** pre>
** class AppModule {
**     static Void defineServices(ServiceDefinitions defs) {
**         defs.add(MyServiceImpl#)
**     } 
** }
** <pre
** 
** You can also use the shorter form, passing in the mixin, if your Impl class has the same name as your mixin + "Impl".
** 
** The default service id is the unqualified name of the service mixin (or impl if no mixin was provided).
** 
** This is an adaptation of ideas from [Guice]`http://code.google.com/p/google-guice/`.
@NoDoc @Deprecated { msg="Use ServiceDefinitions instead." }
mixin ServiceBinder {

	** Binds the service mixin to a service impl class. The default service id is the unqualified name of the service mixin. 
	abstract ServiceBindingOptions bind(Type serviceMixin, Type? serviceImpl := null)

}
