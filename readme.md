## Overview 

`IoC` is an Inversion of Control (IoC) container and Dependency Injection (DI) framework inspired by the most excellent [Tapestry 5 IoC](http://tapestry.apache.org/ioc.html).

Like [Guice](http://code.google.com/p/google-guice/)? Know [Spring](http://www.springsource.org/spring-framework)? Then you'll love *afIoc*!

- **Injection - any way *you* want it!**
  - field injection
  - ctor injection
  - it-block ctor injection - `new make(|This|in) { in(this) }`

- **Distributed service configuration**
  - configure *any* service *from* any **pod** / **module**
  - configure via simple Lists and Maps

- **Override everything**
  - override services and configuration, even override your overrides!
  - replace real services with test services
  - set sensible defaults and let users override them

- **True lazy loading**
  - services can be proxied to ensure nothing is created until you actually use it
  - make circular service dependencies a thing of the past!

- **Advise services with aspects**
  - intercept method calls to your services
  - apply cross cutting concerns such as authorisation, transactions and logging

- **Extensible**
  - inject your own objects, not just services

- **Designed to help YOU the developer!**
  - simple API - 1 facet and 2 registry methods is all you need!
  - over 70 bespoke and informative Err messages!
  - Extensively tested: - `All tests passed! [35 tests, 216 methods, 456 verifies]`


  > **ALIEN-AID:** See [Fantom-Factory](http://www.fantomfactory.org/tags/afIoc) for IoC tutorials.



## Install 

Install `IoC` with the Fantom Repository Manager ( [fanr](http://fantom.org/doc/docFanr/Tool.html#install) ):

    C:\> fanr install -r http://repo.status302.com/fanr/ afIoc

To use in a [Fantom](http://fantom.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afIoc 2.0+"]

## Documentation 

Full API & fandocs are available on the [Status302 repository](http://repo.status302.com/doc/afIoc/).

## Quick Start 

1. Create services as plain Fantom objects
2. Use the `@Inject` facet to mark fields as dependencies
3. Define and configure services in an `AppModule` class
4. Build and start the registry
5. Go, go, go!

### Example 

1). Create a text file called `Example.fan`

```
class Main {
  Void main() {
    registry := IocService([MyModule#]).start.registry

    test1 := (MyService1) registry.serviceById("myservice1")        // returns a singleton
    test2 := (MyService1) registry.dependencyByType(MyService1#)    // returns the same singleton
    test3 := (MyService1) registry.autobuild(MyService1#)           // build a new instance
    test4 := (MyService1) registry.injectIntoFields(MyService1())   // inject into existing Objs

    test1.service2.kick  // --> Ass!
    test2.service2.kick  // --> Ass!
    test3.service2.kick  // --> Ass!
    test4.service2.kick  // --> Ass!

    Service.find(IocService#).uninstall
  }
}

class MyModule {              // every application needs a module class
  static Void defineServices(ServiceBinder binder) {
    binder.bind(MyService1#)  // define your singletons here
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

2). Run `Example.fan` as a Fantom script from the command line:

```
C:\> fan Example.fan

[info] [afIoc] Adding module definition for Example_0::MyModule
[info] [afIoc] Starting IoC...

14 Services:

     Example_0::MyService1: Defined
     Example_0::MyService2: Defined
         afIoc::ActorPools: Builtin
afIoc::AspectInvokerSource: Builtin
afIoc::DependencyProviders: Builtin
     afIoc::InjectionUtils: Builtin
        afIoc::LogProvider: Builtin
           afIoc::Registry: Builtin
       afIoc::RegistryMeta: Builtin
   afIoc::RegistryShutdown: Builtin
    afIoc::RegistryStartup: Builtin
afIoc::ServiceProxyBuilder: Builtin
 afIoc::ThreadLocalManager: Builtin
afPlastic::PlasticCompiler: Builtin

14.29% of services are unrealised (2/14)

   ___    __                 _____        _
  / _ |  / /_____  _____    / ___/__  ___/ /_________  __ __
 / _  | / // / -_|/ _  /===/ __// _ \/ _/ __/ _  / __|/ // /
/_/ |_|/_//_/\__|/_//_/   /_/   \_,_/__/\__/____/_/   \_, /
                            Alien-Factory IoC v2.0.0 /___/

IoC Registry built in 205ms and started up in 11ms

[warn] [afIoc] Autobuilding type 'Example_0::MyService1' which is *also* defined as service 'Example_0::MyService1 - unusual!
[info] [afIoc] Stopping IoC...
[info] [afIoc] IoC shutdown in 19ms
[info] [afIoc] "Goodbye!" from afIoc!
```

## Terminology 

IoC distinguishes between **Services** and **Dependencies**.

A **service** is a Fantom class where there is only one (singleton) instance for the whole application (or one per thread for non-const classes). Each service is identified by a unique ID (usually the qualified class name) and may, or may not, be represented by a Mixin. Services are managed by IoC and must be defined by a module. Services may solicit configuration contributed by other modules.

A **dependency** is any class or object that another service depends on. A dependency may or may not be a service.  For example, a class may depend on a field `Int maxNoOfThreads` but that `Int` isn't a service, it's just a number. Non service dependencies are managed by user defined [dependency providers](http://repo.status302.com/doc/afIoc/DependencyProvider.html).

A **contribution** is a means to configure a service.

A **module** is a class where services and contributions are defined.

## Starting the IoC 

You can use [IocService](http://repo.status302.com/doc/afIoc/IocService.html) to start `IoC` as a Fantom service:

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

Services are defined in Module classes, where each meaningful method is static and usually annotated with a facet.

The `defineServices()` method does not have a facet, but is declared with a standard signature. The `defineServices()` method is the common means to define services. For example:

```
class AppModule {

  static Void defineServices(ServiceDefinitions defs) {

    // defines a service with an ID of 'myPod::MyService'
    defs.add(MyService#, MyServiceImpl#)

    // defines a service with an ID of 'myPod::myServiceImpl'
    defs.add(MyServiceImpl#)

    // defines a service with an ID of 'elephant'
    defs.add(MyServiceImpl#).withId("elephant")
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

Services are either created once [perApplication](http://repo.status302.com/doc/afIoc/ServiceScope#perApplication.html) (singletons) or once [perThread](http://repo.status302.com/doc/afIoc/ServiceScope#perThread.html). Application scoped services *must* be defined as `const`.

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
  static Void contributeExample(Configuration conf) {
    conf.add("text/plain")
  }
}
```

The list and map types are inferred from the ctor definition and all contribution types must fit.

Think of `Configuration` as an ordered Map that collects data from *all* the IoC modules. The collected data / Map is then passed to the ctor of the service. If the service ctor takes a List then just the Map values are passed.

## Lazy Loading 

Define your service with a mixin and take advantage of true lazy loading!

By fronting your service with a mixin, IoC can generate and compile a service proxy on the fly. The *real* service is only instantiated when you call a method on the proxy.

This means circular service dependencies are virtually eliminated!

It also allows you to inject `perThread` scoped services into `perApplication` scoped services.

## Advise Your Services 

Intercept all method calls to proxied services and wrap them in your own code!

See [@Advise](http://repo.status302.com/doc/afIoc/Advise.html) for details

## Tips 

Strive to keep your services `const`, delcare a serialisation ctor to keep `@Inject`ed fields non-nullable:

    new make(|This| injectInto) { injectInto(this) }

Define one main module and declare it in both the pod meta and the pod index props. Use `@SubModule` to reference additional dependant modules in the same pod.

If you have no say in how your classes are created (say, when you're using flux) then use the following line to inject dependencies when needed:

    ((IocService) Service.find(IocService#)).injectIntoFields(this)

When creating GUIs (say, with fwt) then use [Registry.autobuild()](http://repo.status302.com/doc/afIoc/Registry#autobuild.html) to create your panels, commands and other objects. These aren't services and should not be declared as such, but they do often make use of services.

IoC gives detailed error reporting should something go wrong, nevertheless try turning debug logging on to make IoC give trace level contextual information.

Don't be scared of creating `const` services! Use the [Concurrent](http://www.fantomfactory.org/pods/afConcurrent) library to safely store and access mutable state across thread boundaries.

