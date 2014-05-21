## Overview 

`IoC` is an Inversion of Control (IoC) container and Dependency Injection (DI) framework based on the most excellent [Tapestry 5 IoC](http://tapestry.apache.org/ioc.html).

Like [Guice](http://code.google.com/p/google-guice/)? Know [Spring](http://www.springsource.org/spring-framework)? Then you'll love *afIoc*!

- **Injection - the way *you* want it!**
  - field injection
  - ctor injection
  - it-block ctor injection - `new make(|This|in) { in(this) }`

- **Distributed service configuration between pods and modules**
  - configure *any* service *from* any pod / module
  - configure via simple Lists and Maps

- **Override everything**
  - override services and configuration, even override your overrides!
  - replace real services with test services
  - set sensible application defaults and let your users override them

- **True lazy loading**
  - services are proxied to ensure nothing is created until you actually use it
  - make circular service dependencies a thing of the past!

- **Advise services with aspects**
  - intercept method calls to your services
  - apply cross cutting concerns such as authorisation, transactions and logging

- **Extensible**
  - inject your own objects, not just services

- **Designed to help YOU the developer!**
  - simple API - 1 facet and 2 registry methods is all you need!
  - over 70 bespoke and informative Err messages!
  - Extensively tested: - `All tests passed! [36 tests, 225 methods, 614 verifies]`


  > **ALIEN-AID:** For tips and tutorials on IoC, be sure to check out [Fantom-Factory](http://www.fantomfactory.org/tags/afIoc)!



## Install 

Install `IoC` with the Fantom Repository Manager ( [fanr](http://fantom.org/doc/docFanr/Tool.html#install) ):

    C:\> fanr install -r http://repo.status302.com/fanr/ afIoc

To use in a [Fantom](http://fantom.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afIoc 1.6+"]

## Documentation 

Full API & fandocs are available on the [Status302 repository](http://repo.status302.com/doc/afIoc/).

## Quick Start 

1. Create services as Plain Old Fantom Objects
2. Use the `@Inject` facet to mark fields as dependencies
3. Define and configure your services in a `Module` class
4. Build and start the registry
5. Go, go, go!

```
class Main {
  static Void main(Str[] args) {
    registry := IocService([MyModule#]).start.registry

    test1 := (MyService1) registry.serviceById("myservice1")        // return a singleton
    test2 := (MyService1) registry.dependencyByType(MyService1#)    // same instance as test1
    test3 := (MyService1) registry.autobuild(MyService1#)           // build a new instance
    test4 := (MyService1) registry.injectIntoFields(MyService1())   // inject into existing Objs

    test1.service2.kick // --> Ass!
    test2.service2.kick // --> Ass!
    test3.service2.kick // --> Ass!
    test4.service2.kick // --> Ass!

    Service.find(IocService#).uninstall
  }
}

class MyModule {                    // every application needs a module class
  static Void bind(ServiceBinder binder) {
    binder.bind(MyService1#)    // define your singletons here
    binder.bind(MyService2#)
  }
}

class MyService1 {
  @Inject               // you'll use @Inject all the time
  MyService2? service2  // inject services into services!
}

class MyService2 {
  Str kick() { return "Ass!" }
}
```

## Terminology 

IoC distinguishes between **Services** and **Dependencies**.

A **service** is just a Plain Old Fantom Object where there is only one (singleton) instance for the whole application (or one per thread for non-const classes). Each service is identified by a unique ID (usually the qualified class name) and may, or may not, be represented by a Mixin. Services are managed by IoC and must be defined by a module. Services may solicit configuration contributed by other modules.

A **dependency** is any class or object that another service depends on. A dependency may or may not be a service.  For example, a class may depend on a field `Int maxNoOfThreads` but that `Int` isn't a service, it's just a number. Non service dependencies are managed by user defined [dependency providers](http://repo.status302.com/doc/afIoc/DependencyProvider.html).

A **contribution** is a means to configure a service.

A **module** is a class where services and contributions are defined.

## Starting the IoC 

Use [IocService](http://repo.status302.com/doc/afIoc/IocService.html) to start `IoC` as a Fantom service:

    IocService([MyModule#]).start
    ...
    reg     := ((IocService) Service.find(IocService#)).registry
    service := reg.dependencyByType(MyService#)
    ...
    Service.find(IocService#).uninstall

Or use [RegistryBuilder](http://repo.status302.com/doc/afIoc/RegistryBuilder.html) to manage the [Registry](http://repo.status302.com/doc/afIoc/Registry.html) instance manually;

    reg := RegistryBuilder().addModule(MyModule#).build.startup
    ...
    service := reg.dependencyByType(MyService#)
    ...
    reg.shutdown

When [building a registry](http://repo.status302.com/doc/afIoc/RegistryBuilder.html), you declare which modules are to loaded. You may also load modules from dependant pods, in which case, each pod should have declared the following meta:

`"afIoc.module" : "{qname}"`

Where `{qname}` is a qualified type name of an `AppModule` class. Additional modules can be declared by the [@SubModule](http://repo.status302.com/doc/afIoc/SubModule.html) facet.

Modules can also be loaded from index properties in a similar manner.

## Defining Services 

Services are defined in Module classes, where each meaningful method is static and annotated with a facet.

Except the `bind()` method which, does not have a facet but, is declared with a standard signature. The bind method is also the common means to define services. For example:

```
class AppModule {

  static Void bind(ServiceBinder binder) {

    // has service ID of 'myPod::MyService'
    binder.bind(MyService#, MyServiceImpl#)

    // has service ID of 'myPod::myServiceImpl'
    binder.bind(MyServiceImpl#)

    // has service ID of 'elephant'
    binder.bind(MyServiceImpl#).withId("elephant")
  }
}
```

Modules may can also define *builder* methods. These are static methods annotated with the `@Build` facet. Here you may construct and return the service yourself. Any parameters are taken to be dependencies and are resolved and injected as such when the method is called. For example, to manually build a service with the Id `penguin`:

```
class AppModule {

  @Build { serviceId="penguin" }
  static EmailService buildStuff(EmailConfig config) {
    EmailServiceImpl(config)
  }
}
```

Services are *not* created until they are referenced or required.

## Dependency Injection 

IoC performs both ctor and field injection, for normal and const fields.

Note that under the covers, all services are resolved via their unique service ids, injection by type is merely a layer on top, added for convenience.

When IoC autobuilds a service it locates a suitable ctor. This is either the one donned with the `@Inject` facet or the one with the most parameters. Ctor parameters are taken to be dependencies and are resolved appropriately.

Field injection happens *after* the object has been created and so fields must be declared as nullable:

```
class MyService {
  @Inject
  MyService? myService
}
```

The exception is if you declare an it-block ctor:

```
const class MyService {
  @Inject
  const MyService myService

  new make(|This|? f := null) { f?.call(this) }
}
```

On calling `f` all injectable fields are set, even fields marked as `const`. The it-block ctor may be abbreviated to:

    new make(|This| f) { f(this) }

After object construction and field injection, any extra setup may be performed via methods annotated with `@PostInjection`. These methods may be of any visibility and all parameters are resolved as dependencies.

## Service Scope 

Services are either created once [perApplication](http://repo.status302.com/doc/afIoc/ServiceScope#perApplication.html) (singletons) or once [perThread](http://repo.status302.com/doc/afIoc/ServiceScope#perThread.html). Application scoped services *must* be defined as `const`. If you need mutable state in your const service, try using the [ConcurrentState](http://repo.status302.com/doc/afIoc/ConcurrentState.html) class.

(Using proxies) you can even inject a `perThread` scoped service into a `perApplication` scoped service! Think about it... you can inject your [http request](http://fantom.org/doc/web/WebReq.html) into any static service you desire!

## Service Configuration 

Services can solicit configuration from modules simply by declaring a list or a map in their ctor or builder method.

```
class Example {

  new make(Str[] mimeTypes) { ... }
  ...
}
```

Modules may then contribute to the `Example` service:

```
class AppModule {

  @Contribute { serviceType=Example# }
  static Void contributeExample(OrderedConfig conf) {
    conf.add("text/plain")
  }
}
```

The list and map types are inferred from the ctor definition and all contribution types must fit.

If the service declares a map configuration then contribution methods should take a `MappedConfig` object. If the map config uses `Str` as the key, then the created map is `caseInsensitive` otherwise the map is `ordered`.

## Lazy Loading 

Define your service with a mixin and take advantage of true lazy loading!

By fronting your service with a mixin, IoC will generate and compile a service proxy on the fly. The *real* service is only instantiated when you call a method on the proxy.

This means registry startup times can be quicker than ever and circular service dependencies are virtually eliminated!

It also allows you to inject `perThread` scoped services into `perApplication` scoped services.

## Advise Your Services 

Intercept all calls to services defined by a mixin and wrap them in your own code.

See [@Advise](http://repo.status302.com/doc/afIoc/Advise.html) for details

## More! 

`Ioc` comes bundled with utility classes that cover common use cases:

- [RegistryStartup](http://repo.status302.com/doc/afIoc/RegistryStartup.html): (Service) Define tasks to execute when the registry starts up.
- [RegistryShutdownHub](http://repo.status302.com/doc/afIoc/RegistryShutdownHub.html): (Service) Define tasks to execute when the registry shuts down.
- [ThreadLocalManager](http://repo.status302.com/doc/afIoc/ThreadLocalManager.html): (Service) Keep tabs on threaded state.
- [TypeCoercer](http://repo.status302.com/doc/afIoc/TypeCoercer.html): Coerce Objs of one type to another via Fantom's `toXXX()` and `fromXXX()` methods.
- [StrategyRegistry](http://repo.status302.com/doc/afIoc/StrategyRegistry.html): Holds a map of `Type:Obj` where values may be looked up by type inheritance search.

## Tips 

Strive to keep your services `const`, delcare a serialisation ctor to keep `@Inject`ed fields non-nullable:

    new make(|This| injectInto) { injectInto(this) }

Define one main module and declare it in both the pod meta and the pod index props. Use `@SubModule` to reference additional dependant modules in the same pod.

If you have no say in how your classes are created (say, when you're using flux) then use the following line to inject dependencies when needed:

    ((IocService) Service.find(IocService#)).injectIntoFields(this)

When creating GUIs (say, with fwt) then use [Registry.autobuild()](http://repo.status302.com/doc/afIoc/Registry#autobuild.html) to create your panels, commands and other objects. These aren't services and should not be declared as such, but they do often make use of services.

IoC gives detailed error reporting should something go wrong, nevertheless try turning debug logging on to make IoC give trace level contextual information.

Don't be scared of creating `const` services! Use the [Concurrent](http://www.fantomfactory.org/pods/afConcurrent) library to safely store and access mutable state across thread boundaries.

