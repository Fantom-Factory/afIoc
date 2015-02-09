#IoC v2.0.2
---
[![Written in: Fantom](http://img.shields.io/badge/written%20in-Fantom-lightgray.svg)](http://fantom.org/)
[![pod: v2.0.2](http://img.shields.io/badge/pod-v2.0.2-yellow.svg)](http://www.fantomfactory.org/pods/afIoc)
![Licence: MIT](http://img.shields.io/badge/licence-MIT-blue.svg)

## Overview

`IoC` is an Inversion of Control (IoC) container and Dependency Injection (DI) framework inspired by the most excellent [Tapestry 5 IoC](http://tapestry.apache.org/ioc.html).

Like [Guice](http://code.google.com/p/google-guice/)? Know [Spring](http://www.springsource.org/spring-framework)? Then you'll love *IoC*!

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
  - service proxies ensure nothing is created until you actually use it
  - make circular service dependencies a thing of the past!

- **AOP - Advise your services**
  - intercept method calls to your services
  - apply cross cutting concerns such as authorisation, transactions and logging

- **Extensible**
  - inject your own objects and dependencies, not just services

- **Designed to help YOU the developer!**
  - simple API - 1 facet and 2 registry methods is all you need!
  - over 70 bespoke and informative Err messages!
  - Extensively tested: - `All tests passed! [37 tests, 221 methods, 482 verifies]`


## Install

Install `IoC` with the Fantom Repository Manager ( [fanr](http://fantom.org/doc/docFanr/Tool.html#install) ):

    C:\> fanr install -r http://repo.status302.com/fanr/ afIoc

To use in a [Fantom](http://fantom.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afIoc 2.0+"]

## Documentation

Full API & fandocs are available on the [Status302 repository](http://repo.status302.com/doc/afIoc/).

## Quick Start

1). Create a text file called `Example.fan`

```
using afIoc

// ---- Services are plain Fantom classes -------------------------------------

** A reusable piece of code
class PokerService {
    Void poke() { echo("Poking ${this.toStr}") }
}

** PokerService is reused here
class MyService {
    ** Inject services into services!
    @Inject PokerService? poker
}



// ---- Modules - every IoC application / library needs one -------------------

** This is the central place where services are defined and configured
class MyModule {
    static Void defineServices(ServiceDefinitions defs) {
        defs.add(MyService#)
        defs.add(PokerService#)
    }
}



// ---- Use the IoC Registry to access the services ---------------------------

class Main {
    Void main() {
        // create the registry, passing in our module
        registry := RegistryBuilder().addModule(MyModule#).build().startup()

        // different ways to access services
        test1 := (MyService) registry.serviceById("myService")       // returns a service instance
        test2 := (MyService) registry.dependencyByType(MyService#)   // returns the same instance
        test3 := (MyService) registry.autobuild(MyService#)          // build a new instance
        test4 := (MyService) registry.injectIntoFields(MyService())  // inject into existing objects

        // all test classes poke the same instance of PokerService
        test1.poker.poke()
        test2.poker.poke()
        test3.poker.poke()
        test4.poker.poke()

        // clean up
        registry.shutdown()
    }
}
```

2). Run `Example.fan` as a Fantom script from the command line:

```
C:\> fan Example.fan

[info] [afIoc] Adding module definition for Example_0::MyModule
[info] [afIoc] Starting IoC...

12 Services:

     Example_0::MyService1: Defined
     Example_0::MyService2: Defined
         afIoc::ActorPools: Builtin
afIoc::DependencyProviders: Builtin
        afIoc::LogProvider: Builtin
           afIoc::Registry: Builtin
       afIoc::RegistryMeta: Builtin
   afIoc::RegistryShutdown: Builtin
    afIoc::RegistryStartup: Builtin
afIoc::ServiceProxyBuilder: Builtin
 afIoc::ThreadLocalManager: Builtin
afPlastic::PlasticCompiler: Builtin

16.67% of services are unrealised (2/12)

   ___    __                 _____        _
  / _ |  / /_____  _____    / ___/__  ___/ /_________  __ __
 / _  | / // / -_|/ _  /===/ __// _ \/ _/ __/ _  / __|/ // /
/_/ |_|/_//_/\__|/_//_/   /_/   \_,_/__/\__/____/_/   \_, /
                            Alien-Factory IoC v2.0.4 /___/

IoC Registry built in 205ms and started up in 11ms

[warn] [afIoc] Autobuilding type 'Example_0::MyService1' which is *also* defined as service 'Example_0::MyService1 - unusual!

Poking fan.Example_0.Poker@680e2291
Poking fan.Example_0.Poker@680e2291
Poking fan.Example_0.Poker@680e2291
Poking fan.Example_0.Poker@680e2291

[info] [afIoc] Stopping IoC...
[info] [afIoc] IoC shutdown in 19ms
[info] [afIoc] "Goodbye!" from afIoc!
```

## Terminology

A **service** is a Fantom class whose instances are created and managed by IoC. It ensures only a single instance is created for the whole application or thread. Services are identified by a unique ID (usually the qualified class name). Services must be defined in a **module**. Services may solicit, and be instantiated with, configuration data defined in multiple modules.

A **dependency** is any class instance or object that a service depends on. A dependency may or may not be a service. Non service dependencies are managed by user defined [dependency providers](http://repo.status302.com/doc/afIoc/DependencyProvider.html).

A **module** is a class whose static methods define and configure services.

The **registry** is the key class in an IoC application. It creates, holds and manages the service instances.

## The IoC Registry

Frameworks such as [BedSheet](http://www.fantomfactory.org/pods/afBedSheet) and [Reflux](http://www.fantomfactory.org/pods/afReflux) are IoC containers. That is, they create and look after a `Registry` instance, using it to create classes and provide access to services.

Sometimes you don't have access to an IoC container and have to create the `Registry` instance yourself. (Running unit tests is a good example.) In these cases you will need to use the [RegistryBuilder](http://repo.status302.com/doc/afIoc/RegistryBuilder.html), passing in the module that defines your services:

    registry := RegistryBuilder().addModule(AppModule#).build().startup()
    ...
    service  := registry.serviceById("serviceId")
    ...
    registry.shutdown

If your code uses other IoC libraries, make sure modules from these pods are added too. Example, if using the [IocEnv library](http://www.fantomfactory.org/pods/afIocEnv) then add a dependency on the `afIocEnv` pod:

    registry := RegistryBuilder()
        .addModule(MyModule#)
        .addModulesFromPod("afIocEnv")
        .build().startup()

### Fantom Services

The Fantom language has the notion of application wide [services](http://fantom.org/doc/sys/Service.html). Should your application make use of this mechanism, IoC provides the [IocService](http://repo.status302.com/doc/afIoc/IocService.html) wrapper class that holds a `Registry` instance and extends Fantom's [Service](http://fantom.org/doc/sys/Service.html). It also contains convenience methods for creating and accessing the registry.

For example, to create and start a Fantom IoC Service:

    IocService([ MyModule# ]).start()

Then, from anywhere in your code, use the standard Fantom service methods to locate the `IocService` instance and query the registry:

    iocService := (IocService) Service.find(IocService#)
    ...
    myService  := iocService.dependencyByType(MyService#)

Uninstall `IocService` like any other:

    Service.find(IocService#).uninstall()

## Modules

Every IoC application / library will have a module class. Module classes are where services are defined and configured. Module classes declare static methods with special facets that tell IoC what they do.

By convention an application will call its module `AppModule` and libraries will name modules after themselves, but with a `Module` suffix. Example, BedSheet has a module named `BedSheetModule`.

### Pod Meta-data

It is good practice, when writing an IoC application or library, to always include the following meta in the `build.fan`

    meta = [ "afIoc.module" : "<module-qname>" ]

Where `<module-qname>` is the qualified type name of the pod's main module class.

This is how IoC knows what modules each pod has. It is how the `addModulesFromPod("afIocEnv")` line works; IoC inspects the meta-data in the `afIocEnv` pod and looks up the `afIoc.module` key. It then loads the modules listed.

The `afIoc.module` meta may also be a Comma Separated List (CSV) of module names; handy if the pod has many modules. Though it is generally better (more explicit / less prone to error) to use the [@SubModule](http://repo.status302.com/doc/afIoc/SubModule.html) facet on a main `AppModule` class.

## Services

A service can be any old Fantom class. What differentiates a *service* from any other class is that you typically want to reuse a service in multiple places. An IoC Service is a class that is created and held by the IoC Registry. IoC may then inject that service into other classes, which may themselves be services.

For IoC to instantiate and manage a service it needs to know:

- How to build the service
- What unique ID to store it under
- What scope it has (application or threaded)
- What its proxy strategy is.

(Scopes and proxy strategies are covered later, as they're kinda advanced topics.)

All these details are defined in the application's module.

Note that IoC does not want an instance of your service. Instead it wants to know how to make it. That is because IoC will defer creating your service for as long as possible (lazy loading).

If nobody ever asks for your service, it is never created. When the service is explicitly asked for, either by you or by anther service, only then is it created.

Note that under the covers, all services are resolved via their unique service ids, injection by type is merely a layer on top, added for convenience.

### Build Your Own

If we have a class `MyService` that we wish to use as a service, then we need to tell IoC how to build it. The simplest way is to declare a static *build* method in the module that creates the instance for us:

```
using afIoc

// Example 1
class AppModule {

    @Build
    static MyService buildMyService() {
        return MyService()
    }
}
```

The method may be called anything you like and be of any scope (internal or even private), but it needs to be `static` and it needs the `@Build` facet.

Because of the `@Build` facet, IoC inspects the method and infers the following:

- Calling the method creates a service instance - *inferred from `@Build`*
- The service is of type `MyService` - *inferred from the return type*
- The unique ID is `myPod::MyService` - *inferred from the return type's qualified name*

We can now retrieve an instance of `MyService` with the following:

    myService := (MyService) registry.serviceById(MyService#.qname)

or

    myService := (MyService) registry.dependencyByType(MyService#)

What if `MyService` created penguins? Well, it'd be useful to have a `Penguins` class / service to hold them in. We'll pass that into `MyService`. We'll also tell `MyService` how many penguins it should make:

    class MyService {
        new make(Int noOfPenguins, Penguins penguins) { ... }
    }

The `AppModule` now needs updating with a builder method for the `Penguins` service, and the `MyService` builder method needs updating also:

```
using afIoc

// Example 2
class AppModule {

    @Build
    static Penguins buildPenguins() {
       return Penguins()
    }

    @Build
    static MyService buildMyService(Penguins penguins) {
        return MyService(3, penguins)
    }
}
```

Before IoC calls `buildMyService()` it looks at the method signature and assumes any parameters are dependant services. In this case, `Penguins`. It then looks up, and creates if it doesn't already exist, the `Penguins` service and passes it to `buildMyService()`. This is an example of *method injection*. All this is automatic, and all builder methods may declare any number of services as a method parameters.

Note that the `@Build` facet has other attributes that give you control over the service's unique ID, scope and proxy strategy.

Service builder methods are a very powerful pattern as they give you complete control over how the service is created. But they are also very verbose and require a lot of code. So lets look at an easier way; the `defineServices()` method...

### Defining Services

Modules may declare a `defineServices()` static method. It may be of any visibility but must be called `defineServices` and it must define a single parameter of `ServiceDefinitions`. The method lets you create and add service definitions in place of writing builder methods.

We could replace the previous `Example 1` with the following:

```
using afIoc

class AppModule {
    static Void defineServices(ServiceDefinitions defs) {
        defs.add(MyService#)
    }
}
```

It may look simple, but several things are inferred from the above code:

- The service is of type `MyService` - *inferred from the service type*
- The unique ID is `myPod::MyService` - *inferred from the service type's qualified name*
- `MyService` may be instantiated by IoC.

Note how we didn't create an instance of `MyService`, just told IoC that it exists. When a service is defined in this way, IoC will inspect it an choose a suitable ctor to create it with.

Now lets replace the builder methods in `Example 2` with service definitions:

```
using afIoc

class AppModule {
    static Void defineServices(ServiceDefinitions defs) {
        defs.add(MyService#).withCtorArgs([ 3 ])
        defs.add(Penguins#)
    }
}
```

That's a lot more succinct! But wait! `MyService` has a ctor arg of `3` and it's easy to see how that is passed in, but what about the `Penguins` service? Just like method injection, IoC will assume all unknown parameters are services and will attempt to resolve them as such. This is an example of *ctor injection* and more is said in the relevant section.

## Dependency Injection

This section looks at how to inject one service into another; the different ways of injecting the `Penguins` service into `MyService`. The examples assume that both services have been defined or have builder methods.

### Field Injection

Field injection requires the least amount of work on your behalf, but has a couple of drawbacks. To use, simply mark the fields to be injected with `@Inject`. And that's it!

```
using afIoc

class MyService {
    @Inject private Penguins?     penguins
    @Inject private OtherService? otherService

    ...
}
```

When you request `MyService` from the registry:

    myService := (MyService) registry.dependencyByType(MyService#)

IoC creates an instance of `MyService` and then sets the fields. As simple as it sounds, it does have a couple of drawbacks:

1. **Services not available in the ctor**

  Because fields are set *after* the service is constructed, they are not available during the constructor call. Attempting to use injected field in the ctor will result in a `NullErr`.



        using afIoc
        
        class MyService {
            @Inject private Penguins?     penguins
            @Inject private OtherService? otherService
        
            new make() {
                penguins.save(...)  // Runtime NullErr --> penguins is null
            }
        
            ...
        }


2. **Fields *must* be nullable**

  Because the fields are set *after* the service is constructed, they need to be nullable. This is a shame because one of the nice features of Fantom is being able to specify non-nullable types.


3. **Fields cannot be const**

  Because the fields are set *after* the service is constructed, they cannot be `const`. This poses a problem for services that are to be shared between threads, because these services need to be `const` - therefore all their fields need to be `const` too.



How can we overcome these little niggles? Why, by setting the fields inside the ctor!

### Ctor Injection

Ctor injection is where IoC hands the service all the dependencies it needs via ctor arguments. IoC inspects the parameter list of the ctor, resolves each one as a dependency, and passes it in.

```
class MyService {
    private const Penguins     penguins
    private const OtherService otherService

    new make(Penguins penguins, OtherService otherService) {
        this.penguins     = penguins
        this.otherService = otherService
    }

    ...
}
```

Ctor injection puts you in complete control. You list which dependencies your service requires as ctor parameters and IoC passes them in. The dependencies may be used there and then or set as fields. Because the fields are set in the ctor, they may be non-nullable and `const`.

When IoC instantiates a class, it will *always* attempt ctor injection. That is, it will always inspect the ctor parameter list and attempt to resolve them as dependencies.

Note how the fields are **not** annotated with `@Inject`. In fact, `afIoc` is not used at all! That's because IoC does not need to touch the fields, we set them ourselves. Which leads to the one downfall of ctor injection:

1. **Fields must be set manually**

  This is not much of an issue for the above example, as it only means 2 extra lines of code. But what if you had a mega service with lots and lots of dependencies? It would be quite tiresome to manually set all the fields.



Note that ctor's can be of any scope you like: public, protected, internal or private. They are public in these examples purely for brevity.

#### Which ctor?

Sometimes your service may have multiple ctors. Perhaps one for building and another for testing. When this happens, which one should IoC use to create the service?

By default, IoC will choose the ctor with the *most* parameters. But this behaviour can be overridden by annotating a chosen ctor with `@Inject`.

```
using afIoc

const class MyService {

    ** By default, IoC would choose this ctor because it has the most parameters
    new make(Penguins penguins, OtherService otherService) {
        ....
    }

    ** But we can force IoC to use this ctor by annotating it with @Inject
    @Inject
    new make(|This| in) {
        ....
    }
}
```

### It-Block Injection

The easiest method of field injection is via a [it-block](http://fantom.org/doc/docLang/Fields.html#const) ctor parameter (see [This](http://fantom.org/doc/docLang/Closures.html#thisFunc)):

```
using afIoc

const class MyService {
    @Inject private const Penguins     penguins
    @Inject private const OtherService otherService

    new make(|This| f) { f(this) }

    ...
}
```

This is a form of ctor injection where the last parameter is the it-block function, `|This|`. When IoC encounters this special parameter it creates and passes in a function that sets all the fields annotated with `@Inject`. So to set the field in the service, just call the function!

A more verbose example would be:

```
using afIoc

const class MyService {
    @Inject private const Penguins penguins

    new make(|This| injectionFunc) {
        // right here, the users field is null

        // let afIoc set the users field
        injectionFunc.call(this)

        // now I can use the users field
        users.setIq("traci", 69)
    }
}
```

Again, because the fields are set in the ctor they may be non-nullable and `const`.

Note this is sometimes referred to as the `serialisation ctor` because it is how the Fantom serialisation mechanism sets fields when it inflates class instances.

### Mixed Injection

If a service is to be only used in the ctor there is no point in creating a field for it; it could just be injected as a ctor parameter. An it-block parameter may also be declared to set all the `@Inject`ed fields. This is an example of mixed injection.

```
using afIoc

const class MyService {
    @Inject private const Penguins penguins

    new make(OtherService other, |This| in) {

        // let afIoc inject penguins and any other @Inject fields
        in(this)

        // use the other service
        other.doSomthing()
    }
}
```

Note that the it-block parameter is *always* the last parameter in the parameter list.

Ctor parameters should be declared in the following order:

    new make(<config>, <supplied>, <dependencies>, <it-block>) { ... }

Where:

- `config` - service contributions / configuration (see Service Configuration)
- `supplied` - any ctor args declared by service definitions
- `dependencies` - dependencies and other services
- `it-block` - for it-block injection

### Post Injection

Once IoC has instantiated your service, called the ctor, and performed any field injection, it then looks for any methods annotated with `@PostInjection` - and calls them. Similar to ctor injection, `@PostInjection` methods may take dependencies and services as parameters.

```
using afIoc

const class MyService {

    new make(|This| in) {
        ....
    }

    @PostInjection
    Void doStuff(OtherService otherService) {
        otherService.doSomting()
    }
}
```

## Service Configuration

Arguably, services are more useful if they can be configured. IoC has a built-in means to configure, or contribute configuration, to any service defined in any module!

### List Configuration

Lets have our `Penguins` service hold a list of penguin related websites. And lets have other modules be able to contribute their own penguin URLs.

Following the standard principle of dependency injection, these URLs will be handed to the `Penguins` service. In IoC this is done via the ctor:

```
class Penguins {
    private Uri[] urls

    new make(Uri[] urls) {
        this.urls = urls
    }
}
```

If the first parameter of a service's ctor is a List, IoC assumes it is configuration and scans all known modules for appropiate contribution methods:

```
using afIoc

class AppModule {
    static Void defineServices(ServiceDefinitions defs) {
        defs.add(Penguins#)
    }

    @Contribute { serviceType=Penguins# }
    static Void contributePenguinUrls(Configuration config) {
        config.add(`http://ypte.org.uk/factsheets/penguins/`)
        config.add(`http://www.kidzone.ws/animals/penguins/`)
    }
}
```

Contribution methods are static methods annotated with `@Contribute`. They may be of any scope and be called anything (although by convention they have a `contributeXXX()` prefix. The `serviceType` facet parameter tells IoC which service the method contributes to. Each contribution method may add as many items to the list as it likes.

Note that any *any* module may define contribution methods for *any* service.

The `Configuration` object is write only. Because contribution methods may be called in any order, being able to *read* contributions would only give partial data. Only when the service is constructed is the full set of configuration known.

If were to build the `Penguins` service via a builder method then the first parameter (if it is a List or a Map) is taken to be service configuration and injected appropriately:

```
using afIoc

class AppModule {
    @Build
    static Penguins buildPenguins(Uri[] penguinUrls) {
       ...
    }

    @Contribute { serviceType=Penguins# }
    static Void contributePenguinUrls(Configuration config) {
        config.add(`http://ypte.org.uk/factsheets/penguins/`)
        config.add(`http://www.kidzone.ws/animals/penguins/`)
    }
}
```

Because the service configuration is a list of Uris, the contribution methods must contribute Uri objects. It is an error to add anything else. Example, if we try to add the number 19 we would get the Err message:

    ...
    [13] Looking for dependency of type acme::Penguins
    [14] Creating REAL Service 'acme::Penguins'
    [15] Creating 'acme::Penguins' via ctor autobuild
    [16] Determining injection parameters for acme::Penguins sys::Void make(Uri[] urls)
    [17] Looking for dependency of type sys::Uri[]
    [18] Gathering configuration of type sys::Uri[]
    [19] Invoking sys::Void contributePenguinUrls(afIoc::Configuration config) on acme::AppModule...
    afIoc::IocErr: Contribution 'Int' does not match service configuration value of Uri

That said, all contribution values are `coerced` via [afBeanUtils::TypeCoercer](http://repo.status302.com/doc/afBeanUtils/TypeCoercer.html) which gives a little leeway. `TypeCoercer` looks for `toXXX()` and `fromXXX()` methods to *coerce* values from one type to another. This is useful when contributing the likes of `Regex` which has a `fromStr()` method, or `File` which has a Uri ctor:

```
using afIoc

class AppModule {
    @Build
    static MyService buildMyService(File[] file) {
       ...
    }

    @Contribute { serviceType=MyService# }
    static Void contributeFiles(Configuration config) {
        config.add(File(`/css/styles-1.css`))  // file added as is
        config.add(`/css/styles-2.css`)        // Uri coerced to File via File(Uri) ctor
    }
}
```

### Ordering

What if the order of the penguin URLs were important? And what if we wanted our URL to appear before others? Luckily service configurations can be ordered.

First we have to give the configurations a unique ID. We do this by using `config.set()` which may be abbreviated to the map construct:

```
using afIoc

class AppModule {
    @Contribute { serviceType=Penguins# }
    static Void contributePenguinUrls(Configuration config) {
        config["youngPeoplesTrust"] = `http://ypte.org.uk/factsheets/penguins/`
        config["kidZone"]           = `http://www.kidzone.ws/animals/penguins/`

        // same as above, just a difference syntax
        config.set("natGeo",           `http://ngkids.co.uk/did-you-know/emperor_penguins`)
    }
}
```

In our module, when we contriture our URL we can use ordering constraints to say where our URL should appear.

```
using afIoc

class MyModule {
    @Contribute { serviceType=Penguins# }
    static Void contributePenguinUrls(Configuration config) {
        config.set("defenders", `http://www.defenders.org/penguins/basic-facts`).before("youngPeoplesTrust")
        config.set("wikipedia", `http://en.wikipedia.org/wiki/Penguin`         ).after ("natGeo")
    }
}
```

The above shows how we use the configuration IDs to position our contributions.

### Map Configuration

## Overrides

Override Services

Override Configuration

## Service Scope

Services are either created once [perApplication](http://repo.status302.com/doc/afIoc/ServiceScope#perApplication.html) (singletons) or once [perThread](http://repo.status302.com/doc/afIoc/ServiceScope#perThread.html). Application scoped services *must* be defined as `const`.

(Using proxies) you can even inject a `perThread` scoped service into a `perApplication` scoped service! Think about it... you can inject your [http request](http://fantom.org/doc/web/WebReq.html) into any static service you desire!

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

Strive to keep your services `const`, declare a serialisation ctor to keep `@Inject`ed fields non-nullable:

    new make(|This| injectInto) { injectInto(this) }

Define one main module and declare it in both the pod meta and the pod index props. Use `@SubModule` to reference additional dependant modules in the same pod.

If you have no say in how your classes are created (say, when you're using flux) then use the following line to inject dependencies when needed:

    ((IocService) Service.find(IocService#)).injectIntoFields(this)

When creating GUIs (say, with fwt) then use [Registry.autobuild()](http://repo.status302.com/doc/afIoc/Registry#autobuild.html) to create your panels, commands and other objects. These aren't services and should not be declared as such, but they do often make use of services.

IoC gives detailed error reporting should something go wrong, nevertheless try turning debug logging on to make IoC give trace level contextual information.

Don't be scared of creating `const` services! Use the [Concurrent](http://www.fantomfactory.org/pods/afConcurrent) library to safely store and access mutable state across thread boundaries.

