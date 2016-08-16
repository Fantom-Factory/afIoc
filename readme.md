#IoC v3.0.4
---
[![Written in: Fantom](http://img.shields.io/badge/written%20in-Fantom-lightgray.svg)](http://fantom.org/)
[![pod: v3.0.4](http://img.shields.io/badge/pod-v3.0.4-yellow.svg)](http://www.fantomfactory.org/pods/afIoc)
![Licence: MIT](http://img.shields.io/badge/licence-MIT-blue.svg)

## Overview

IoC is a fast, lightweight, and highly customisable Dependency Injection framework that binds your application together.

Like [Guice](http://code.google.com/p/google-guice/)? Know [Spring](http://www.springsource.org/spring-framework)? Use [Autofac](http://autofac.org/)? Then you'll love *IoC*!

- Ctor injection
- Field injection
- Distributed service configuration
- Non-invasive usage
- Lazy services
- Simple API
- **Runs in Javascript!**

See frameworks such as [BedSheet](http://pods.fantomfactory.org/pods/afBedSheet) and [Reflux](http://pods.fantomfactory.org/pods/afReflux) for ready to go IoC containers.

IoC was inspired by the most excellent [Tapestry 5 IoC](http://tapestry.apache.org/ioc.html) for Java.

## Install

Install `IoC` with the Fantom Repository Manager ( [fanr](http://fantom.org/doc/docFanr/Tool.html#install) ):

    C:\> fanr install -r http://pods.fantomfactory.org/fanr/ afIoc

To use in a [Fantom](http://fantom.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afIoc 3.0"]

## Documentation

Full API & fandocs are available on the [Fantom Pod Repository](http://pods.fantomfactory.org/pods/afIoc/).

## Quick Start

This quick start demonstrates:

1. Service definition
2. List configuration
3. Registry building
4. It-block ctor injection
5. Autobuilding

The `Main::main()` method creates a registry instance, obtains instances of the `DinnerMenu` service, which prints contributed instances of the `ChefsSpecials` class.

1. Create a text file called `Example.fan`

        using afIoc
        
        // ---- Services are plain Fantom classes -------------------------------------
        
        const class DinnerMenu {
        
            @Inject
            const ChefsSpecials chefsSpecials
        
            const Str[] dishes
        
            // 4. It-block ctor injection
            new make(Str[] dishes, |This| in) {
                in(this)  // this it-block performs the actual injection
                this.dishes = dishes
            }
        
            Void printMenu() {
                echo("\nDinner Menu:")
                dishes.rw.addAll(chefsSpecials.dishes).each { echo(it) }
            }
        }
        
        const class ChefsSpecials {
            const Str[] dishes := ["Lobster Thermadore"]
        }
        
        
        
        // ---- Every IoC application / library should have an AppModule --------------
        
        ** This is the central place where services are defined and configured
        const class AppModule {
        
            // 1. Service definition
            Void defineServices(RegistryBuilder bob) {
                bob.addService(DinnerMenu#)
                bob.addService(ChefsSpecials#)
            }
        
            // 2. Service configuration
            @Contribute { serviceType=DinnerMenu# }
            Void contributeDinnerMenu(Configuration config) {
                config.add("Fish'n'Chips")
                config.add("Pie'n'Mash")
            }
        }
        
        
        
        // ---- Use Scopes to access the services -------------------------------------
        
        class Main {
            Void main() {
                // 3. Registry building
                // create the registry, passing in our module
                registry := RegistryBuilder().addModule(AppModule#).build()
                scope    := registry.rootScope
        
                // different ways to access services
                menu1 := (DinnerMenu) scope.serviceById("Example_0::DinnerMenu")  // returns a service instance
                menu2 := (DinnerMenu) scope.serviceByType(DinnerMenu#)            // returns the same instance
        
                // 5. Autobuilding
                menu3 := (DinnerMenu) scope.build(DinnerMenu#, [["Beef Stew"]])   // build a new instance
        
                // print menus
                menu1.printMenu()
                menu2.printMenu()
                menu3.printMenu()
        
                // clean up
                registry.shutdown()
            }
        }


2. Run `Example.fan` as a Fantom script from the command line:

        C:\> fan Example.fan
        
        [info] [afIoc] Adding module afIoc::IocModule
        [info] [afIoc] Adding module Example_0::AppModule
        
        2 public services in Example_0:
        
                ChefsSpecials: root
                   DinnerMenu: root
        
        4 public services in afIoc:
        
                  AutoBuilder| builtIn
          DependencyProviders| builtIn
                     Registry| builtIn
                 RegistryMeta| builtIn
        
        66.67% of services were built on startup (4/6)
        
           ___    __                 _____        _
          / _ |  / /_____  _____    / ___/__  ___/ /_________  __ __
         / _  | / // / -_|/ _  /===/ __// _ \/ _/ __/ _  / __|/ // /
        /_/ |_|/_//_/\__|/_//_/   /_/   \_,_/__/\__/____/_/   \_, /
                                    Alien-Factory IoC v3.0.4 /___/
        
        IoC Registry built in 75ms and started up in 20ms
        
        [warn] Building Example_0::DinnerMenu which is *also* defined as service 'Example_0::DinnerMenu - unusual!
        
        Dinner Menu:
        Fish'n'Chips
        Pie'n'Mash
        Lobster Thermadore
        
        Dinner Menu:
        Fish'n'Chips
        Pie'n'Mash
        Lobster Thermadore
        
        Dinner Menu:
        Beef Stew
        Lobster Thermadore
        
        [info] [afIoc] IoC shutdown in 2ms
        [info] [afIoc] IoC says, "Goodbye!"



## Terminology

The **registry** is the top level object in an IoC application. It holds service definitions and the root scope.

**Scopes** are responsible for creating and managing service instances. They build class instances and perform dependency injection. Scopes may also create child scopes.

A **service** is a Fantom class whose instances are created and managed by IoC Scopes. Services are identified by a unique ID, typically the qualified class name. A service may also be referenced by its Type. Multiple services may share the same Type as long as their IDs are different. Services may solicit, and be instantiated with, a configuration map or or map.

A **dependency** is any object a service depends on. A dependency may or may not be a service. Dependencies are provided by [dependency providers](http://pods.fantomfactory.org/pods/afIoc/api/DependencyProvider).

A **module** is a class whose methods define and configure services.

## The IoC Registry

Frameworks such as [BedSheet](http://pods.fantomfactory.org/pods/afBedSheet) and [Reflux](http://pods.fantomfactory.org/pods/afReflux) are IoC containers. That is, they create and look after a `Registry` instance, using it to create classes and provide access to services.

Sometimes you don't have access to an IoC container and have to create the `Registry` instance yourself. (Running unit tests is a good example.) In these cases you will need to use the [RegistryBuilder](http://pods.fantomfactory.org/pods/afIoc/api/RegistryBuilder), passing in the module(s) that define your services:

    registry := RegistryBuilder().addModule(AppModule()).build()
    scope    := registry.rootScope
    ...
    service  := scope.serviceById("serviceId")
    ...
    registry.shutdown

If your code uses other IoC libraries, make sure modules from these pods are added too. Example, if using the [IocEnv library](http://pods.fantomfactory.org/pods/afIocEnv) then add a dependency on the `afIocEnv` pod:

    registry := RegistryBuilder()
        .addModule(MyModule())
        .addModulesFromPod("afIocEnv")
        .build()

## Modules

Most IoC applications / libraries will have a module class. Module classes are where services are defined and configured. Module classes declare methods with special facets that tell IoC what they do.

By convention an application will call its module `AppModule` and libraries will name modules after themselves, but with a `Module` suffix. Example, BedSheet has a module named `BedSheetModule`.

### Pod Meta-data

It is good practice, when writing an IoC application or library, to always include the following meta in the `build.fan`

    meta = [ "afIoc.module" : "<module-qname>" ]

Where `<module-qname>` is the qualified type name of the pod's main module class.

This is how IoC knows what modules are in each pod. It is how the `addModulesFromPod("afIocEnv")` method works; IoC inspects the meta-data in the `afIocEnv` pod and looks up the `afIoc.module` key. It then loads the modules listed.

The `afIoc.module` meta may be a Comma Separated List (CSV) of module names; handy if the pod has many modules. Though it is generally better (more explicit / less prone to error) to use the [@SubModule](http://pods.fantomfactory.org/pods/afIoc/api/SubModule) facet on a single module class.

## Services

A service can be any old Fantom class. What differentiates a *service* from any other class is that you typically want to reuse a service in multiple places. An IoC Service is a class that is created and held by an IoC scope. IoC may then inject that service into other classes; which may themselves be services.

For IoC to instantiate and manage a service it needs to know:

- How to build the service
- What unique ID to store it under
- What Fantom `Type` the service is
- Which scopes it may be created by

All these details are defined in the application's module.

Note that IoC does not want an instance of your service. Instead it wants to know how to make it. That is because IoC will defer creating your service for as long as possible (lazy instantiation).

If nobody ever asks for your service, it is never created. When the service is explicitly asked for, either by you or by anther service, only then is it created.

### Build Your Own

If we we wish to use `MyService` as an IoC service, then we need to tell IoC how to build it. The simplest way is to declare a *build* method in `AppModule` that creates the instance for us:

```
using afIoc

// Example 1
const class AppModule {

    @Build
    MyService buildMyService() {
        return MyService()
    }
}
```

The method may be called anything you like and be of any scope (internal or even private), but it needs the `@Build` facet.

Because of the `@Build` facet, IoC inspects the method and infers the following:

- Calling the method creates a service instance - *inferred from `@Build`*
- The service is of type `MyService` - *inferred from the return type*
- The unique ID is `myPod::MyService` - *inferred from the return type's qualified name*

We can now retrieve an instance of `MyService` with the following:

```
myService := (MyService) scope.serviceById(MyService#.qname)
```

or

```
myService := (MyService) scope.serviceByType(MyService#)
```

The facet attribute `serviceId` allows you to define a service with a different ID.

```
@Build { serviceId="wotever" }
MyService buildMyService() {
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
    Penguins buildPenguins() {
       return Penguins()
    }

    @Build
    MyService buildMyService(Penguins penguins) {
        return MyService(3, penguins)
    }
}
```

Before IoC calls `buildMyService()` it looks at the method signature and assumes any parameters are dependencies that need to be passed in. In this case, it is the service `Penguins`. So it looks up, and creates if it doesn't already exist, the `Penguins` service and passes it to `buildMyService()`. This is an example of *method injection*. All this is automatic, and all builder methods may declare any number of services and dependencies as a method parameters.

Note that the `@Build` facet has other attributes that give you control over the service's unique ID and scopes.

Service builder methods are a very powerful pattern as they give you complete control over how the service is created. But they are also very verbose and require a lot of code. So lets look at an easier way; the `defineXXXX()` method...

### Defining Services

Modules may declare a `defineXXXX()` method. It may be of any visibility but must have the prefix `define` and it must define a single parameter of `RegitryBuilder`. The method lets you create and add service definitions in place of writing builder methods.

We could replace the previous `Example 1` with the following:

```
using afIoc

class AppModule {
    Void defineServices(RegistryBuilder bob) {
        bob.addService(MyService#)
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
    Void defineServices(RegistryBuilder bob) {
        bob.add(MyService#).withCtorArgs([ 3 ])
        bob.add(Penguins#)
    }
}
```

That's a lot more succinct! But wait! The `MyService` definition just declares a ctor arg of `3`, but what about the `Penguins` service? Just like method injection, IoC will assume all unknown parameters are dependencies and will attempt to resolve them as such. This is an example of *ctor injection* and more is said in the relevant section.

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

When you request `MyService` from a scope:

    myService := (MyService) scope.serviceByType(MyService#)

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



Ctor's can be of any scope you like: public, protected, internal or private. In the following examples, the ctors are public purely for brevity.

Note that nullable ctor parameters are deemed *optional* and don't throw an Err if a dependency cannot found.

#### Which ctor?

Sometimes your service may have multiple ctors. Perhaps one for building and another for testing. When this happens, which one should IoC use to create the service?

By default, IoC will choose the best fitting ctor with the most parameters. But this behaviour can be overridden by annotating a chosen ctor with `@Inject`.

```
using afIoc

const class MyService {

    ** By default, IoC would choose this ctor because it has the most parameters
    new make1(Penguins penguins, OtherService otherService) {
        ....
    }

    ** But we can force IoC to use this ctor by annotating it with @Inject
    @Inject
    new make2(|This| in) {
        ....
    }
}
```

Note that IoC is clever enough to find the *best fitting* ctor. That is, it looks for a ctor that has the most injectable parameters. So given we have a *Penguins* service, when we try to build this class:

```
using afIoc

const class CtorTest {

    new make1(Int not_a_service, Penguins penguins) { .... }

    new make2(Penguins penguins) { .... }
}
```

Then IoC would choose `make2()` because it doesn't know how to inject `Int not_a_service`. But if we define `CtorTest` with:

```
Void defineServices(RegistyBuilder bob) {
    bob.add(CtorTest#).withCtorArgs([69])
}
```

Then IoC would then choose `make1()`.

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

## AutoBuilding

It is common to *autobuild* class instances. So much so, there is a `build()` method on `Scope`, a `build()` method on service `Configuration` objects, and there's even an `@Autobuild` facet. But what is *auto-building*?

Autobuilding is the act of creating an instance of a class with IoC. That is, IoC will new up the instance and perform any necessary injection as previously outlined.

Let's look at this code:

```
Void main() {
    registry := RegistryBuilder().build()
    scope    := registry.rootScope

    myClass := (MyClass) scope.build(MyClass#)

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

## Lazy Functions

To defer building services until they are used, you can inject *Lazy Functions*. These are funcs that return a service:

```
@Inject
|->MyService| myServiceFunc
```

Lazy funcs always query the current *active* scope to find the service instance. The active scope may be different to the scope that the containing class was created in. This important distinction allows threaded services to be injected into non-threaded services.

(Note that Lazy Funcs are immutable.)

So instead of writing this:

```
using afIoc

const class ConstService {

    @Inject const Registry registry

    new make(|This| in) { in(this) }

    Void doStuff() {
        oldSkoolLazyFunc().doStuff()
    }

    NonConstService oldSkoolLazyFunc() {
        // returns a non-const service from the active scope
        registry.activeScope.serviceById(NonConstService#.qname)
    }
}
```

You can just write this:

```
using afIoc

const class ConstService {

    @Inject const |->NonConstService| lazyFunc

    new make(|This| in) { in(this) }

    Void doStuff() {
        lazyFunc().doStuff()
    }
}
```

### Circular Dependencies

Sometimes it can't be helped. Sometimes you have a circular dependency in your services:

    ServiceA -> ServiceB -> ServiceC -> ServiceA

This makes creating an instance of `ServiceA` impossible, because to create `ServiceA` you first create `ServiceA` to inject into `ServiceC`!

But by turning just one of the service injections into a Lazy Func, the chain is broken!

    ServiceA -> ServiceBLazyFunc ...... ServiceB -> ServiceC -> ServiceA

The chain is broken because when IoC creates `ServiceA` it injects a func for `ServiceB`. `ServiceB` is only created when that func is called. By which time, `ServiceA` has already been created! So when the Lazy Func is called, IoC happily creates `ServiceC`, injecting in `ServiceA`.

This means circular service dependencies are virtually eliminated!

## Factory Functions

To perform an autobuild you need a `Scope` instance. As it is not always convenient to inject / pass around the Scope you may also autobuild using *Factory Functions*.

Factory functions are similar to Lazy Functions, except they return non-service types. Factory funcs may also define parameters, the values of which get passed to the autobuild ctor:

```
using afIoc

class Builder {
    @Inject |Str->BuildMe| factoryFunc

    Void stuff() {
        bob1 := factoryFunc("Judge")  // "Judge" gets passed to the BuildMe ctor
        bob2 := factoryFunc("Dredd")  // "Dredd" gets passed to the BuildMe ctor
    }
}

class BuildMe {
    // name is passed in from the factory func, someService is injected
    new make(Str name, SomeService someService) { ... }
}
```

Any non-declared arguments in the autobuild ctor are resolved as dependencies as usual.

So, as seen in the example above, the strings `Judge` and `Dredd` get passed to the `BuildMe` ctor and IoC resolves the `SomeService` class.

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

const class AppModule {
    Void defineServices(ServiceDefinitions defs) {
        defs.add(Penguins#)
    }

    @Contribute { serviceType=Penguins# }
    Void contributePenguinUrls(Configuration config) {
        config.add(`http://ypte.org.uk/factsheets/penguins/`)
        config.add(`http://www.kidzone.ws/animals/penguins/`)
    }
}
```

Contribution methods are module methods annotated with `@Contribute`. They may be of any scope and be called anything; although by convention they;re named `contributeXXX()`. The `serviceType` facet parameter tells IoC which service the method contributes to. Each contribution method may add as many items to the list as it likes.

Note that *any* module may define contribution methods for *any* service. Because the modules may be spread out in multiple pods, this is known as *distributed configuration*.

The `Configuration` object is write only. Only when all the contribution methods have been called, is the full list of configuration data known. Because contribution methods may be called in any order, being able to *read* contributions would only give partial data. Becasuse partial data can be misleading it is deemed better not to give any at all.

If the `Penguins` service were to built via a builder method then the method's first parameter (if it is a List or a Map) is taken to be service configuration and injected appropriately:

```
using afIoc

const class AppModule {
    @Build
    Penguins buildPenguins(Uri[] penguinUrls) {
       ...
    }

    @Contribute { serviceType=Penguins# }
    Void contributePenguinUrls(Configuration config) {
        config.add(`http://ypte.org.uk/factsheets/penguins/`)
        config.add(`http://www.kidzone.ws/animals/penguins/`)
    }
}
```

Because the service configuration is a list of Uris, the contribution methods must contribute Uri objects. It is an error to add anything else. Example, if we try to add the number 19 we would get the Err message:

```
afIoc::IocErr: Contribution 'Int' does not match service configuration value of Uri
```

That said, all contribution values are `coerced` via [afBeanUtils::TypeCoercer](http://pods.fantomfactory.org/pods/afBeanUtils/api/TypeCoercer) which gives a little leeway. `TypeCoercer` looks for `toXXX()` and `fromXXX()` methods to *coerce* values from one type to another. This is useful when contributing the likes of `Regex` which has a `fromStr()` method, or `File` which has a Uri ctor:

```
using afIoc

const class AppModule {
    @Build
    MyService buildMyService(File[] file) {
       ...
    }

    @Contribute { serviceType=MyService# }
    Void contributeFiles(Configuration config) {
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

const class AppModule {
    @Contribute { serviceType=Penguins# }
    Void contributePenguinUrls(Configuration config) {
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

const class MyModule {
    @Contribute { serviceType=Penguins# }
    Void contributePenguinUrls(Configuration config) {
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

Some aspects of Service **can not** be changed, these are:

- The unique ID
- The Fantom Type

All other aspects may be. Substituting service implementations can be useful for testing where real services may be switched with mocked versions.

Given that `MyService` has already been defined in a module, we can substitute it for our own instance by writing an `@Override` method.

`@Override` methods are similar to builder methods in that they may be of any scope, and be named what you like, but they must annotated with the `@Override` facet.

```
@Override
MyService overrideMyService() {
    // build a different instance
    return MyServiceImpl(...)
}
```

The return type, `MyService` in the above example, is used to find the service to override. The return type **must** match the original service type. If more control is required over which service to override, you can use the `serviceId` or `serviceType` facet attributes:

```
@Override { serviceId="acme::MyService" }
MyService overrideMyService() {
    // build a different instance
    return MyServiceImpl(...)
}
```

Service scope and proxy strategies may also be overriden via facet attributes. The override may also be marked as `optional` if there is a chance the original service may not be defined; for example if it is defined by an optional 3rd party library.

Similar to `@Build` methods, method injection is used to resolve method parameters as dependencies:

```
@Override
MyService overrideMyService(Uri[] urls, Scope scope) {
    // 'urls' is the service configuration
    // use the scope to build MyServiceImpl
    return scope.build(MyServiceImpl#, [urls])
}
```

`@Override` methods can be a little cumbersome, so services may also be override via the `defineServices()` method:

```
Void defineServices(ServiceDefinitions defs) {
    // define a different MyService instance
    defs.overrideServiceByType(MyService#).withImpl(MyServiceImpl#)
}
```

### Overriding Configuration

Configuration contributions may be overridden by using the `Configuration.overrideXXX()` methods. Assuming we have a configuration of:

```
@Contribute { serviceType=Penguins# }
Void contributePenguinUrls(Configuration config) {
    config["wikipedia"] = `http://en.wikipedia.org/wiki/Penguin`
}
```

We may override the contribution value with:

```
@Contribute { serviceType=Penguins# }
Void contributeMoarPenguinUrls(Configuration config) {
    config.overrideValue("wikipedia", `https://www.youtube.com/watch?v=-SVF1i-7l5k`).before("kidZone")
}
```

Note that when we override a contribution we are able to re-define the ordering constraints.

Or, if we decided we didn't like the wikipedia entry at all, we could remove it.

```
@Contribute { serviceType=Penguins# }
Void contributeMoarPenguinUrls(Configuration config) {
    config.remove("wikipedia")
}
```

### Overriding Overrides

Services and Service contributions can only be overridden the once, because if two different modules tried to override the same service, which one should win!?

```
const class Module1 {
    Void defineServices(RegistryBuilder bob) {
        bob.overrideServiceByType(MyService#).withImpl(Override1Impl#)
    }
}

const class Module2 {
    static Void defineServices(RegistryBuilder bob) {
        bob.overrideServiceByType(MyService#).withImpl(Override2Impl#)
    }
}
```

Because modules are loaded in any order, either `Module1` or `Module2` could perform the override. Because this behaviour is non-deterministic, it is not allowed.

Instead IoC introduces the concept of an override ID. Whenever an override is performed, you have the option of providing an ID. This ID may be overridden. If an override provides its own override ID then it, in turn, may also be overriden. And so on.

Rewriting the above example into a legal use case:

```
const class Module1 {
    Void defineServices(RegistryBuilder bob) {
        bob.overrideServiceByType(MyService#).withImpl(Override1Impl#).withOverrideId("override1")
    }
}

const class Module2 {
    Void defineServices(RegistryBuilder bob) {
        bob.overrideServiceById("override1").withImpl(Override2Impl#)
    }
}
```

Now it becomes obvious who overrides who! As mentioned, the override chain may be perpetuated:

```
const class Module1 {
    Void defineServices(RegistryBuilder bob) {
        bob.overrideServiceByType(MyService#).withImpl(Override1Impl#).withOverrideId("override1")
        ...
        bob.overrideServiceById("override1").withImpl(Override2Impl#).withOverrideId("override2")
        bob.overrideServiceById("override2").withImpl(Override3Impl#).withOverrideId("override3")
        bob.overrideServiceById("override3").withImpl(OverrideNImpl#).withOverrideId("overrideN")
        ...
        // this cannot be overridden because it does not provide an override ID
        bob.overrideServiceById("overrideN").withImpl(OverrideZ#)
    }
}
```

The `@Override` facet has an `overrideId` attribute which is the same as above. Overriding Service definitions and `@Override` methods may be freely mixed.

The service `Configuration` class also provides a means to set an override ID. Overriding service contribution overrides work in exactly the same way.

> TIP: It is good practice to provide an override ID so others may override your override.

### Decorating Services

Services may be decorated. That is, they may be replaced with another instance that *wraps* the original instance. You may do this to log method calls. For example, a `MrMen` service and a wrapper:

```
const mixin MrMen {
    virtual Str mrHappy() { "Mr Happy" }
}

const class MeMenWrapper : MrMen {
    const MrMen orig

    new make(MrMen orig) {
        this.orig = orig
    }

    override Str mrHappy() {
        echo("Calling Mr Happy...")
        return orig.mrHappy
    }
}
```

Decorate the original `MrMen` service using the `RegistryBuilder`:

```
regBuilder.decorateService("acme::MrMen") |Configuration config| {
    config["mrMen.wrapper"] = |Obj? serviceInstance, Scope scope, ServiceDef serviceDef->Obj?| {
        return MrMenWrapper(serviceInstance)
    }
}
```

Note the id `mrMen.wrapper` isn't required, but may be useful for ordering if someone wishes to wrap your wrapper!

Note that wrapping / decorating services isn't possible with normal overrides because overrides don't have a handle on the original service.

## Dependency Providers

IoC injects services, but it can also inject other custom classes and objects. By contributing instances of [DependencyProvider](http://pods.fantomfactory.org/pods/afIoc/api/DependencyProvider) to the `DependencyProviders` service you can inject your own objects:

```
@Contribute { serviceType=DependencyProviders# }
Void contributeDependencyProviders(Configuration config) {
    config["myProvider"] = MyProvider()
}
```

Note that the `DependencyProviders` service is currently annotated with `@NoDoc` as, other than being a reciever for contributions, it has no other public use.

`DependencyProvider` defines 2 simple methods:

    ** Should return 'true' if the provider can provide.
    Bool canProvide(Scope scope, InjectionCtx injectionCtx)
    
    ** Should return the object to be injected.
    Obj? provide(Scope scope, InjectionCtx injectionCtx)

The [InjectionCtx](http://pods.fantomfactory.org/pods/afIoc/api/InjectionCtx) class holds details of the injection currently being performed, e.g. ctor / field / method / it-block injection, field / method details, etc...

Note that `canProvide()` is called for *all* fields of a class, not just those annotated with `@Inject`. The `@Autobuild` facet is an example of this. IoC has an (internal) `AutobuildDependencyProvider` that looks for fields annotated with `@Autobuild`. It then autobuilds the field value as required and returns it for injection.

IoC also provides dependency providers for `Log` objects:

```
class Example {
    @Inject private Log log

    ...
}
```

## Service Scopes

Scopes are where services definitions and service instances are held. They form a tree like, hierarchical structure. When looking for a service in a scope, if it is not found then the search is delegated to the parent.

    builtin
     |
     +-root
        |
        +-myScope1
        |
        +-myScope2

IoC defines two scopes - the **builtin scope** which is used for system services defined by afIoc itself, and the **root scope** which. Any other scope is defined by the application and must be derived from the root scope.

Services are created just once per Scope, but may be created in multiple scopes.

The scope of a service may be explicitly set when you define the service - either in the `@Build` / `@Override` facet or in the `RegistryBuilder.addService()` method.

### Const vs Non-Const

The root scope is a non-threaded scope, meaning it can only hold instances of const classes and services. Threaded scopes are created and destroyed in the same thread, hence they may contain non-const classes and services.

Non-threaded scopes (like the root scope) may create and contain any type of scope, but threaded scopes may only contain other threaded scopes.

If a service does not explicitly define a scope, then by default const classes are matched to all non-threaded scopes. And non-const classes are matched to all threaded scopes.

Note that the root scope is a non-threaded scope, meaning it can only hold instances of const classes and services.

### Reflux Applications

In a [Reflux](http://pods.fantomfactory.org/pods/afReflux) application all processing happens in the UI thread. As such, Reflux defines a single threaded scope called `uiThread` and all services are created from this. This means all your services can be non-const, and you don't have to even think about scopes.

*Happy days!*

### BedSheet Applications

[BedSheet](http://pods.fantomfactory.org/pods/afBedSheet) Web applications are multi-threaded; each web request is served on a different thread. For that reason BedSheet defines a threaded scope called `request`.

**Request Scope:** Here a new instance of request services will be created for each thread / web request. BedSheet's `WebReq` and `WebRes` are good examples of `request` services. Note in some situations this *per thread* object creation could be considered wasteful. In other situations, such as sharing database connections, it is not even viable.

**Root Scope:** In IoC's default scope, only one instance of the service is created for the entire application. *Root scoped* services need to be `const` classes.

Writing `const` services may be off-putting to some - because they're constant and can't hold mutable data, right!? ** *Wrong!* ** Const classes *can* hold *mutable* data. The article [From One Thread to Another...](http://www.fantomfactory.org/articles/from-one-thread-to-another) shows you how.

The smart ones may be thinking that `root` scoped services can only hold other `root` scoped services. Well, they would be wrong too! Using the magic of *Lazy Funcs*, `request` scoped services may be injected into `root` scoped services. See [Lazy Functions](#lazyFunctions) for more info.

### Custom Scopes

In any thread, there can be only one active scope. By default this is the **root** scope. To create new scope (as the child of another) and make it active, use `Scope.createChild()`.

`createChild()` takes a function that is executed straight away. The new scope also becomes the default active scope for the duration of the function.

```
registry := RegistryBuilder() {
    addScope("myScope")
}.build

rootScope := registry.rootScope

rootScope.createChild("myScope") |myScope| {
	echo(myScope)               // --> Scope: myScope
	echo(registry.activeScope)  // --> Scope: myScope

    ...
}

registry.shutdown
```

### Jail Breaking

As you can see above, the `myScope` scope is constrained to the closure passed into `Scope.createChild()`. Sometimes this is not desirable and you want to set a default scope for the thread. If so, it is possible to **jail break** the child scope from the closure.

If you jail break a scope then remember, it is your responsibility to `destroy()` it! Calling destroy ensures all thread state related to the scope, including service instances, are correctly disposed of. It also ensures all registered destroy hooks are called.

The next example uses the [afConcurrent](http://pods.fantomfactory.org/pods/afConcurrent) library to run code in a separate thread. It calls into the other thread 3 times:

1. To create and jailbreak an instance of `myScope`
2. To prove that indeed `myScope` is the default scope for the thread
3. To destroy the `myScope` instance

```
run := afConcurrent::Synchronized(concurrent::ActorPool())
registry := RegistryBuilder() {
    addScope("myScope")
}.build

rootScope   := registry.rootScope

run.synchronized |->| {
	// create and jailbreak myScope
	rootScope.createChild("myScope") |myScope| {
		myScope.jailBreak
	}
}

// prove that root scope is active by default
echo(registry.activeScope)  // --> Scope: root

run.synchronized |->| {
	// prove that this thread has myScope active by default!
	echo(registry.activeScope)  // --> Scope: myScope
}

// all jailbroken scopes must be manually destroyed
run.synchronized |->| {
	registry.activeScope.destroy
}

registry.shutdown
```

Also note that once jail broken, the scopes is no longer returned as the registry's active scope.

To create a new scope, and not have it become the default active scope for the thread, then just call `Scope.createChild()` but don't pass in a function. Note you still have to destroy the scope.

```
registry := RegistryBuilder() {
    addScope("myScope")
}.build

rootScope := registry.rootScope

myScope := rootScope.createChild("myScope")

echo(registry.activeScope)  // --> Scope: root

myScope.destroy
registry.shutdown
```

Note, to set a new scope that becomes the global default in any new thread (instead of `root` scope), use `Registry.defaultScope`.

## Testing IoC Applications

To test an application that uses IoC it is reccommended you use the following approach:

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
                  .build

        // set MyService and other @Inject'ed fields
        reg.rootScope.inject(this)
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

const class TestModule {
    // define any service / test overrides here
}
```

The `setup()` method builds the IoC Registry, passing in the application's `AppModule` and an additional `TestModule`. The `TestModule` is used to define any additional services or mock overrides required for the test.

See how the registry is used to inject dependencies into the test class. These may then be used in the test methods.

Note that you need to add modules from other IoC libraries the application / test uses. For instance, if using the [IocEnv library](http://pods.fantomfactory.org/pods/afIocEnv) library, it would need to added to the builder:

    override Void setup() {
        reg = RegistryBuilder()
                  .addModule(AppModule#)
                  .addModule(TestModule#)
                  .addModulesFromPod("afIocEnv")
                  .build
        ...
    }

Should you fail to add a required module / library, the test will fail when IoC attempts to inject a service that hasn't been defined:

    TEST FAILED
    afIoc::ServiceNotFoundErr: Could not find service of Type XXXX.

Where `XXXX` is a service in the library you forgot to add.

Note that the `setup()` and `teardown()` could be moved into a common base class.

### Threaded Services

If your application contains threaded services, then to inject them, you need to create an instance of a threaded scope:

```
using afIoc::Inject
using afIoc::Registry
using afIoc::RegistryBuilder

class TestExample : Test {
    Registry? reg

    // the threaded scope instance
    Scope?    scope

    @Inject
    MyService? myService

    override Void setup() {
        reg = RegistryBuilder()

        // define a threaded scope
        reg.addScope("thread", true)

        reg.addModule(AppModule#)
           .addModule(TestModule#)
           .build

        // create an instance of the threaded scope
        reg.rootScope.createChild("thread") { this.scope = it.jailBreak }

        // use the threaded scope to set MyService and other @Inject'ed fields
        scope.inject(this)
    }

    override Void teardown() {
        // ensure any scopes we broke out of jail are destroyed
        scope?.destroy
        reg?.shutdown
    }

    Void testStuff() {
        ...
        myService.doStuff()
        ...
    }
}

const class TestModule {
    // define any service / test overrides here
}
```

Note the scope may be called what you like, but `thread` shows intent here.

## Debugging

Recursively creating and injecting services into services can become surprisingly complex. So much so, when a error occurs it can be difficult to track down. For this reason IoC wraps Errs thrown and provides an Operations Stack that gives insight into what IoC was attempting to do (and to what) when the error occured.

For example, if you tried to build an instance of `MyClass`, which depended on the `Penguins` service, which referenced `MyService02` - but `MyService02` had not been defined as a service; you would see:

```
afIoc::ServiceNotFoundErr: Could not find service of Type acme::MyService02 in scopes: root, builtIn
IoC Operation Trace:
  [ 3] Resolving Type: acme::MyService02
  [ 2] Resolving Type: acme::Penguins
  [ 1] Building:       acme::MyClass

Available Service IDs:
  builtIn - afIoc::AutoBuilder
  builtIn - afIoc::DependencyProviders
  builtIn - afIoc::Registry
  builtIn - afIoc::RegistryMeta
  root - acme::Penguins

Stack Trace:
  afIoc::ScopeImpl.serviceByType_ (Scope.fan:152)
  afIoc::ScopeImpl.serviceByType_ (Scope.fan:151)
  afIoc::ScopeImpl.serviceByType (Scope.fan:142)
  ...
```

### Disable Startup Messages

To disable IoC's startup and shutdown messages, add the following to your `AppModule`:

```
Void onRegistryStartup(Configuration config) {
    config.remove("afIoc.logServices")
    config.remove("afIoc.logBanner")
    config.remove("afIoc.logStartupTimes")
}

Void onRegistryShutdown(Configuration config) {
    config.remove("afIoc.sayGoodbye")
}
```

