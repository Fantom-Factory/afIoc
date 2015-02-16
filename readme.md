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

A **service** is a Fantom class whose instances are created and managed by IoC. It ensures only a single instance is created for the whole application or thread. Services are identified by a unique ID (usually the qualified class name). Services must be defined in a **module**. Services may solicit, and be instantiated with, configuration data defined by multiple modules.

A **dependency** is any class instance or object that a service depends on. A dependency may or may not be a service. Non service dependencies are managed by user defined [dependency providers](http://repo.status302.com/doc/afIoc/DependencyProvider.html).

A **module** is a class whose static methods define and configure services.

The **registry** is the key class in an IoC application. It creates, holds and manages the service instances.

## The IoC Registry

Frameworks such as [BedSheet](http://www.fantomfactory.org/pods/afBedSheet) and [Reflux](http://www.fantomfactory.org/pods/afReflux) are IoC containers. That is, they create and look after a `Registry` instance, using it to create classes and provide access to services.

Sometimes you don't have access to an IoC container and have to create the `Registry` instance yourself. (Running unit tests is a good example.) In these cases you will need to use the [RegistryBuilder](http://repo.status302.com/doc/afIoc/RegistryBuilder.html), passing in the module(s) that define your services:

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

The `afIoc.module` meta may also be a Comma Separated List (CSV) of module names; handy if the pod has many modules. Though it is generally better (more explicit / less prone to error) to use the [@SubModule](http://repo.status302.com/doc/afIoc/SubModule.html) facet on a single module class.

## Services

A service can be any old Fantom class. What differentiates a *service* from any other class is that you typically want to reuse a service in multiple places. An IoC Service is a class that is created and held by the IoC Registry. IoC may then inject that service into other classes, which may themselves be services.

For IoC to instantiate and manage a service it needs to know:

- How to build the service
- What unique ID to store it under
- What Fantom `Type` the service is
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

```
myService := (MyService) registry.serviceById(MyService#.qname)
```

or

```
myService := (MyService) registry.dependencyByType(MyService#)
```

The `serviceId` facet attribute allows you to define a service with a different ID.

```
@Build { serviceId="wotever" }
static MyService buildMyService() {
    return MyService()
}
```

Taking our example further, what if `MyService` created penguins? Well, it'd be useful to have a `Penguins` class / service to hold them in so we'll pass that into the ctor of `MyService`. We'll also tell `MyService` how many penguins it should make. The `MyService` ctor now looks like:

```
class MyService {
    new make(Int noOfPenguins, Penguins penguins) { ... }
}
```

Because we've changed the `MyService` ctor we need to update the `MyService` builder method in the `AppModule`. We need a builder method for the `Penguins` service too. `AppModule` now looks like:

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

Before IoC calls `buildMyService()` it looks at the method signature and assumes any parameters are dependencies that need to be passed in. In this case, it is the service `Penguins`. So it looks up, and creates if it doesn't already exist, the `Penguins` service and passes it to `buildMyService()`. This is an example of *method injection*. All this is automatic, and all builder methods may declare any number of services and dependencies as a method parameters.

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

Note how we didn't create an instance of `MyService`, just told IoC that it exists. When a service is defined in this way, IoC will inspect it and choose a suitable ctor to create it with.

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

That's a lot more succinct! But wait! The `MyService` definition just declares a ctor arg of `3`, but what about the `Penguins` service? Just like method injection, IoC will assume all unknown parameters are services and will attempt to resolve them as such. This is an example of *ctor injection* and more is said in the relevant section.

## Dependency Injection

This section looks at how to inject one service into another; or in particular, different ways of injecting the `Penguins` service into `MyService`. The examples assume that both services have been defined or have builder methods.

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

  Because fields are set *after* the service is constructed, they are not available during the constructor call. Attempting to use an injected field in the ctor will result in a `NullErr`.



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

Note how the fields are **not** annotated with `@Inject`. (In fact the class doesn't even have a ` using afIoc` statement!) That's because IoC does not need to touch the fields, we set them ourselves. Which leads to the one downfall of ctor injection:

1. **Fields must be set manually**

  This is not much of an issue for the above example, as it only means 2 extra lines of code. But what if you had a mega service with 12 or more dependencies!? It would quickly become quite tiresome to set all the fields manually.



Note that ctor's can be of any scope you like: public, protected, internal or private. In the following examples, the ctors are public purely for brevity.

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

This is a form of ctor injection where the last parameter is the it-block function, `|This|`. When IoC encounters this special parameter it creates and passes in a function that sets all the fields annotated with `@Inject`. So to set all the fields in the service, just call the function!

A more verbose example would be:

```
using afIoc

const class MyService {
    @Inject private const Penguins penguins

    new make(|This| injectionFunc) {
        // right here, the penguins field is null

        // let IoC set the penguins field
        injectionFunc.call(this)

        // now I can use the penguins field
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

- `config` - service contributions / configuration (see [Service Configuration](#serviceConfiguration))
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

## Autobuilding

It is common to *autobuild* class instances. So much so, there is an `autobuild()` method on the registry, an `autobuild()` method on service configuration objects and there is even an `@Autobuild` facet. But what is *autobuilding*?

Autobuilding is the act of creating an instance of a class with IoC. That is, IoC will new up the instance and perform any necessary injection as previously outlined.

For example, all services defined via `defineServices()` methods are autobuilt.

Let's look at this code:

```
Void main() {
    registry := RegistryBuilder().build().startup()

    myClass := (MyClass) registry.autobuild(MyClass#)

    registry.shutdown()
}
```

It uses IoC to create an instance of `MyClass` with all dependencies injected into it. Note that `MyClass` is **not** a service for it has not been defined as a service in any module class. Instead, `MyClass` is just a simple standalone instance.

Autobuilding a class will **always** create a new instance. This is the difference between a service and an autobuilt class. Services are cached and re-used by IoC. IoC maintains a lifecyle for, and looks after services. Autobuilt instances are your responsibility.

An autobuilt class *may* be a service (such as those defined via `defineServices()` methods) but the mere act of autobuilding does not make it a service.

Now you know the difference, lets look at the `@Autobuild` facet:

```
using afIoc
class MyClass {

    @Inject
    Registry registry

    @Autobuild { ctorArgs=["arg1", "arg2"] }
    MyOtherClass otherClass

    new make(|This| f) { f(this) }
}
```

Here the registry service is injected, and a new instance of `otherClass` is created and injected. `arg1` and `arg2` are used as ctor arguments when building `MyOtherClass`.

The `@Autobuild` facet is an example of custom dependency injection. See [Dependency Providers](#dependecnyProviders) for details.

## Service Configuration

Arguably, services are more useful if they can be configured. IoC has a built-in means to configure, or contribute configuration, to any service defined in any module!

### List Configuration

Lets have our `Penguins` service hold a list of penguin related websites. And lets have other modules be able to contribute their own penguin URLs.

Following the standard principle of dependency injection, these URLs will be handed to the `Penguins` service. In IoC this is done via ctor injection:

```
class Penguins {
    private Uri[] urls

    new make(Uri[] urls) {
        this.urls = urls
    }
}
```

If the first parameter of a service's ctor is a List, IoC assumes it is configuration and scans all known modules for appropriate contribution methods:

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

Contribution methods are static methods annotated with `@Contribute`. They may be of any scope and be called anything; although by convention they have a `contributeXXX()` prefix. The `serviceType` facet parameter tells IoC which service the method contributes to. Each contribution method may add as many items to the list as it likes.

Note that any *any* module may define contribution methods for *any* service. Because the modules may be spread out in multiple pods, this is known as *distributed configuration*.

The `Configuration` object is write only. Only when all the contribution methods have been called, is the full list of configuration data known. Because contribution methods may be called in any order, being able to *read* contributions would only give partial data. Becasuse partial data can be misleading it is deemed better not to give any at all.

If the `Penguins` service were to built via a builder method then the method's first parameter (if it is a List or a Map) is taken to be service configuration and injected appropriately:

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

```
afIoc::IocErr: Contribution 'Int' does not match service configuration value of Uri
```

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

What if the order of the penguin URLs were important? What if we wanted our URL to appear before others? Luckily service configurations can be ordered.

First we have to give the configurations a unique ID. We do this by using `Configuration.set()`. Note that `Configuration.set()` is annotated with `@Operator` which means calls to it may be abbreviated using map syntax:

```
using afIoc

class AppModule {
    @Contribute { serviceType=Penguins# }
    static Void contributePenguinUrls(Configuration config) {
        // standard call to set()
        config.set("natGeo",          `http://ngkids.co.uk/did-you-know/emperor_penguins`)

        // same as above, but using the Map.set() @Operator syntax
        config["youngPeoplesTrust"] = `http://ypte.org.uk/factsheets/penguins/`
        config["kidZone"]           = `http://www.kidzone.ws/animals/penguins/`
    }
}
```

Then in a different module, when more URLs are contributed we can use ordering constraints to say where our URL should appear.

```
using afIoc

class MyModule {
    @Contribute { serviceType=Penguins# }
    static Void contributePenguinUrls(Configuration config) {
        config.set("defenders", `http://www.defenders.org/penguins/basic-facts`).before("natGeo")
        config.set("wikipedia", `http://en.wikipedia.org/wiki/Penguin`         ).after ("kidZone")
    }
}
```

The above shows how to use configuration IDs to position the contributions using `before` and `after` notation. If the `Penguins` service were to print the List it was injected with, it would look like:

```
[
  `http://www.defenders.org/penguins/basic-facts`,
  `http://ngkids.co.uk/did-you-know/emperor_penguins`,
  `http://ypte.org.uk/factsheets/penguins/`,
  `http://www.kidzone.ws/animals/penguins/`,
  `http://en.wikipedia.org/wiki/Penguin`
]
```

Not every piece of configuration needs an ID. If one isn't provided IoC makes up its own unique ID for the config. But as nobody knows what that ID is, other config can't then be ordered before or after it - obviously!

Note that configuration IDs are also used for overriding / removing contributions. See [Configuration Overrides](#overridingConfig) for details.

### Map Configuration

Sometimes it's useful for the service to know what IDs were used when adding pieces of configuration. In that case, it can replace the List (in the ctor or builder method) with a Map:

```
class Penguins {
    private Str:Uri urls

    new make(Str:Uri urls) {
        this.urls = urls
    }
}
```

Injected configuration Maps are always ordered. If the `Penguins` service were to print its Map, it would look like:

```
[
  "defenders"         : `http://www.defenders.org/penguins/basic-facts`,
  "natGeo"            : `http://ngkids.co.uk/did-you-know/emperor_penguins`,
  "youngPeoplesTrust" : `http://ypte.org.uk/factsheets/penguins/`,
  "kidZone"           : `http://www.kidzone.ws/animals/penguins/`,
  "wikipedia"         : `http://en.wikipedia.org/wiki/Penguin`
]
```

As you can see, in effect, we've just configured and injected a Map!

In this `Penguins` example we've been using a `Str` for the key, but we could use any object; `Uris`, `Files`, `MimeTypes`...

Again, map keys are type coerced to the correct type. If the map key does not fit, or can not be coerced, to the type declared by the service an error is thrown.

## Overrides

A cool feature about IoC is that just about anything may be overridden, be it a service implementation, a ctor parameter or a piece of config.

Note that all aspects of IoC are determined at registry startup. Once the registry is built, very little changes. So when we talk of overriding we're actually talking about overriding definitions. This is done via `AppModules` and is very powerful.

### Overriding Services

Some aspects of Service can not be changed, these are:

- The unique ID
- The Fantom Type

All other aspects may be. Substituting service implementations can be useful for testing where real services may be switched with mocked versions.

Given that `MyService` has already been defined in a module, we can substitute it for our own instance by writing an `@Override` method.

`@Override` methods are similar to builder methods in that they may be of any scope, and be named what you like, but they must be static and be annotated with the `@Override` facet.

```
@Override
static MyService overrideMyService() {
    // build a different instance
    return MyServiceImpl(...)
}
```

The return type, `MyService` in the above example, is used to find the service to override. The return type **must** match the original service type. If more control is required over which service to override, you can use the `serviceId` or `serviceType` facet attributes:

```
@Override { serviceId="acme::MyService" }
static MyService overrideMyService() {
    // build a different instance
    return MyServiceImpl(...)
}
```

Service scope and proxy strategies may also be overriden via facet attributes. The override may also be marked as `optional` if there is a chance the original service may not be defined; for example if it is defined by an optional 3rd party library.

Similar to `@Build` methods, method injection is used to resolve method parameters as dependencies:

```
@Override
static MyService overrideMyService(Uri[] urls, Registry registry) {
    // 'urls' is the service configuration
    // use the registry to build MyServiceImpl
    return registry.autobuild(MyServiceImpl#, [urls])
}
```

`@Override` methods can be a little cumbersome, so services may also be override via the `defineServices()` method:

```
static Void defineServices(ServiceDefinitions defs) {
    // define a different MyService instance
    defs.overrideByType(MyService#).withImpl(MyServiceImpl#)
}
```

### Overriding Configuration

Configuration contributions may be overridden by using the `Configuration.overrideXXX()` methods. Assuming we have a configuration of:

```
@Contribute { serviceType=Penguins# }
static Void contributePenguinUrls(Configuration config) {
    config["wikipedia"] = `http://en.wikipedia.org/wiki/Penguin`
}
```

We may override the contribution value with:

```
@Contribute { serviceType=Penguins# }
static Void contributeMoarPenguinUrls(Configuration config) {
    config.overrideValue("wikipedia", `https://www.youtube.com/watch?v=-SVF1i-7l5k`).before("kidZone")
}
```

Or, if we decided we didn't like the wikipedia entry at all, we could remove it.

```
@Contribute { serviceType=Penguins# }
static Void contributeMoarPenguinUrls(Configuration config) {
    config.remove("wikipedia")
}
```

### Overriding Overrides

Services and Service contributions can only be overridden the once, because if two different modules tried to override the same service, which one should win!?

```
class Module1 {
    static Void defineServices(ServiceDefinitions defs) {
        defs.overrideByType(MyService#).withImpl(Override1Impl#)
    }
}

class Module2 {
    static Void defineServices(ServiceDefinitions defs) {
        defs.overrideByType(MyService#).withImpl(Override2Impl#)
    }
}
```

Becasue modules are loaded in any order, either `Module1` or `Module2` could perform the override. Because this behaviour is non-deterministic, it is not allowed.

Instead IoC introduces the concept of an override ID. Whenever an override is performed, you have the option of providing an ID. This ID may be overridden. If the new override provides its own override ID then it, in turn, may also be overriden. And so on.

Rewriting the above example into a legal use case:

```
class Module1 {
    static Void defineServices(ServiceDefinitions defs) {
        defs.overrideByType(MyService#).withImpl(Override1Impl#).withOverrideId("override1")
    }
}

class Module2 {
    static Void defineServices(ServiceDefinitions defs) {
        defs.overrideById("override1").withImpl(Override2Impl#)
    }
}
```

Now it becomes obvious who overrides who! As mentioned, the override chain may be perpetuated:

```
class Module1 {
    static Void defineServices(ServiceDefinitions defs) {
        defs.overrideByType(MyService#).withImpl(Override1Impl#).withOverrideId("override1")
        ...
        defs.overrideById("override1").withImpl(Override2Impl#).withOverrideId("override2")
        defs.overrideById("override2").withImpl(Override3Impl#).withOverrideId("override3")
        defs.overrideById("override3").withImpl(OverrideNImpl#).withOverrideId("overrideN")
        ...
        // this cannot be overridden because it does not provide an override ID
        defs.overrideById("overrideN").withImpl(OverrideZ#)
    }
}
```

The `@Override` facet has an `overrideId` attribute which is the same as above. Overriding Service definitions and `@Override` methods may be freely mixed.

The service `Configuration` class also provides a means to set an override ID. Overriding service contribution overrides work in exactly the same way.

> TIP: It is good practice to provide an override ID so others may override your override.

## Dependency Providers

IoC injects services, but it may also inject other custom classes and objects. By contributing instances of [DependencyProvider](http://repo.status302.com/doc/afIoc/DependencyProvider.html) to a (hidden) `DependencyProviders` service you can inject your own objects:

```
@Contribute { serviceType=DependencyProviders# }
static Void contributeDependencyProviders(Configuration config) {
    config["myProvider"] = MyProvider()
}
```

`DependencyProvider` defines 2 simple methods:

    ** Should return 'true' if the provider can provide.
    Bool canProvide(InjectionCtx injectionCtx)
    
    ** Should return the object to be injected.
    Obj? provide(InjectionCtx injectionCtx)

The [InjectionCtx](http://repo.status302.com/doc/afIoc/InjectionCtx.html) class holds details of the injection currently being performed, e.g. ctor / field / method / it-block injection, field / method details, etc...

Note that `canProvide()` is called for *all* fields of a class, not just those annotated with `@Inject`. The `@Autobuild` facet is an example of this. IoC has an (internal) `AutobuildDependencyProvider` that looks for fields annotated with `@Autobuild`. It then autobuilds the field value as required and returns it for injection.

IoC also provides dependency providers for the following:

### Log Injection

Log instances may be injected as dependencies. The [LogProvider](http://repo.status302.com/doc/afIoc/LogProvider.html) reuses the `@Inject` facet:

```
class Example {
    @Inject private Log log

    ...
}
```

### LocalRef Injection

`LocalRefs`, `LocalLists`, and `LocalMaps` from Alien-Factory's [Concurrent](http://www.fantomfactory.org/pods/afConcurrent) library may be injected as dependencies.

```
const class Example {
    @Inject
    const LocalRef localRef

    @Inject { type=Str[]# }
    const LocalList localList

    @Inject { type=[Str:Slot?]# }
    const LocalMap localMap

    ...
}
```

Using `type` to define the backing List / Map type is optional but recommended. By default the field name is used as the *local* name, this may be overridden by declaring an ID in `@Inject`:

    @Inject { id="localName" }
    const LocalRef localRef

## Service Scope

Services may either be created just the once - [perApplication](http://repo.status302.com/doc/afIoc/ServiceScope#perApplication.html) scope, or created once per thread - [perThread](http://repo.status302.com/doc/afIoc/ServiceScope#perThread.html) scope.

The scope of a service may be explicitly set when you define it - either in the `@Build` / `@Override` facet or in the `defineServices()` method. If not explicitly set then the scope defaults to `perApplication` for const classes and `perThread` for non-const classes.

The article [From One Thread to Another...](http://www.fantomfactory.org/articles/from-one-thread-to-another) states a Fantom fact:

> Only instances of `const` classes can be shared by multiple threads.

As such, only `const` classes may have the `perApplication` scope. The implications of this largely depends on what application you're building.

### Reflux Applications

If building a [Reflux](http://www.fantomfactory.org/pods/afReflux) application then all the processing happens in the UI thread. In effect, you're building a single threaded application. Therefore, for all intents and purposes, `perThread` scope *is* the same as `perApplication` scope. So all your services can non-const and threaded. Happy days!

### Web / REST Applications

Web / REST applications are multi-threaded; each web request is served on a different thread. This gives you a choice when defining a service:

**Per Thread:** A new instance of the service will be created for each thread / web request. [BedSheet's](http://www.fantomfactory.org/pods/afBedSheet) `HttpRequest` and `HttpResponse` are good examples of `perThread` services, with a new instance being created for each request.

In some situations this object creation could be considered wasteful. In other situtations, such as sharing database connections, it is not even viable.

The [ThreadLocalManager](http://repo.status302.com/doc/afIoc/ThreadLocalManager.html) class is responsible for cleaning up threaded resources at the end of a web request / thread processing. You may add your own cleanup handlers to it, but note handlers are only cached for the current thread - meaning the same handler has to be added in each thread.

**Per Application:** Creating `const` services may be off-putting because they're constant, right!? ** *Wrong!* **

Const classes **can** hold *mutable* data and the article [From One Thread to Another...](http://www.fantomfactory.org/articles/from-one-thread-to-another) shows you how.

The smart ones may be thinking that `perApplication` scoped services can only hold other `perApplication` scoped services. Well, they would be wrong also! Using the magic of *Proxies*, `perThread` scoped services may be injected into `perApplication` scoped services. See the *Proxies* section for more info.

## Proxies

IoC has the concept of *Proxies*. A proxy is a thin wrapper class that fronts the real service. Proxies are not created by default but can have real benefits, as outlined below. To front a service with a proxy the service type must be a `mixin` and the service definition should set the appropriate proxy creation strategy - `always`, `never`, `asRequired`.

Ignoring the real implementation, if we had a simple service mixin such as:

```
mixin MyService {
    abstract Void doStuff(Str arg)
}
```

Then conceptually, you can imagine a proxy for `MyService` to look like (*):

```
using afIoc

class MyServiceProxy : MyService {
    @Inject Registry registry

    new make(|This| f) { f(this) }

    override Void doStuff(Str arg) {
        myService := (MyService) registry.serviceById(MyService#.qname)
        myService.doStuff()
    }
}
```

(*) Actual proxy implementations are actually a lot more optimised / complicated but follow a similar pattern.

Proxy classes are dynamically created by IoC at runtime using the [Plastic](http://www.fantomfactory.org/pods/afPlastic) library.

"That's nice." you may be thinking, "But why bother?". Here's why:

### Lazy Loading

As the proxy is injected everywhere that's expecting the real service, then the registry is only asked for the real service when a service method is invoked. That means the real service is only created when a service method is invoked. That means we delay creating the service until the very last minute!

That means real lazy loading!

### Circular Dependencies

Sometimes it can't be helped. Sometimes you have a circular dependency in your services:

    ServiceA -> ServiceB -> ServiceC -> ServiceA

But by giving just one of the services a proxy, the chain is broken!

    ServiceA -> ServiceBProxy

The chain is broken because when IoC creates `ServiceA` it injects a proxy for `ServiceB`. `ServiceB` is only created when a method is called on the proxy. By which time, `ServiceA` has already been created, so IoC happily creates `ServiceC`, injecting in `ServiceA`.

This means circular service dependencies are virtually eliminated!

### Per Thread Injection

As mentioned earlier, proxies allow `perThread` scoped services to be injected into `perApplication` scoped services. Well, to be more precise, the proxy is injected into the `perApplication` scoped services. All calls to the proxy are then routed to the registry which creates on demand, the threaded version of the service.

Note that the `perThread` service mixin has to be `const`, otherwise it can't be injected into the `perApplication` scoped services, which by definition are also `const`.

### Aspects / AOP

[Aspect-oriented programming](http://en.wikipedia.org/wiki/Aspect-oriented_programming) is sometimes a necessary evil, so IoC provides an aspect mechanism.

Method calls to proxied services may be wrapped in your own code, allowing you to:

- perform pre & post method logic
- change the method arguments
- change the return value
- catch and process any thrown Errs
- ignore the method call
- do something else entirely!

See [@Advise](http://repo.status302.com/doc/afIoc/Advise.html) for details.

## Testing IoC Applications

To test an application that uses IoC it is reccommended to use the following approach:

```
using afIoc::Inject
using afIoc::Registry
using afIoc::RegistryBuilder

class TestExample : Test {
    Registry? reg

    @Inject
    MyService? myService

    override Void setup() {
        reg = RegistryBuilder()
                  .addModule(AppModule#)
                  .addModule(TestModule#)
                  .build.startup

        // set MyService and other @Inject'ed fields
        reg.injectIntoFields(this)
    }

    override Void teardown() {
        // use elvis incase 'reg' was never set due to a startup Err
        // we don't want an NullErr in teardown() to mask the real problem
        reg?.shutdown
    }

    Void testStuff() {
        ...
        myService.doStuff()
        ...
    }
}

class TestModule {
    // define any service / test overrides here
}
```

The `setup()` method builds the IoC Registry, passing in the application's `AppModule` and an additional `TestModule`. The `TestModule` is used to define any additional services or mock overrides required for the test.

See how the registry is used to inject dependencies into the test class. These may then be used in the test methods.

Note that you need to add modules from any other IoC library the application / test uses. For instance, if using the [IocEnv library](http://www.fantomfactory.org/pods/afIocEnv) library, it would need to added to the builder:

    override Void setup() {
        reg = RegistryBuilder()
                  .addModule(AppModule#)
                  .addModule(TestModule#)
                  .addModulesFromPod("afIocEnv")
                  .build.startup
        ...
    }

Should you fail to add a required module / library, the test will fail with an `IocErr`:

    TEST FAILED
    afIoc::IocErr: No service matches type XXXX.

Where `XXXX` is a service in the library you forgot to add.

## Debugging

Recursively creating and injecting services into services can become surprisingly complex. So much so, when a error occurs it can be difficult to track down. For this reason IoC wraps all Errs thrown and provides an Operations Stack that gives insight into what IoC was attempting to do (and to what) when the error occured.

For example, if you try to contribute a number instead of a func to `RegistryStartup` you would get the following error:

```
afIoc::IocErr: Contribution 'Int' does not match service configuration value of |->Void|

Ioc Operation Trace:
  [ 1] Locating service by ID 'afIoc::RegistryStartup'
  [ 2] Creating REAL Service 'afIoc::RegistryStartup'
  [ 3] Creating 'afIoc::RegistryStartup' via ctor autobuild
  [ 4] Determining injection parameters for afIoc::RegistryStartupImpl Void make([Str:|->Void|] startups, |This->Void| in)
  [ 5] Looking for dependency of type [Str:|->Void|]
  [ 6] Gathering configuration of type [Str:|->Void|]
  [ 7] Invoking Void contributeRegustryStartup(afIoc::Configuration config) on acme::AppModule...

Stack Trace:
  afIoc::Utils.stackTraceFilter (Utils.fan:53)
  afIoc::RegistryImpl.serviceById (RegistryImpl.fan:218)
  afIoc::RegistryImpl.serviceById (RegistryImpl.fan)
  afIoc::RegistryImpl.startup (RegistryImpl.fan:170)
  afReflux::Reflux$.start (Reflux.fan:52)
  ...
```

If more information if required, you can turn on `afIoc` debug logging on which would output trace level contextual information.

    Registry#.pod.log.level = LogLevel.debug

Be warned though - it outputs a lot!

```
[  1]  --> Locating service by ID 'afReflux::Reflux'
[  2]   --> Creating PROXY for Service 'afReflux::Reflux'
[  3]    --> Creating REAL Service 'afIoc::ServiceProxyBuilder'
[  4]     --> Creating 'afIoc::ServiceProxyBuilder' via ctor autobuild
[  5]      --> Determining injection parameters for afIoc::ServiceProxyBuilderImpl Void make(afIoc::ActorPools actorPools, |This->Void| in)
[  5]        > Parameter 1 = afIoc::ActorPools
[  6]       --> Looking for dependency of type afIoc::ActorPools
[  6]       <-- Looking for dependency of type afIoc::ActorPools [000ms]
[  6]       --> Looking for dependency of type afIoc::ActorPools
[  6]         > Found Service 'afIoc::ActorPools'
[  7]        --> Creating REAL Service 'afIoc::ActorPools'
[  8]         --> Creating 'afIoc::ActorPools' via ctor autobuild
[  9]          --> Determining injection parameters for afIoc::ActorPoolsImpl Void make([Str:concurrent::ActorPool] actorPools)
[  9]            > Parameter 1 = [Str:concurrent::ActorPool]
[ 10]           --> Looking for dependency of type [Str:concurrent::ActorPool]
[ 10]           <-- Looking for dependency of type [Str:concurrent::ActorPool] [000ms]
[ 10]           --> Looking for dependency of type [Str:concurrent::ActorPool]
[ 10]             > Found Configuration '[Str:concurrent::ActorPool]'
[ 11]            --> Gathering configuration of type [Str:concurrent::ActorPool]
[ 12]             --> Determining injection parameters for afIoc::IocModule Void contributeActorPools(afIoc::Configuration config)
[ 12]               > Parameter 1 = afIoc::Configuration
[ 12]               > Parameter provided by user
[ 12]             <-- Determining injection parameters for afIoc::IocModule Void Void contributeActorPools(afIoc::Configuration config) [000ms]
[ 12]             --> Invoking Void contributeActorPools(afIoc::Configuration config) on afIoc::IocModule...
[ 12]             <-- Invoking Void contributeActorPools(afIoc::Configuration config) on afIoc::IocModule... [005ms]
[ 11]              > Added 1 contributions
[ 11]            <-- Gathering configuration of type [Str:concurrent::ActorPool] [005ms]
 ...
 ...
```

